# Project teammate finder review and delivery

Verified on 26 October 2026. Integrated with remote main at `dfba137` before
the user-authorized commit and push.

## Findings and changes

The Spring project controller and Flutter repository agree on route names,
request fields, response envelopes, student eligibility, and owner-only actions.
The existing backend already enforces privacy, capacity, application uniqueness,
and lifecycle rules. No backend or database change was needed.

| Finding | Change |
| --- | --- |
| Candidate load-more read edited, unsubmitted filters | Keep the submitted query for every subsequent page |
| Older candidate requests could replace newer results | Ignore completions from superseded request generations |
| Desktop search fields were squeezed into a single row | Use two columns on desktop, one on mobile |
| Fixed search controls consumed short viewports | Bound the filter region and let it scroll independently |
| Duplicate skill checks differed from the API | Normalize whitespace and case using a focused validation helper |
| More than 50 skill rows could be added | Match the API limit and disable Add skill at 50 |
| Capacity edits allowed fewer places than existing members | Show validation before submitting |
| Deadline selection used the device calendar day | Derive today in Asia/Dhaka and identify that zone in the form |
| Management retained its original listing after accepting | Reload current listing details with applications, members, recommendations, and audit |
| Editing from management reused stale capacity | Pass the refreshed listing to the edit form |
| Remaining applications could still offer Accept on a full team | Disable Accept when the refreshed backend listing is full |
| Owner action errors appeared behind the modal | Display actionable errors and Retry within management |
| Management did not rebuild when mutation state changed | Listen to controller changes and disable mutation controls during requests |
| Application status crowded narrow cards | Move the status into the content column on small screens |
| The finder page mixed many responsibilities | Extract cards, statuses, header/tabs, filters, state panels, and presentation formatting |

The finder composition decreased from 1,104 to 428 lines. Extracted presentation
files range from 17 to 196 lines. The existing view/controller/model/data
structure and injected repository remain in place. Shared colors, typography,
buttons, cards, dialogs, navigation, and light/dark themes are retained.
The existing finder page and dialogs cover the workflow; a separate new route
would duplicate it and was not added.

## Backend/frontend contract audit

| Workflow | Real API used by production |
| --- | --- |
| Browse and filter projects | `GET /api/v1/projects` |
| Owner listings and lifetime applications | `GET /api/v1/projects/mine`, `applied` |
| Standalone teammate search | `GET /api/v1/projects/candidates` |
| Details, create, edit | `GET/PUT /api/v1/projects/{id}`; `POST /api/v1/projects` |
| Listing lifecycle | `POST .../{id}/close`, `reopen`; `DELETE .../{id}` with confirmation body |
| Apply and owner review | `POST .../{id}/applications`, `POST .../applications/{id}/accept`, `reject` |
| Owner management data | `GET .../{id}/applications`, `recommendations`, `members`, `audit` |
| Department options | `GET /api/v1/profile/academic-options` |

Browse, mine, applied, candidates, applications, and audit parse the backend
`items/page/size/totalElements` envelope. Members and recommendations parse
arrays. The management repository already follows all application and audit
pages. Browse and candidate results load additional pages explicitly.

Closed and expired listings retain details. Pending applications remain
reviewable after closing or expiry, subject to capacity. The backend owns final
eligibility and capacity decisions, including concurrent acceptance. There is
one lifetime application per student/project and no withdrawal endpoint.
Deleted listings appear as null projects in applied history.

The backend additionally offers project-scoped strict candidate search at
`GET /api/v1/projects/{id}/candidates`. The current owner UI uses ranked
recommendations; standalone search uses the collection candidate endpoint.
Exposing strict project-scoped search is an optional future enhancement.

## Verification

| Check | Result |
| --- | --- |
| Project Dart formatting | Passed; 38 files checked, zero remaining changes |
| `flutter analyze --no-pub` | Passed; no issues; includes Dart type checking |
| `flutter test --no-pub` | Passed; all 321 tests after main integration |
| Production release web build, local renderer resources | Passed |
| Separate release fixture-preview build | Passed |
| Maven `verify` | BUILD SUCCESS; 335 tests reported, zero failures/errors, 3 skipped |
| Backend startup using test profile and H2 | Started on port 3080 |
| Backend OpenAPI HTTP smoke check | HTTP 200 |
| Unauthenticated project collection | HTTP 401, as expected |
| Production frontend HTTP and browser smoke check | HTTP 200; `/login` renders |
| Preview HTTP check | HTTP 200; Project Finder renders |
| Browser inspection | Desktop 1440×900 and mobile 390×844, light and dark views |
| Responsive widget inspection | 1440×900, 390×844, and 320×640 in both themes |

