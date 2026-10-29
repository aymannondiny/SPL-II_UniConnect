# Role dashboards and workspace contexts

Delivery date: 27 October 2026.

## Behavior

The authenticated client uses a shared layout and theme with separate Student,
Alumni and System Administration experiences. One presentation policy determines
desktop navigation, mobile navigation, home cards and allowed workspace
destinations. Backend authorization continues to enforce the actual permissions.

| Workspace | Relevant destinations |
| --- | --- |
| Student personal | Home, Discover, Connections, Messages, Notifications, Clubs & events, Project finder, Career board, Mentorship, My reports, My profile |
| Alumni personal | Home, Discover, Connections, Messages, Notifications, Clubs & events, Career board, Mentorship, My reports, My profile |
| System administration | Administration overview, Account management, Club administration, Club requests, Report queue, Academic catalog, Notifications, My profile |
| Admin personal | Personal overview, Discover, Connections, Messages, Notifications, Clubs & events, My reports, My profile |
| Assigned student club | Assigned club workspace, Notifications, My profile; Personal remains available through the workspace selector |

Project finder is absent from alumni and administrator menus, home cards and
navigation entry points. Passing an unauthorized initial destination does not
instantiate its page or request its API. Search is only a shortcut to people
discovery; global search, account anonymization and warnings have no actionable
navigation entries.

The admin landing page provides links to existing workflows, without fabricated
statistics. Direct management destinations open the matching section without
requesting the academic catalog as a prerequisite for account/report work.

## Career Board amendment

The project owner explicitly requested alumni browsing in addition to author
management. This extends the earlier student-only interpretation of FR_57.
The API contract and Career Board decision document record this amendment.

- Students and alumni browse active posts using the existing filters and sorting.
- Alumni select **My career posts** to request `/api/v1/career/posts/mine`,
  including their published, expired and closed author history.
- Publishing switches the alumni view to their own-post filter.
- Alumni can open other authors' active posts, but cannot open their historical
  closed/expired posts through ordinary detail endpoints.
- Save and external Apply remain student-only; alumni responses return
  `canApply=false`.
- Edit and Close remain alumni-author-only. Browse cards do not expose author
  mutation controls; the own-post filter does.
- No internal job-application records, admin job/project deletion, author
  deletion or reopening endpoints were introduced.

## Mentorship

Students in study year 2 or above and alumni may register as mentors. A missing
study year does not grant registration access. Year-1 students retain session
browsing and enrollment. Registered mentors receive hosting tools rather than
registration prompts. Both the page header and My Mentorship registration panel
use the same eligibility rule. Alumni retain enrollment and participation views.

## Context ownership

The workspace controller loads `/api/v1/auth/contexts` and only presents contexts
appropriate to the account role and returned current club assignment. System
administrators land in System administration and may switch to Personal.
Students may select their current club administrator or representative contexts.
Alumni do not receive club-management contexts.

Switching waits for the backend to accept selection before changing navigation.
Failed selections retain the previous workspace and show an error. Refresh
reconciles revoked assignments and the backend's selected context. Duplicate
switch requests are prevented, and page content is disabled while switching.
Previously visited pages are cleared after a successful switch.

Administration/report repositories and club panels no longer silently select a
different context. The workspace selector owns that responsibility. Club
management is reached through the shared selector rather than a second selector
inside Clubs & events. Representatives see their authorized publication
workspace, without the administrator-only club profile edit action. The backend
still filters representative publications to their current assignment.

Existing backend-only operator-assignment APIs were not expanded into a new
representative-management UI in this change.

## Structure

The access policy, context controller, context selector, mobile destinations,
admin overview, career tabs and mentor eligibility rule each have focused files.
Existing large views were separated into Dart library parts for page factories,
profile editing, career actions/filters/results, club publication lists, club
requests, academic catalog rows/widgets and individual dialog forms. Parts preserve existing library-private
state boundaries without duplicating models or introducing new dependencies.

The implementation adds actual behavior and regression coverage; it does not
pad source files to inflate line counts.

## Verification

- Complete frontend test suite: **390 passed**.
- Flutter static analysis: **no issues** at the completed analysis checkpoint.
- Production release web build: successful, including Wasm compatibility dry run.
- Focused backend Career Board suite: **8 passed**.
- Complete backend suite: **349 tests discovered, 346 passed, 3 skipped, zero failures/errors**.
  The skips are the PostgreSQL mentorship migration-upgrade check (missing
  `postgres.migration.url`) and two PostgreSQL mentorship smoke checks
  (`uniconnect_smoke` database unavailable).
