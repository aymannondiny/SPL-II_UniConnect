# One-to-one chat

Backend scope: FR_51–FR_55 and FR_79–FR_80 from the approved requirements baseline and the corrected chat class diagram. Flutter chat screens and content reporting are separate work.

## Rules

Both accounts must be ACTIVE and their connection ACCEPTED to send. Privacy settings do not grant chat access. The first ordinary message creates one conversation for the unordered user pair, exactly two participants, and two participant-state records per message in one transaction. Connection introductions are not chat messages; accepting a connection does not create a conversation.

Removing a connection blocks further messages but preserves history, receipts, and deletion actions. Reconnecting reuses the same conversation. Participants may view their history when the other account is suspended or anonymized; the requesting account must still be ACTIVE with a valid session. An anonymized participant is labelled `Former User`.

Text must be nonblank and at most 5,000 Java characters (UTF-16 code units). Whitespace inside valid text is preserved. No attachments, typing indicators, or online-presence tracking are included. Render message content as plain text, never as HTML.

All REST endpoints use the existing `Authorization: Bearer <accessToken>` session and return `Cache-Control: no-store`. Timestamps are UTC without a suffix, matching existing backend records.

## API

Base: `/api/v1/chat`.

| Method | Path | Result |
| --- | --- | --- |
| POST | `/messages` | 200 persisted message, including retry |
| GET | `/conversations?page=0&size=20` | 200 inbox with other participant, latest visible message, unread count, and canSend |
| GET | `/conversations/{id}/messages?size=20` | 200 latest history page; marks returned incoming messages read |
| GET | `/conversations/{id}/messages?beforeMessageId=123&size=20` | 200 older history page |
| PATCH | `/messages/{id}/delivered` | 200 recipient delivery acknowledgement |
| PATCH | `/messages/{id}/read` | 200 recipient read acknowledgement, also establishes delivery |
| DELETE | `/messages/{id}/self` | 204 hide for the caller |
| DELETE | `/messages/{id}/everyone` | 204 sender-only content removal for both |

Send body:

```json
{
  "receiverId": 3,
  "clientMessageId": "df08ef56-dad2-44f5-bf7d-8974c23545b1",
  "content": "Hello! This is our first chat message."
}
```

Generate a fresh UUID per logical message, e.g. browser `crypto.randomUUID()`. Retry a failed/uncertain send with the same UUID, receiver, and content. The UUID is unique per sender; changing the payload with an existing UUID gives 409 `MESSAGE_RETRY_CONFLICT`. A retry still requires a current accepted connection and a message not deleted for self. It never restores deleted content.

Conversation pages are ordered by latest send time descending, then conversation ID descending. Page starts at 0 (maximum 100000), size is 1–50. Deleting or reading a message does not bump conversation activity. An empty visible history keeps its conversation entry with a null latestVisibleMessage.

History selects the newest `size` visible messages and returns them oldest-to-newest. If `hasMore` is true, pass `nextBeforeMessageId` unchanged as `beforeMessageId` to fetch older messages. Message IDs establish committed order within each conversation; gaps are normal. Only returned incoming non-deleted messages are marked read. A client should fetch history only when showing that conversation, not for a background inbox refresh. Opening a page does not mark older, unloaded messages read.

Unread counts exclude self-deleted messages and everyone-deleted messages. Delivery requires a recipient acknowledgement; a successful send or WebSocket event alone does not imply delivery. Reading establishes deliveredAt if absent. Repeated acknowledgements preserve their first timestamps. The sender sees the recipient's deliveredAt/readAt in the message response.

Self deletion affects only the caller's history and preview. Everyone deletion has no time limit and is allowed only for the sender, including after self deletion or connection removal. Both histories then show a tombstone (`content: null`, `deletedForEveryoneAt` populated), unless already self-deleted. Underlying content is retained for later reporting/administration; no public endpoint exposes it. Both deletion operations are idempotent.

Common errors: 400 validation or invalid pagination; 401 invalid/expired/revoked session; 403 no accepted connection or unauthorized sender/recipient action; 404 nonparticipant or unavailable record/member; 409 retry conflict or acknowledging a deleted message. Nonparticipants cannot inspect a guessed conversation or message ID.

## Live updates

Use a native WebSocket connection to `/ws/chat` (`wss://` with HTTPS). Within 10 seconds of connecting, send one text frame:

```text
AUTH <accessToken>
```

Do not place credentials in the URL. No chat events are sent before authentication. Successful authentication returns `{"type":"READY"}`. After committed chat changes, connected participants receive `{"type":"CHAT_CHANGED"}`. Multiple changes may be coalesced into one event. Send `PING` to receive `{"type":"PONG"}`; other application frames close the socket. REST handles all messages, receipts, and deletions.

