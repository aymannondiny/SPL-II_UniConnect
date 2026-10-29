# Peer mentorship delivery — 2026-10-25

## Recommendations implemented

The main gap was frontend parity with the existing lifecycle API. This delivery
adds the missing behavior within the existing three mentorship tabs, preserving
the shared Material typography, rounded cards, light/burgundy and dark/green-gold
themes. A separate route was unnecessary.

- Parse COMPLETED series and COMPLETED/REMOVED enrollments. Unknown values fail
  closed instead of becoming open or active.
- Preserve meetingCount, enrollmentOpen, vacancies, next/ongoing meeting times,
  recurrenceEndDate and persisted occurrence details in client models.
- Prefer ongoing and next meeting times on discovery, enrolled and host cards.
  Label schedule values as Asia/Dhaka without converting them to the device zone.
  Older responses without occurrence times retain an explicitly labelled series
  start fallback.
- Show dated occurrences as Upcoming, Ongoing, Past or Cancelled using server
  lifecycle flags instead of labelling every date as upcoming.
- Offer enrollment reopening for a closed series with a vacancy and a future
  meeting; allow editing/cancelling closed series; hide mutation actions for
  completed, cancelled and unknown series. Backend remains authoritative for
  availability, conflicts and permissions.
- Add a lazy-loaded, retryable Participation History panel using my-participation.
  Retain separate leave/rejoin records, goals and messages. Historical meeting
  links are intentionally not rendered. Lifecycle dates are labelled UTC.
- Preserve host start/end times and recurrence bounds during edits. Add an end
  time picker and an explicit 1–52 meeting count. Keep an existing recurrence end
  date unless the host explicitly selects count-only scheduling. Validate end
  after start, count, capacity and required details before submitting. Requests
  send exactly one recurrence bound, as required by the backend.
- Distinguish own-profile HTTP 404 from outages using a typed missing-profile
  failure instead of matching words in error messages.
- Consolidate slot mutation/loading/refresh handling and reject duplicate slot
  submissions while another mutation is active.
- Fix narrow editor title/action overflow and give history expansion its own
  PageStorageKey, preventing scroll-offset/expanded-state collisions on mobile.

## Structure

Focused new components own schedule formatting, occurrence parsing, occurrence
presentation, history loading/presentation and date/time inputs. The existing
repository interface isolates HTTP from widgets; the controller manages feature
state. Repeated slot mutation logic was removed. The widget fixture was moved
out of the page test so visual QA and tests share it; production main.dart does
not import that fixture. No filler, duplicate implementation or artificial
line expansion was added.

## APIs and mock boundaries

Production uses the existing authenticated backend endpoints, including:

- GET /api/v1/mentorship/slots/my-current-series — card summaries.
- GET /api/v1/mentorship/slots/my-participation — enrollment periods.
- POST /api/v1/mentorship/slots/{id}/reopen — host operation.
- GET /api/v1/mentorship/slots/{id} — persisted occurrence lifecycle.
- POST/PUT slot requests — meetingCount and recurrenceEndDate.

HTTP contract tests use MockClient. Widget tests and tool/preview.dart use an
explicit fixture repository/session. Preview actions are simulated and do not
prove database persistence or notifications. Historical links are not rendered.
Backend tests use H2 and exercise real services, migrations and HTTP security.
The optional PostgreSQL tests require their dedicated environment variables.

## Run and verification

Frontend verification: all 252 tests passed, including actual edit submission,
lifecycle parsing, HTTP route contracts, profile outages, history and responsive
layouts. Final flutter analyze passed with no issues; formatting checked 45 files
with zero changes; the production web build and Wasm dry run both passed.
The running production frontend returned HTTP 200.

The installed SDK is Flutter 3.47.7 / Dart 3.13.5; the repository pins Flutter
3.47.1 / Dart 3.13.1. No SDK pin or dependencies were upgraded.

Frontend commands (from code/frontend):

```powershell
dart format --output=none --set-exit-if-changed lib/features/mentorship test/unit/mentorship_lifecycle_test.dart test/unit/mentorship_repository_test.dart test/unit/mentorship_controller_test.dart test/widget/mentorship_page_test.dart test/widget/mentorship_lifecycle_widget_test.dart tool/preview.dart tool/support/fake_mentorship_repository.dart
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://localhost:8080
flutter run -d web-server -t tool/preview.dart --web-port=3014 --web-hostname=127.0.0.1
```

Visual QA URL: http://127.0.0.1:3014/?screen=mentorship
Mobile preview: append &width=390&theme=dark. The width parameter constrains the
actual Flutter layout and MediaQuery to 390 logical pixels, within a desktop
browser viewport; this is not physical-device emulation. Widget checks use
1440×900, 390×844, and 320-pixel widths. History is tested in both app themes.

Backend verification (from code/backend):

```powershell
.\mvnw.cmd verify '-Dtest=*Mentorship*,Mentor*'
```

Result: BUILD SUCCESS; 48 discovered, 45 passed, 3 skipped, no failures/errors.
The skipped checks are two PostgreSQL smoke tests and a migration upgrade test.

The real backend also started using profile test and useTestClasspath=true on
8092, applying all 26 migrations to isolated H2. The production Flutter entry
point started on 3013 with API_BASE_URL=http://127.0.0.1:8092 and a matching
backend allowed origin. Unauthenticated participation requests return HTTP 401.
The health endpoint also requires authentication in this configuration.

## Integration limits and next useful work

A live signed-in mentorship journey against PostgreSQL was not exercised.
It requires a verified test member, an eligible mentor profile, and dedicated
PostgreSQL test credentials. SMTP/notification delivery and actual concurrent
production enrollment are not established by the fixture preview. No required
new backend endpoint or migration was identified for this frontend delivery.

Useful future contributions: actionable meeting links with launch-failure
handling; calendar export; timezone-aware reminder preferences; dedicated
PostgreSQL browser integration tests; accessibility tests with larger text;
and independent loading/error states per mentorship feed. These should be
separate scoped changes with their own acceptance criteria.

## Delivered commits

The initial plan suggested ten possible commit groups. Related changes were
combined into the following six delivery commits, all pushed to `origin/main`:

| Commit | Delivered change |
| --- | --- |
| `2f2bd6b` | Lifecycle, occurrence and recurrence models, status badges and model tests |
| `4004549` | Participation/reopening APIs, controller state, contract tests and shared fixture |
| `ec92780` | Next/ongoing meeting times and occurrence schedule presentation |
| `73e16b5` | Participation history and host enrollment controls |
| `1c874d0` | Responsive session editor, preserved recurrence/times and widget regression tests |
| `ef1cfa5` | Preview entry point, delivery documentation and updated READMEs |

New remote demo-seeding commits were fetched before publishing. The six local
commits were rebased onto them without conflicts and pushed normally. No
force-push or new merge commit was used.

A subsequent documentation-only commit replaces the outdated ten-group plan
with this actual delivery record. That correction is an additional commit;
it does not represent another feature or a change to the verified application.

## Future contribution guidance

Commit independently useful features, bug fixes, tests, accessibility work and
documentation as coherent changes. Keep required API, model and test updates
together when splitting them would leave a broken checkpoint. Avoid arbitrary
line splits, empty commits, duplicate logic and formatting padding.
