# Chat send performance

## Send contract and critical path

`POST /api/v1/chat/messages` remains authoritative. The client supplies one
UUID `clientMessageId` per logical message and reuses it for retries. The
database uniqueness constraint on `(sender_id, client_message_id)` and the
service conflict check prevent duplicate persistence while rejecting reuse for
different content or recipients.

The Flutter client now renders a local `Sending` message before awaiting the
POST. A successful response, a REST history refresh, or a WebSocket-triggered
history refresh reconciles that local row by `clientMessageId`. Only an
authoritative server message is shown as `Sent`. A failed or ambiguous request
stays visible as `Failed`; Retry reuses the same UUID.

The WebSocket remains a content-free invalidation channel. It is opened once
per chat page, authenticated once, and reused. REST remains the source of truth.

## Source-confirmed bottlenecks

Before this change, the sender saw no message until the POST completed. After
success, the UI also awaited a complete paginated inbox reload before finishing
the send operation. On the backend, `ChatRepository.insert` called `flush()`
for every conversation, participant, message, and participant-state row. A
first message therefore forced six persistence-context flushes, in addition to
authorization, notification, and response queries. Remote-database round-trip
latency magnifies that sequence.

The optimized path immediately renders locally, updates the inbox from the POST
response, and leaves subsequent WebSocket invalidations in the background.
Backend participant and message-state rows are each inserted with one set-based
statement. Conversation and message inserts still flush because their generated
IDs are required for dependent rows. Notification creation remains synchronous
and transactional: a notification failure still rolls back the message.

Existing chat indexes already cover pair uniqueness, sender/client UUID
idempotency, conversation history, participant state, unread counts, and
conversation activity. No migration was added without an observed query-plan
need.

## Opt-in diagnostics

Diagnostics are disabled by default and never include message content, names,
tokens, or credentials.

Backend:

```bash
export CHAT_PERFORMANCE_LOGGING=true
```

The backend emits one `chat_send` line after transaction commit with a client
UUID correlation value, total duration, and authorization, conversation,
message-persistence, and notification phase durations. Disable it by unsetting
the variable or setting it to `false`.

Flutter:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=CHAT_PERFORMANCE_LOGGING=true
```

Flutter emits `local-ui`, `server-ack`, and `failed` milestones keyed by the
same client UUID. Omit the define to disable it.

## Reproducible measurement procedure

1. Use the same two presentation accounts, backend process, database endpoint,
   browser build mode, and network conditions for before and after runs.
2. Open browser developer tools, preserve the Network log, and filter for
   `chat`. Clear the log before each sample.
3. Send five warm-up messages, then record at least 20 sequential messages.
   Do not load test or send concurrent automated traffic.
4. For each message, record Flutter `local-ui` and `server-ack`, the matching
   backend `chat_send`, recipient arrival time, and HTTP requests caused by the
   action.
5. Calculate median and p95 send-to-acknowledgement. Report cold first-send
   separately from warm sends. Do not mix debug and release-build samples.
6. Repeat with browser network throttling, then disconnect after tapping Send.
   Confirm `Failed` remains visible and Retry uses the same correlation UUID.
7. Keep both users open. Verify recipient delivery, rapid consecutive sends,
   ordering, read/delivery state, and that repeated `CHAT_CHANGED` events or a
   reconnect never duplicate a message.
8. Load older history before sending, then confirm the paging cursor and older
   messages remain intact.

Expected request shape for a normal sender action is one POST on the critical
path. WebSocket invalidations may cause background inbox/history GETs; record
them separately. The recipient normally performs inbox/history reads and any
delivery acknowledgement required by its current view.

## Remaining boundaries

The POST still performs database-backed session validation, participant locks,
accepted-connection authorization, notification persistence, and transaction
commit before acknowledging success. These operations are intentional security
and reliability boundaries. Remote Neon connection acquisition and network
latency must be measured in the running environment; this source review does
not establish their magnitude.
