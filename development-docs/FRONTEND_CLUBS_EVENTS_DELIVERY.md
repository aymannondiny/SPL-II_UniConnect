# Clubs and events frontend

Implemented in `code/frontend/lib/features/club`, using the existing Flutter
view/controller/model/data structure. Each production file has one focused
responsibility; the largest new production file is 220 lines. Shared `AppTheme`,
Material text styles, `SectionCard`, workspace navigation and responsive spacing
keep the new screens consistent with the existing pages.

## Delivered behavior

- Open **Clubs & events** from desktop navigation, mobile **More**, or home.
- Browse the paginated club directory and search by name or category. Searching
  narrows the directory; selecting a club separately scopes the publication feeds.
- Open a freshly fetched club profile, read its description/contact information,
  and select **Show this club’s updates**. Publishing suspension is explained.
- Read paginated announcements, priority labels, full announcement details and
  published times. Full content renders as text, never HTML.
- Browse all current, upcoming or live events. Select a club to access its past
  events. Clearing the club selection exits history and restores current events.
- Open freshly fetched event details, descriptions, local start/end times,
  locations and registration deadlines. Valid HTTPS registration metadata is
  selectable and can be copied. Expired registration is shown as closed.
- Refresh campus data explicitly. While this destination is active, known
  announcement expiry/event start/end boundaries trigger a publication refresh.
  Returning to the destination refreshes publications. There is no publication
  WebSocket subscription or polling for unknown new publications; use Refresh.
- Loading, empty, unavailable, malformed-response and retry states are distinct.
  Load-more failures preserve existing rows; obsolete searches cannot replace
  newer results. Club-directory authentication uses the current session token;
  public publication requests omit authentication. Authenticated 401 ends the
  local session through the existing session controller.

## API integration and limitations

Production uses these existing contracts:

| Endpoint | Frontend use |
| --- | --- |
| `GET /api/v1/clubs` | Authenticated directory/search and pagination |
| `GET /api/v1/clubs/{id}` | Authenticated club profile |
| `GET /api/v1/announcements` | Public feed, optional club filter |
| `GET /api/v1/announcements/{id}` | Fresh public announcement detail |
| `GET /api/v1/events` | Current/upcoming/live feed, optional club filter |
| `GET /api/v1/events/{id}` | Fresh public event detail |
| `GET /api/v1/clubs/{id}/events/history` | Selected club’s published history |

API timestamps without offsets are interpreted as UTC and displayed locally.
Lists follow `{items,page,size,totalElements}` with page size 12.

There are **no production mocks**. `tool/support/campus_fixture_api.dart` provides
synthetic clubs/publications only to tests and the explicit `tool/preview.dart`
entry point. Example registration URLs in that preview are fixtures, not live
registration services. No account or club was created during verification.

The backend at `127.0.0.1:8080` refused the live events request on 2026-10-19.
Live account-authenticated club browsing and real data therefore still need an
available backend, database, a verified test account, and the existing allowed
frontend origins. Configure `API_BASE_URL` and CORS as described in the frontend
README. No new backend endpoint is required for the delivered browsing flows.

RSVP, attendance, follow/subscription and membership application models are absent
from the backend contract; the UI does not simulate those actions. Registration
is external to UniConnect. Club filtering is not a change to the authenticated
identity context. Operator dashboard/context switching, publishing forms, operator
assignment and lifecycle administration are outside this browsing implementation.

## Verification and reproduction

Run from `code/frontend`:

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8080
flutter run -d web-server -t tool/preview.dart --web-hostname=127.0.0.1 --web-port=3001
```

Open `http://127.0.0.1:3001/?screen=clubs` for fixture-based visual QA. Add
`&theme=dark` for the existing dark theme. Production starts with `lib/main.dart`.
Flutter analysis covers lint and Dart static typing; there is no separate
TypeScript/npm type-check command in this Flutter project.

New tests cover authenticated/public transport, filters, history paths, malformed
responses, unavailable items, session expiry, UTC conversion, safe registration
URLs and deadline boundaries, stale searches, pagination retry, disposal, club
selection, history reset, live empty states and responsive interaction flows.
The widget matrix is 1440×900, 390×844 and 320×640 in light and dark themes.
Browser screenshots use explicit fixtures and are under `development-docs/screenshots/clubs`.

Verification on 2026-10-19: repository-wide Dart formatting passed (176 files,
zero changes), Flutter analysis passed with no issues, all 180 frontend tests
passed, and the final production release web build passed. The release app was
served and opened successfully on loopback port 3003; port 3000 was already in
use. Browser inspection covered desktop and mobile fixture screens and event
details. Production authentication/data success remains blocked by the unavailable
local backend. The added feature, fixtures and tests comprise 22 new Dart files
and 1,664 lines, without duplicating implementations or adding padding.

## Git delivery and contribution boundaries

The initial delivery was left uncommitted. The authorized follow-up Git delivery
uses cohesive commits with relevant tests, on `codex/clubs-events-frontend`:

1. `feat(clubs): add club and publication models with UTC date handling`
2. `feat(clubs): add API transport and contract tests`
3. `feat(clubs): add paginated feeds with stale-response protection`
4. `feat(clubs): coordinate club selection and publication refresh`
5. `feat(clubs): build responsive searchable club directory`
6. `feat(clubs): add club profiles and publication detail loading`
7. `feat(announcements): add campus announcement feed and details`
8. `feat(events): add event feed and external registration details`
9. `feat(clubs): compose campus workspace and timing filters`
10. `feat(home): connect clubs navigation and update feature status`
11. `test(clubs): wire campus fixtures into the visual preview`
12. `docs(clubs): document integration, checks and visual evidence`

Keep each snapshot coherent and the final complete branch passing all checks.
Do not split by line count or add empty commits. Useful ways to grow contributions afterward
include genuine bug fixes, accessibility improvements, integration tests and
separate operator-publishing features, each reviewed as a focused change.
