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

## Meaningful commit boundaries

A possible reviewable sequence after approval:

1. Fix series/enrollment lifecycle enum handling and safe unknown states.
2. Map additive series timing and occurrence fields.
3. Render next/ongoing schedules and occurrence lifecycle labels.
4. Wire enrollment reopening through repository/controller/host controls.
5. Add participation history with loading, retry and period privacy.
6. Preserve finite recurrence and times in session editing.
7. Fix mobile form overflow and history storage identity.
8. Add model, HTTP contract, controller and responsive regression tests.
9. Add mentorship visual fixtures and preview navigation.
10. Document verification, limitations and follow-up work.

Use selective staging to keep dependencies coherent; build/test each logical
checkpoint before committing. Each commit should represent a real, explainable
change. Do not split arbitrary lines, add empty commits, duplicate logic, or
pad formatting to increase counts. Tests, accessibility fixes, documentation
and independently useful follow-up features provide legitimate contributions.
The initial delivery left all changes uncommitted. The user subsequently authorized commit and push; the implementation is grouped into six focused commits covering models, API/state integration, schedules, history/host controls, session editing/tests, and preview/documentation. No merge was requested.