- Backend `mvn -DskipTests package`: successful.
- Final Dart formatting check: **352 files checked, zero changes required**.
- Final Flutter analysis: **no issues**; final release web build succeeded.
- Additional final admin navigation/section checks: **21 passed**.
- Rendered visual checks: 1440×900, 390×844 and 320×640, light and dark themes.
  All three dashboards plus alumni Career Board are covered: **24 captured views**.
  The captures load the app's bundled fonts and use the actual application
  widgets. No overflow exceptions remain in these capture tests.

Validation used the installed Flutter **3.47.7** / Dart **3.13.5**. The repository
pins Flutter **3.47.1**; that exact SDK was not installed/used in this session.
No SDK pin or dependency version was changed.

Reproduce normal checks from `code/frontend`:

```powershell
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib test tool
flutter test --no-pub
flutter build web --release --no-web-resources-cdn --no-pub
```

Generate visual evidence explicitly:

```powershell
flutter test test/widget/role_dashboard_test.dart test/widget/career_role_browsing_test.dart --dart-define=CAPTURE_ROLE_DASHBOARDS=true
```

Captures are generated under `code/frontend/build/role-qa/`; regular test runs do
not write screenshots. These are rendered widget captures, not browser captures.
Browser attachment recovered during the pre-push verification. Browser checks
confirmed the administration card opens its destination without fixture errors;
`build/role-qa/browser-club-administration.png` records the result. Exhaustive
widget navigation checks click every relevant home card and sidebar destination
for all three roles at 1440, 390 and 320 pixels: **9 scenarios passed**. They
assert the actual destination page type, no error panel and no rendering exception.

These checks found and corrected two additional issues before publication:
missing admin club-list/request preview fixtures and narrow-screen admin profile
status/detail overflow. Fixture additions are test/preview-only. Club management
copy now describes administrator assignments without implying a fixed count.

Run backend checks from `code/backend`:

```powershell
mvn test
mvn -DskipTests package
```

## Runtime and integration boundaries

The production web build was served locally on port 3000. The debug visual-QA
entry point was run on port 3001. A fresh release build of the final preview is
served on port 3002 from `code/frontend/build/role-preview/`. The preview remains
explicitly separate from the production build. To run the debug entry point:

```powershell
flutter run -d web-server -t tool/preview.dart --web-hostname=127.0.0.1 --web-port=3001 --no-pub
```

Examples: `?role=SYSTEM_ADMIN`, `?role=ALUMNI&screen=career`, or
`?role=STUDENT&clubRole=REPRESENTATIVE`. Add `&theme=dark` or `&width=390`.

The backend was started on loopback port 8081 using the existing `test` profile,
an isolated in-memory H2 database, and loopback-only mail port 1. This does not
populate or modify a persistent PostgreSQL installation. The running protected
career endpoint returns 401 without a session, as expected.

Production code calls real authenticated repositories. Synthetic sessions,
profiles, listings, clubs, assignments, messages and mentoring data exist only
in the preview/test entry points. Preview career create/update/close operations
remain deliberately unimplemented fixture methods; production repositories use
the real API. No activity counts or pending-work totals are mocked into the
production dashboard.

A persistent end-to-end run still needs a configured PostgreSQL database, valid
accounts and the frontend API origin/CORS settings. The normal client defaults
to localhost:8080; use `API_BASE_URL` when targeting a different backend port.
SMTP is needed for registration verification/recovery flows. The H2 integration
tests do not substitute for PostgreSQL validation. No Android emulator/device or
APK installation was exercised; mobile checks cover the shared responsive UI.

## Authorized commit groups

The project owner authorized committing and pushing after dashboard navigation
verification. The work is grouped into seven coherent commits on
`codex/role-dashboards`:

1. Backend alumni career browsing, authorization regressions and API decisions.
2. Mentor eligibility rules, registration actions and regression coverage.
3. Shared role/context destination policy and navigation inventories.
4. Server-confirmed context controller, selector and club context contracts.
5. Alumni career browsing/own-post filtering, focused views and layout captures.
6. Dashboard integration, admin overview, focused club/catalog forms, responsive
   fixes, preview coverage and exhaustive destination regressions.
7. Frontend and delivery documentation.

The branch starts from the original checkout (`ddbd1c2`). Fetched remote main
advanced to `c31ca58` with a separate email-verification-code change; this task
does not merge or overwrite that work. Each commit represents actual behavior,
structure or documentation. No padding, empty commits or delete/re-add cycles
were used to inflate contribution statistics.
