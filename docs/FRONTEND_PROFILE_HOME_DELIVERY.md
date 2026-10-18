# Profile setup and home delivery

Implemented on 2026-10-17 and refined on 2026-10-18. Verification completed before user-authorized publication.

## Behavior

- SessionHost owns the session above MaterialApp. Login renders the authenticated
  workspace using that shared session. Replacing a route no longer disposes the
  login session. Credentials remain in memory; reloading requires login again.
- Protected requests obtain the current bearer token through SessionController.
  Concurrent refresh callers share one operation. A profile API 401 clears the
  session and returns the workspace to login. Logout failures retain retry.
- The workspace distinguishes a missing profile (owner GET 404) from a failed
  request. Missing profiles enter setup; existing profiles enter home.
- Student and Alumni forms share name, biography, academic hierarchy, skills and
  interests. Each role has its own academic/professional fields and validation.
- Academic choices come from the backend catalog. Parent changes reset dependent
  selections. An existing inactive degree can be retained. Empty catalogs explain
  the administrator dependency and block submission. Catalog reload keeps drafts.
- Forms show the first invalid field, normalize skill/interest entries and preserve
  stored photo URLs on complete profile replacement. File upload is not offered.
- Privacy supports CONNECTIONS_ONLY (default) and ALL_MEMBERS. Email and student
  number are described as private. There is no Only me option.
- Profile and privacy save through separate real endpoints. A privacy failure after
  a successful profile PUT leaves the form open and explicitly asks for retry.
- Successful setup opens home. Existing owners can edit and return to home. Saved
  names update the current account shown in the session.
- Home follows the updated root HTML's greeting banner, arch motif, feature-card
  layout, shared desktop navigation and compact mobile navigation. Existing
  Material typography, logos, burgundy light theme and green/gold dark theme are
  reused. New profile identity and form sections follow the same card styling.
- Unimplemented feature destinations explain Coming soon. Home contains no sample
  request counts, fabricated events or invented activity. Administrators receive a
  workspace explanation instead of a Student/Alumni profile request.

## Architecture

Features use the established model/data/controller/view structure. Small widgets
own individual form sections and presentation responsibilities. Repositories and
controllers are injectable. The largest new production file is approximately 200
lines after formatting; related responsibilities are not padded or duplicated.

Primary files:

- `code/frontend/lib/core/session/session_scope.dart`
- `code/frontend/lib/features/authentication/controller/session_controller.dart`
- `code/frontend/lib/features/profile/`
- `code/frontend/lib/features/home/`

## APIs and integration

The production entry point is `lib/main.dart`. It uses real login, current-account,
refresh, logout and these profile endpoints:

| Method | Endpoint |
| --- | --- |
| GET | `/api/v1/profile/me` |
| GET | `/api/v1/profile/academic-options` |
| PUT | `/api/v1/profile/me/student` |
| PUT | `/api/v1/profile/me/alumni` |
| GET | `/api/v1/profile/me/privacy` |
| PATCH | `/api/v1/profile/me/privacy` |

Frontend configuration remains API_BASE_URL, defaulting to localhost:8080. Run the
production frontend on port 3000 to match the backend dev CORS configuration.
Production hosting needs SPA fallback for deep links. `/home` is protected and
shows login when no session exists; `/` and `/sign-up` remain registration entry
points. Internal Home/Profile navigation uses the authenticated workspace.

No mock account, academic option or successful save is reachable from the
production entry point. Test fixtures live under `tool/support` and are imported
only by tests and the explicit `tool/preview.dart` QA entry point.

Remaining integration work:

- A running configured backend and a verified Student/Alumni test account are
  needed for live success verification. The localhost:8080 health probe refused
  connection during this run. Automatic approval review rejected starting the
  configured backend because .env may target a shared database and startup can
  apply Flyway migrations. It was not started through another route.
- An administrator must populate academic options; no catalog values or admin
  credentials are seeded by this change.
- Photo upload/storage, reload persistence and the remaining module screens are
  outside this change. Home's feature cards do not implement discovery, clubs,
  projects, careers or mentorship, and live dashboard counts are not wired.
  Messages now opens the chat implementation integrated from main; see below.

## Verification

Run from `code/frontend`:

```powershell
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```

Formatting, Flutter analysis (including type checks), all 94 tests and the production
release web build passed. Tests cover authentication regressions, owner endpoint
contracts, malformed responses, missing versus failed profile loading, both role
forms, partial-save retry, logout, session expiry and responsive navigation.
Responsive widget coverage includes 1440x900, 390x844 and 320x640 in both themes.
The browser QA app was also inspected at desktop and 390/320 logical-pixel content
widths. Screenshots are kept in the ignored `code/frontend/build/screenshots/`
folder. Browser QA uses fixture accounts; it does not prove database persistence,
SMTP delivery or successful live authentication. The real production entry point
was also run: /home displayed login, and a fictitious login correctly showed the
backend-unavailable error.

To reproduce the isolated browser preview without external renderer assets:

```powershell
flutter build web --release --no-web-resources-cdn -t tool/preview.dart --output build/preview
dart tool/serve.dart build/preview 3003
```