On READY, CHAT_CHANGED, and reconnect, automatically fetch the conversation list and the currently open history page, if any. This delivers incoming messages without manual refresh. Close/refetch on session changes, clear cached content on logout, and replace cached message content when a deletion tombstone arrives. Use the idempotency UUID to reconcile optimistic sends. Do not append duplicate pages or treat an invalidation as a new message.

Only a hash of the authentication token is kept in socket state. Token rotation, expiry, logout, account suspension, or anonymization invalidates it. Each outbound event rechecks session validity; an idle socket is checked every five seconds. After refresh, reconnect with the new access token. Unauthenticated sockets time out after ten seconds, checked by the five-second sweep. Limits: five sockets per user, 1,000 total per instance, 128-byte incoming text/binary message limit, bounded outbound send buffering. Session/authentication failure closes with code 1008.

Allowed browser origins come from `CHAT_ALLOWED_ORIGINS` (comma-separated, exact origins; no wildcard). Defaults: `http://localhost:8080,http://localhost:3000`. For Flutter web, use a fixed development port and add its exact origin. A non-browser client without Origin must still authenticate. Origin allowance does not configure REST CORS; use the same-origin deployment/proxy for browser REST requests.

The event registry is in-memory and supports one backend instance. Events are hints, not a durable queue: REST is the recovery path after disconnect or server restart. Use a shared event broker before deploying multiple instances. Connection removal immediately blocks REST sends; clients should refresh after connection actions to update canSend.

## Two-account Swagger walkthrough

1. Start the backend with Java 21 and the dev profile. Flyway applies V8. Use two ACTIVE accounts, e.g. Hasan (user 2) and Saika (user 3). Obtain fresh login tokens.
2. Your previous connection was REMOVED. Send a new connection request and accept it as the recipient. Confirm ACCEPTED before chat testing. Do not assume the new connection ID is 1.
3. Authorize as Hasan. POST `/api/v1/chat/messages` with receiverId 3, a new UUID, and text. Save the returned message id and conversationId. Repeat the identical body: expect the same message id and only one stored message.
4. Authorize as Saika. GET `/api/v1/chat/conversations`: expect unreadCount 1. PATCH the message `/delivered`: deliveredAt set, readAt null. GET that conversation's `/messages`: content visible, readAt set. Inbox unreadCount becomes 0.
5. Reply as Saika with receiverId 2 and another UUID. Expect the same conversationId. As Hasan, open history and verify both messages in chronological order.
6. Delete one message `/self` as Saika: it disappears only for Saika. Delete Hasan's message `/everyone` as Hasan: its content becomes null for both visible histories. Trying everyone deletion as the recipient returns 403.
7. Remove the accepted connection. Sending now returns 403; both participants can still fetch old history. Reconnect and send again: conversationId stays the same.
8. A third ACTIVE account must get 404 for either conversation history or receipt/deletion operations using those IDs. Requests with no token return 401.
9. To test real time, open Swagger at `http://localhost:8080/swagger-ui/index.html` in the recipient's browser. Open developer tools and run this snippet. The token stays in memory; it is not written to a file or URL. Incoming changes automatically refresh the inbox. Use this only on your own local development page.

```javascript
const chatToken = prompt('Recipient access token');
const chatSocket = new WebSocket('ws://localhost:8080/ws/chat');
chatSocket.onopen = () => chatSocket.send('AUTH ' + chatToken);
chatSocket.onmessage = async ({data}) => {
  const event = JSON.parse(data);
  if (event.type === 'READY' || event.type === 'CHAT_CHANGED') {
    const response = await fetch('/api/v1/chat/conversations', {
      headers: {Authorization: 'Bearer ' + chatToken}
    });
    console.log('Chat inbox:', response.status, await response.json());
  }
};
chatSocket.onclose = ({code}) => console.log('Chat socket closed:', code);
// When finished: chatSocket.close(); then close this developer-tools session.
```

Send from the other account. Expect CHAT_CHANGED and an updated inbox without manually refreshing. Logging out the recipient, rotating its token, or waiting for expiry closes the old socket. For an open conversation, add a history fetch in your UI event handler; it marks the returned messages read.

## Verification

```bash
cd code/backend
./mvnw clean verify
```

`ChatIntegrationTests` covers persistence, permissions, receipts, pagination, deletions, reconnection, idempotent retries, concurrent first sends/retries/removal, rollback, HTTP behavior, and real WebSocket origin/event routing. `ChatSocketHandlerTests` covers authentication gating, coalescing, session revalidation, timeout, per-user limits, and disconnected clients.

The patch was prepared against main commit `73ac122`. Full Maven verification must run on Java 21: the authoring environment had Java 17 and could not resolve Maven Central, so it could not compile or execute this suite. Syntax and patch-applicability checks do not replace that verification.
