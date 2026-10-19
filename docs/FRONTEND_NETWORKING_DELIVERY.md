# Frontend networking readiness delivery

This change closes the major usability gaps in the existing Discover,
Connections, Messages, and Home flows before starting Clubs & events.
Initial implementation and QA made no commits or account-data changes.
Commit and push were subsequently authorized by the repository owner. No
dependency change or backend migration is part of this delivery.

## Implemented behavior

- Populated connection cards use a horizontal flex only in the desktop row;
  narrow cards stack identity and wrapping actions without unbounded flex.
- Connection lists and chat's inbox/accepted-recipient picker follow the backend
  `totalElements` through subsequent pages instead of stopping at 50 records.
  Discovery exposes a load-more action for pages of 20 members.
- Discovery supports name, Student/Alumni role, academic department, up to ten
  comma-separated skills, company, and graduation year. Department choices come
  from the existing academic-options API. Failed catalog loading has a retry;
  the other filters remain usable. Invalid skills/year inputs are rejected.
- Public member details open from discovery. The server's public profile
  representation supplies biography, skills, interests, shared skills, student
  availability, and alumni professional details. Private details are withheld
  even if an unexpected response includes them alongside `detailsVisible=false`.
  Owner email and student-number fields are never used by this view.
- Message actions pass the selected user's identity into the workspace inbox.
  Existing conversations open directly; otherwise a draft opens for the selected
  accepted connection. The accepted-connection API is checked before opening.
  Repeated navigation requests work for an already mounted chat page. Changing
  recipients clears the previous draft text.
- Connection/discovery pages refresh when revisited; request generations prevent
  stale searches from replacing newer results. Load-more keeps submitted search
  criteria rather than silently applying unfinished edits in the search box.
- Empty chat states scroll when reduced height would otherwise overflow.
- Filter expansion and text inputs have distinct page-storage keys so the
  expansion flag cannot be restored as a text-field scroll offset. This was
  found in browser QA and covered with the workspace scroll key in the test.
- Home lists working networking/profile cards first, labels available desktop
  cards Open, forwards the administrator role, and replaces unavailable summary
  counts with useful shortcuts. Planned content is explicitly described as in
  development. Workspace search opens Discover instead of a placeholder.
- Light burgundy and dark green/gold colors, typography, cards, input decoration,
  and navigation continue to come from the existing theme/components.

## Code organization

Connection transport, typed models, search criteria, asynchronous state,
filter inputs, toolbar, list cards, profile page, and profile-detail rendering
have separate files. The connection page orchestrates navigation and dialogs.
The former large chat page is split into small widgets and private library parts
for lifecycle collaboration: realtime refresh, inbox/history, recipient selection,
mutations, navigation, chrome, panel layout, and thread/composer layout. Parts
share a single State object and do not create duplicate polling/socket owners.

## Verification

Run from `code/frontend`:

```powershell
dart format --output=none --set-exit-if-changed lib/features/chat lib/features/connection lib/features/home/view tool/preview.dart tool/support/fake_chat_repository.dart tool/support/member_fixture_api.dart test/unit/connection_controller_test.dart test/unit/connection_repository_test.dart test/widget/chat_recipient_test.dart test/widget/connection_workspace_test.dart test/widget/home_feature_status_test.dart
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-pub --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8080
```

The complete suite has 160 passing unit/widget tests, including 41 new tests.
After the browser-found storage-key correction, the 18 populated networking
widget tests were rerun and passed.
New coverage includes multipage REST contracts, authentication expiry, invalid
filters, privacy, out-of-order requests, failed load-more retry, populated
connection/request actions, member profiles, recipient selection, and sending.
Populated networking screens are checked at 1440x900, 1024x768, 390x844, and
320x640 in light/dark themes. Recipient chat tests include 1440x900, 390x844,
and 320x640. Existing authentication/profile/navigation tests also run.

Browser QA uses `tool/preview.dart`, a separate entry point with injected fake
session/profile repositories, an in-memory member HTTP transport, and a fake
chat repository. Production `lib/main.dart` never imports this fixture code.
The preview accepts `screen=home|discover|connections|messages`, `theme=light|dark`,
and an optional `width` for a constrained responsive viewport:

```powershell
flutter run -d web-server -t tool/preview.dart --web-hostname=127.0.0.1 --web-port=3023 --no-web-resources-cdn
```

## Integration limits and remaining work

The normal app calls real APIs. The local backend was not listening on port
8080, so no live multi-account connection/chat, WebSocket delivery, database
write, or email delivery claim is made. Mock transport and fake chat exercise
frontend behavior, not backend integration. Validate those flows with two real
accounts once the backend and database are available.

Clubs/events, notifications, administration, projects, careers, and mentorship
remain planned destinations. The administrator card's access flag is fixed;
this change does not implement account moderation screens. Search is currently
member discovery, not cross-module search. Home does not claim live activity
counts or recommendations. Photo upload is still not implemented, and sessions
remain in memory by the existing authentication design. Connection/chat lists
currently aggregate all server pages, so very large communities may later need
incremental/virtualized loading rather than eager aggregation.

## Commit organization

The delivery uses these independently meaningful commit groups:

1. `feat(frontend): improve chat recipients pagination and responsive layout`
2. `fix(frontend): clarify home availability and responsive shortcuts`
3. `feat(frontend): complete responsive member discovery and profiles`
4. `test(frontend): wire populated networking previews`
5. `docs(frontend): document networking verification and integration limits`

Behavior tests accompany the implementation they verify. The latest upstream
change from PR #66 is preserved: opening Messages starts with the conversation
list; selecting a conversation or using Message from Connections opens a thread.
Dedicated desktop/mobile tests cover both paths.

Use real features, bug fixes, tests, accessibility, and useful documentation as
future contribution units. Avoid filler lines, empty commits, or splitting a
single statement just to increase counts. Many additions here are code moved
into focused files; raw line churn is not a measure of new functionality.