Open `http://127.0.0.1:3003/?screen=setup&role=ALUMNI&theme=dark&width=390`.
Omit width for desktop, use screen=home for the populated home, and catalog=empty
for the administrator-catalog dependency. The width query constrains only the QA
entry point, letting browser inspection complement full-size widget tests.
`tool/serve.dart` serves build files on loopback with SPA fallback.

## Meaningful contribution and suggested commits

Commit and push actions require the project owner's instruction. A substantial contribution comes from
complete behavior, maintainability, validation and documented verification. Extra
blank lines, duplicated logic and empty commits add no engineering value.

When commits are authorized, use focused, reviewable groups such as:

1. Add PUT/PATCH support and HTTP contract coverage.
2. Preserve account roles and expose authenticated session access.
3. Add app-level session ownership and lifecycle tests.
4. Add profile/catalog models and owner-only API repository contracts.
5. Add profile loading, saving and partial-privacy-failure coordination.
6. Add validated shared profile fields and role-specific sections.
7. Add catalog-driven academic selection and inactive-degree retention.
8. Add profile setup/edit composition and supported privacy preferences.
9. Add wireframe-style home banner and feature cards.
10. Add responsive workspace navigation and authenticated handoff.
11. Add onboarding, expiry and desktop/mobile regression coverage.
12. Add isolated visual-QA tools and delivery documentation.

Some groups share files. Use selective hunks where useful, combine dependent
groups when needed, and keep each resulting commit buildable. Pair feature tests
with their feature where that makes review clearer. Do not commit the same edit
repeatedly, split one statement across commits, or manufacture whitespace churn.
For future work, deliver discovery, member profiles, connections and messaging in
small complete slices, each with its own useful tests and documentation. Verify
Git author attribution before committing so the work is recorded under your
intended identity. No Git identity, history or repository settings were changed.

## Updated-wireframe correction — 2026-10-18

Compared the implementation with the repository-root
`uniconnect-wireframe-v2-updated.html` and the supplied home screenshot.

- Restored every navigation entry under Main, Campus and Account: Home, Discover,
  Connections, Messages, Notifications, Clubs & events, Project finder, Career
  board, Mentorship, My profile and Administration. Sidebar navigation scrolls
  independently, with the owner card and logout available at the bottom.
- Matched the desktop search header and theme/notification/profile controls.
  The search field retains the reference's maximum width. Search currently opens
  the unavailable-feature notice rather than pretending to return results.
- Matched the mobile Home/Discover/Messages/Alerts/More tabs. More exposes the same
  grouped navigation inventory, including profile and the restricted admin item.
- Recreated gradient greeting/summary tiles and rounded arch artwork, the larger
  Discover and Clubs cards, the complete ten-card feature inventory, and the
  campus-events/people-suggestions sections. Existing fonts and both themes remain.
- Administration stays visible but disabled for Student/Alumni accounts. The HTML
  prototype displays it for its sample Student; that should not imply permission.
- Prototype counts, badges, events and people are examples. Production displays
  unavailable counts as an em dash, omits fabricated badges and uses explicit
  empty/planned states. Only profile and existing authentication flows are live.
- The prototype's Screen/theme/Web/Mobile/Annotations toolbar is a preview tool,
  so it is not included as a product control.

Formatting, lint/type analysis and all 103 frontend tests passed. Navigation tests
cover 1440x900, 1024x600, 390x844 and 320x640 in both themes, including scrolling,
mobile More access and the administrator restriction. Browser QA also caught and
fixed menu-row highlight clipping while the More sheet scrolls. Release builds and browser
checks use the same production/isolated-preview commands above. Design verification was completed before user-authorized commit and push. No
merge was performed.

## Integration with main — 2026-10-18

Resolved overlapping routing, account and fixture changes from main while keeping
the app-owned session, profile setup and complete home navigation. The obsolete
signed-in panel stays removed; Messages in the sidebar, mobile tabs and home card
now opens the incoming chat screen. Direct `/chat` navigation without a session
opens login. Chat reads the shared current token, and a chat authentication failure
expires the shared session. Saving a profile name preserves user ID and role.

Removed duplicate HTTP PATCH and session token declarations introduced by the
automatic merge. Corrected incoming web socket string-to-JavaScript conversions
required by the installed web package. Incoming mobile application files are
retained unchanged. Chat success against a live backend remains unverified.

Validation: formatting, Flutter analysis, all 115 frontend tests and the release
web build passed. Tests cover desktop/mobile Messages navigation, unauthenticated
chat deep links, and preservation of account identity during profile updates.
The project owner authorized committing and pushing the conflict resolution to
`codex/frontend-login-recovery`. This integrates main into the feature branch;
it does not merge the feature branch into main.

## Messages preview follow-up — 2026-10-18

Registered the production route generator in the isolated preview so Messages
works there as it does in the application. Updated the desktop Messages card
action from Coming soon to Open. Actual panel layout tests exposed an infinite
inbox width and header overflow on mobile; compact layouts now render a single
bounded pane and a constrained header. Chat accepts an optional repository for
isolated layout tests without network or socket activity.

All 119 frontend tests pass, including the real panel at 1440, 390 and 320 pixel
widths, navigation and feature-card entry, shared session identity and login
protection. Preview login/profile data are fixtures. Chat still uses its real API;
live conversations and sending require a reachable backend and accepted connections.
