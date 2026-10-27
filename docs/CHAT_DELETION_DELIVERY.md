# Delete chat for yourself

Users can open the three-dot menu beside any inbox conversation, choose
**Delete chat for me**, and confirm. Cancel leaves the conversation untouched.
A failed request preserves the conversation and displays an error.

Deletion removes the conversation from that user's inbox and hides every
existing message from their history. The other participant retains their copy.
A new message in either direction restores the conversation, but does not
restore messages that the user previously hid. There is no undo or hard purge.

## Integration

- `DELETE /api/v1/chat/conversations/{id}/self` returns HTTP 204.
- Authentication and conversation membership are required. Nonparticipants get
  HTTP 404; repeating a valid deletion is safe.
- Flyway migration V30 adds a participant-specific `hidden` flag, defaulting to
  false for existing conversations.
- Existing message visibility flags hide old history. Inbox pagination and its
  total count exclude hidden conversations.
- The existing user-pair lock serializes deletion with sending and connection
  removal. Only the deleting user receives the deletion refresh event.
- New messages restore inbox visibility for both participants. Retrying an old
  message does not restore a deleted conversation.
- The frontend discards stale inbox responses after deletion, clears a deleted
  selected thread, and refreshes other sessions through the existing realtime
  and polling flow. It prevents duplicate delete submissions and concurrent
  sending/deletion from the same page.

The production entry point uses the actual HTTP repository. Only the explicit
`tool/preview.dart` entry point and widget tests use fake sessions/chat data.
Backend integration tests use the real service, controllers, security, and
Flyway migrations with H2 in PostgreSQL mode and a deterministic clock.

## Review evidence

- Backend `mvn verify` with `ChatIntegrationTests,ChatSocketHandlerTests`:
  30 tests passed and the executable JAR packaged successfully with V30.
- Frontend chat repository and deletion widget checks: 15 tests passed,
  including comparison against the final screenshot baselines.
- Full frontend regression suite: all 502 tests passed.
- Flutter static analysis: no issues. Changed Dart files pass format checking.
- Final production web release build and Wasm compatibility dry run passed.
  The release app was served on port 3013 and returned HTTP 200.
- The backend started on port 8082 using the test profile and isolated H2
  database. HTTP requests reach the authentication filter; protected endpoints
  correctly require authentication.
- The explicit fixture preview ran on port 3012 and served HTTP 200.

The initial broad backend suite was stopped to reduce resource contention;
the completed backend verification covers the chat and WebSocket scope.

Responsive widget tests cover 1440×900, 390×844, and 320×640 layouts, confirmation,
cancellation, request success, and server failure. The `test/widget/goldens`
directory contains inbox and confirmation screenshots rendered with the app's
Roboto font and Material icons. These were visually inspected for clipping,
readability, and access to both dialog actions.

Run frontend checks from `code/frontend`:

```powershell
dart format --output=none --set-exit-if-changed lib/features/chat test/widget/chat_deletion_test.dart test/unit/chat/chat_repository_test.dart tool/support/fake_chat_repository.dart
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```

Run relevant backend checks from `code/backend`:

```powershell
mvn verify '-Dtest=ChatIntegrationTests,ChatSocketHandlerTests'
```

Browser automation repeatedly timed out while opening the running preview.
Rendered widget inspection therefore does not claim a completed browser-driven
or Android-device end-to-end check. Deployment requires the backend migration
and endpoint alongside the updated client.

The initial checkout lacked V29, `index mentorship reads`, already present in
the configured development PostgreSQL database. Updating from origin/main
before pushing restored that migration. This change uses V30 to avoid reusing
the existing version. Shared-database startup was not rechecked after that
update. No Flyway repair or schema-history rewrite was performed.

## Commit organization

Keep commits cohesive and reviewable rather than adding padding or empty
commits. A useful sequence for this change is:

1. `feat(chat): persist participant-specific conversation visibility`
   — migration, entity, repository, service, controller, and backend tests as
   one working backend feature.
2. `feat(chat): add conversation deletion to the client API`
   — HTTP repository method and its request contract test.
3. `feat(chat): add confirmed inbox deletion and refresh handling`
   — menu, deletion coordinator, page state, concurrency guards, and inbox sync.
4. `test(chat): cover deletion across desktop and mobile layouts`
   — preview fixture, widget scenarios, and rendered screenshot baselines.
5. `docs(chat): document deletion behavior and verification`
   — this delivery record.

For future work, commit each completed bug fix, feature, meaningful refactor,
test improvement, or documentation improvement separately. Keep related changes
together, run relevant checks, and use descriptive messages. Extra blank lines,
duplicated logic, and artificially tiny commits make the project harder to
review without improving the contribution. No commits, pushes, or merges were
performed during implementation. The user subsequently authorized committing
and pushing this work to main.
