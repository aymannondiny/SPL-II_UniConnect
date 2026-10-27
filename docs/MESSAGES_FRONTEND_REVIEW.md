# Messages frontend review — 27 October 2026

## Desktop design fix

Following the audit, the requested desktop layout fix is implemented in `chat_layout.dart`: Messages now follows the workspace's 900px desktop breakpoint, keeps the inbox alongside the conversation, renders the welcome panel before selection, and fills the available width and height with consistent padding. A divider separates the panes. Mobile retains the inbox/thread switch. The profile test now asserts these corrected behaviors and regenerates the screenshots. Production API behavior is unchanged. No commit, push or merge was performed.

The sections below preserve the original audit findings; layout findings 1–3 are addressed by this follow-up. Other integration risks remain open. The generated previews show the updated design.

## Scope and evidence

The initial audit left production code unchanged and added `code/frontend/test/widget/chat_profile_review_test.dart` to make the observations repeatable. The later desktop fix is described above. No commit, push, or merge.

Rendered the real `AuthenticatedWorkspace` and shared `ChatPage` using explicitly injected fixtures. Sizes are Flutter logical pixels: 320×640, 390×844, 900×700, 1440×900, 1536×864, and 1920×1080. Dark theme matches the supplied reference. Student and Alumni cover inbox, selected conversation, and sending. Alumni additionally covers an empty inbox and zero accepted connections. System administrator, club administrator, and representative contexts cover navigation/access restrictions at every size. Simulated a 300px keyboard inset at 390px for Student and Alumni.

PNG evidence is generated under `code/frontend/build/chat-review/`. This is Flutter widget rendering, not a browser/device end-to-end test. Physical keyboard behavior, browser zoom, device safe areas, light-theme visual QA, and live two-account delivery are not certified by these checks.

## Role/context matrix

| Profile/context | Messages behavior |
| --- | --- |
| Student, Personal | Available; same messaging layout and repository as Alumni |
| Alumni, Personal | Available; desktop layout inconsistency reproduced |
| System administrator | Workspace controller selects System administration; Messages is intentionally excluded |
| Student with Club administrator assignment, Club context | Messages intentionally excluded; return to Personal to message |
| Student with Representative assignment, Club context | Messages intentionally excluded; return to Personal to message |

The club assignments are workspace contexts rather than additional platform account roles. See `workspace_context_controller.dart` and `workspace_access.dart`.

## Confirmed layout findings

1. **Desktop uses phone-style navigation inside Messages (P2).** `chat_layout.dart` uses `constraints.maxWidth < 1240`, after the desktop shell subtracts its 268px sidebar. The shell itself switches at viewport width 900. Consequently a 1440px viewport has 1172px content and hides the inbox when a thread opens, with a Back to inbox button. At 1536px it becomes two-pane. The actual threshold is 1508 logical viewport pixels. Student and Alumni behave identically. Browser scaling can therefore change the result even on a physically wide monitor. Use available pane space to choose a practical two-pane threshold independently of shell chrome.

2. **Blank desktop right pane on initial entry (P2).** Above that threshold, the inbox is fixed at 320px and the thread is only inserted when `_showThread` is true. The existing `ChatWelcomePane` is never reached for the initial unselected state. This explains the large blank area in the supplied screenshot; it does not establish that the backend is mocked. Show the welcome pane whenever desktop has no selection. Evidence: `ALUMNI-1920-inbox.png` and `ALUMNI_EMPTY-1920-inbox.png`.

3. **Panel is vertically capped and centered (P2, polish).** Embedded Messages caps its height at 620/640px instead of filling the available workspace. Tall desktop screenshots show large unused bands, while the Student workspace selector changes vertical placement compared with Alumni. Evidence: `ALUMNI-1920-inbox.png` and `STUDENT-1440-inbox.png`. Consider filling the available height and keeping padding consistent.

4. **Empty-recipient copy is misleading (P3).** With zero accepted connections, New message says “You already have conversations with all your accepted connections.” It should distinguish having no connections from having existing conversations with everyone. Reproduced by the empty Alumni fixture at every checked size.

Phone inbox/thread layouts at 320 and 390 logical pixels had no Flutter layout exceptions in this audit. Conversation selection, composer, send button and back control fit. At 320px the bottom Connections label wraps; it remains readable. Simulated keyboard inset checks also produced no layout exception; these are not physical-device keyboard tests.