Fourteen new tests cover skill/capacity/date validation, normalized candidate
queries, edited-filter pagination, out-of-order search responses, responsive
finder/applied/search layouts, refreshed owner capacity and edit payloads,
full-team acceptance disabling, and visible review conflicts.

The backend project-specific suite passed 28 tests: 12 candidate integration,
8 lifecycle integration, 7 recommendation scoring, and 1 migration test.
Maven compiles/packages the backend and runs its tests; the repository has no
separate configured Java lint task.
The three skips are PostgreSQL mentorship smoke/upgrade tests: their dedicated
database and migration URL were unavailable. They are outside Project Finder.

The installed SDK used for these checks is Flutter 3.47.7 / Dart 3.13.5.
The repository pins Flutter 3.47.1; verify with that exact SDK in CI as well.
Dependency versions were not upgraded.

## Real behavior, fixtures, and integration limits

The incoming project-scoped candidate method was preserved. Its response
parsing now uses the same actionable-error boundary as other project queries.
Two additional contract tests check its authenticated URL, optional filters,
pagination, deserialization, and malformed-response handling.

Production imports no preview fixtures and continues to call authenticated
HTTP endpoints. Backend integration tests use real services and migrations with
isolated H2 databases. They are not a PostgreSQL deployment verification.

Browser visual checks use `tool/preview.dart`, its fake session/profile, and
the existing workflow fixture transport. Its project listings and roster are
fixtures; its My posts and Applied lists are empty. Candidate success results
and owner mutations are covered by dedicated HTTP test doubles in widget tests,
not a live authenticated browser session. The preview is not an end-to-end demo
of every mutation.

The release production login page was rendered without signing in. A successful
real browser-to-backend project workflow still needs a team-owned verified
student account, another eligible candidate/applicant, a configured persistent
PostgreSQL environment, and a matching API URL/CORS origin. SMTP verification,
real notifications, and actual team-to-team workflows were not exercised.
No shared database records were created or modified.

Ports 3000 and 8080 were occupied, so isolated checks used backend 3080,
production frontend 3081, and preview 3082. The production build was compiled
with `API_BASE_URL=http://localhost:8080`; it was not connected to the isolated
H2 backend at 3080. To test that pair, rebuild with the corresponding API URL
and preserve its allowed origin. Temporary browser viewport overrides were
reset after inspection.

Local screenshots are under `code/frontend/build/project-qa/` (ignored build
artifacts): `desktop-light.jpg`, `mobile-dark.jpg`, `search-mobile-dark.jpg`,
`search-desktop-dark.jpg`, and `production-login.jpg`. Command logs are under
`development-docs/project-*.log` and are also ignored.

## Reproduce checks

From `code/frontend`:

```powershell
dart format --output=none --set-exit-if-changed lib/features/project test/unit/project_form_validation_test.dart test/widget/project_finder_test.dart test/widget/project_management_test.dart
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8080 --output=build/project-production
flutter build web --release --no-web-resources-cdn -t tool/preview.dart --output=build/project-preview
dart tool/serve.dart build/project-production 3081
```

Run the preview server in another terminal:

```powershell
dart tool/serve.dart build/project-preview 3082
```

Open `http://127.0.0.1:3082/?screen=projects`, optionally adding `&theme=dark`.
From `code/backend`, run `./mvnw verify`. The local verification used installed
Maven with an explicit path to the existing local dependency cache.

## Main integration and meaningful commits

The initial delivery remained uncommitted as requested. After a later explicit
request to integrate, commit, and push, the local work was saved in a recovery
stash, main was fast-forwarded from `c2ae00a` to `dfba137`, and the stash was
applied without conflict. Both sets of imports and the incoming candidate API
were inspected. No force push or merge commit is required for that update.

A reviewable sequence is:

1. Extract finder presentation widgets and keep behavior unchanged.
2. Align form rules with the backend and add validation tests.
3. Fix candidate query pagination/races and add search regression tests.
4. Refresh owner management state and cover capacity/conflict behavior.
5. Improve responsive search/application layout and its layout tests.
6. Document the contract review, runtime evidence, and integration limits.

Some files contain changes from multiple groups. Use selective staging of
related hunks, and keep dependencies and matching tests in the same commit.
Combine dependent groups if they cannot pass independently. Run the relevant
checks before each commit and the complete suite on the resulting branch.
Avoid empty commits, repeated cosmetic changes, duplicate implementations,
and line padding. Useful tests, bug fixes, accessibility improvements, and
documented integration work provide stronger contribution evidence.