## What works and what is mocked

Production `ChatPage` defaults to `ChatRepository(ApiClient())`. The repository uses authenticated REST for conversation pagination, latest/older history, accepted connections, sending with an idempotency UUID, delivery acknowledgement and deletion. History GET marks returned incoming messages read on the server. The WebSocket transports `AUTH`, `PING` and invalidation hints; it is not used to send message bodies. These endpoints have corresponding backend controller/service implementations. There is no production fake repository fallback.

The existing tests verify request paths, auth headers, cursor parsing, deletion scope, safe failures, recipient selection, a revoked connection, workspace navigation and unauthenticated entry. This audit additionally exercises the actual workspace for each eligible role and renders desktop/mobile states. Sending assertions establish that the UI passes the expected recipient and displays the fixture response; they do not prove database persistence or recipient delivery.

All accounts, profiles, connections, conversation content, send responses, and sockets in the visual audit are fixtures. `tool/preview.dart` likewise explicitly injects `FakeChatRepository`; its successful send is a preview only. That fake socket produces no incoming updates, and its default history has no older pages. Neither receipts, deletion propagation, nor reconnect reliability can be established from preview screenshots.

## Integration risks from code review

These require targeted regression tests and live verification; they were identified by tracing code, rather than reproduced against a running backend.

- **Reconnect can miss content changes (P1).** `chat_realtime.dart` refreshes only the inbox on READY. `_refreshInbox` reloads a selected thread only if the latest message ID is absent locally. An edit to receipt/deletion state of an already-known message, or an older message's deletion during a disconnect, can therefore remain stale. Polling is skipped once `_socketToken == _token`. Refresh the currently open history on READY/reconnect, as the API contract requires.
- **Loaded old messages are not fully reconciled (P1).** Quiet history refresh merges the newest 20 messages into cached history by ID (`chat_inbox.dart`). A self-deleted message absent from the response remains cached; a deletion tombstone outside that newest page is never refreshed. Another device's deletion can leave previously loaded content visible. Reconcile the loaded range, including removals and older-page invalidations.
- **Timestamp timezone mismatch (P2).** The backend contract specifies UTC strings without suffixes. `chat_models.dart` passes them directly to `DateTime.tryParse`, which treats those strings as local wall time. `chat_time_format.dart` then formats without UTC normalization or conversion. On a Dhaka client, displayed times can be six hours behind actual local send time. Parse according to the documented UTC contract before formatting for the chosen display timezone.

REST and socket endpoints exist; no missing endpoint was identified for the implemented text-chat scope. Attachments, typing indicators and online presence are explicitly outside the current API contract.

## Remaining integration verification

No local service was found listening on frontend ports 3000/3001 or backend port 8080 during the initial environment check. No real authenticated accounts were supplied. Live end-to-end testing was therefore not performed, and backend tests were not run for this frontend audit.

To finish integration verification, run the backend with its database and migrations, use two ACTIVE accounts with an ACCEPTED connection, and configure the frontend API URL plus exact REST and WebSocket allowed origins. Check incoming messages, unread/read/delivery transitions, older history, both deletion scopes across devices, connection removal, token rotation and disconnect/reconnect recovery. The socket event registry is instance-local; multiple backend instances require shared invalidation infrastructure or a reliable REST recovery strategy, per `docs/api/ONE_TO_ONE_CHAT.md`.

## Reproduce

Final verification: **67 tests passed**, including 36 profile/size audit cases and the existing messaging/access checks. `git diff --check` completed without errors. The run log is `code/frontend/build/chat-review/test-results.txt`.

From `code/frontend`, run:

```powershell
flutter test test/widget/chat_profile_review_test.dart test/widget/chat_recipient_test.dart test/widget/chat_workspace_integration_test.dart test/unit/chat/chat_repository_test.dart test/unit/workspace_access_test.dart --reporter expanded
```

The profile test now asserts the corrected desktop welcome pane, persistent desktop inbox, full-height layout, mobile back navigation and role/context restrictions. The other integration findings above remain open.

Environment: installed Flutter 3.47.7 / Dart 3.13.5, newer than the README's stated Flutter 3.47.1 / Dart 3.13.1. Screenshots and the saved run log are generated artifacts, not production changes.
