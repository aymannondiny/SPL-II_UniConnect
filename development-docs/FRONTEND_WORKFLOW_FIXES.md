# Frontend workflow fixes — 26 October 2026

The shared Flutter app is `code/frontend`. The archived `mobile` prototype was
not changed. After the initial uncommitted delivery, the user explicitly approved
focused commits and a push. No schema migration or shared-database change was
performed.

## Delivered behavior

| Problem | Result |
| --- | --- |
| Projects disappear when skills contain `id` | Project skills read canonical `id`; legacy `skillId` remains accepted. A regression loads four populated projects. |
| Team rosters fail to parse | Memberships read canonical `id` and `userId`, retaining compatibility with the previous field names. |
| Contract failures resemble empty results | Project repository parsing converts malformed JSON/model contracts into actionable failures. Required page envelopes are validated; project lists show a persistent error and Retry action. |
| Reporting has no client workflow | My reports supports submission, paginated history, detail and resolution summaries. Contextual Report actions cover members, clubs, announcements, events, messages, projects and Career posts. |
| Account moderation has no client workflow | Administration includes account search, role/status filters, details, complete audit history, suspension and restoration. Actions require a reason and explicit confirmation. |
| Report review has no client workflow | Administration includes a filtered, paginated queue, retained evidence, review ownership, resolution, internal notes and action-evidence linking. |
| Notifications discard resource IDs | Project, mentorship-slot, report, club, member, connection and conversation navigation uses the referenced ID and owning APIs. Missing or unsupported destinations produce an explanation. |
| Lists stop at 50 | Notifications, project applications/audit, managed club publications and eligible administrator searches follow server pagination. New account/report lists expose Load more. The existing club directory already supported Load more. |
| Meeting links are inert | Both enrollment cards and mentorship details use a reusable button that opens an HTTP(S) link and reports launch failures. |
| Career Apply uses stale data | Application channels are rechecked when Apply is opened and again when a channel is selected. The resolver fetches the current address and eligibility and validates the scheme. Web navigation uses the current tab after the asynchronous check to avoid popup blocking. |

## Design and organization

New workflows reuse `AppTheme`, Material controls and `SectionCard`. Both the
burgundy light theme and green/gold dark theme are preserved. Forms scroll on
small screens; filters wrap within the available width. Administration uses a
section dropdown on narrow screens and segmented buttons on desktop.

Project models now live in individual files behind the existing public export
file. The former 1,600-line project dialog library is divided into focused parts
for forms, applications, candidates, management, details and shared presentation.
Network error conversion, authenticated JSON transport, pagination, meeting
links and career destination resolution have separate responsibilities.

## Verification

- `flutter analyze`: no issues, including Dart type and lint checks.
- `flutter test`: 301 tests passed in the final full-suite run after incorporating
  the latest remote changes. This includes administration selector coverage at
  1440, 390 and 320 pixels.
- `flutter build web --release`: production build passed; the isolated visual-QA
  target also builds in release mode.
- `flutter build apk --debug`: passed after provisioning the required Android
  NDK, Build-Tools 36 and Platform 36 through the installed toolchain. Output:
  `code/frontend/build/app/outputs/flutter-apk/app-debug.apk`. No physical-device
  or emulator run was performed.
- `mvnw.cmd verify -q`: 335 tests discovered, 332 passed, 3 skipped, no failures
  or errors. The skipped mentorship checks require an optional disposable
  PostgreSQL smoke/migration database.
- `git diff --check`: passed.
- New report/account workflows were exercised at 1440×900, 390×844 and 320×844,
  in both light and dark themes. Real-font screenshots were rendered and
  inspected at desktop and mobile sizes. The browser also opened the production
  app and the isolated authenticated preview, including the mobile report form,
  administration section selector/account list, and notification-to-project
  navigation with both team members visible.
- The real backend was started with `test` profile and an isolated in-memory H2
  database. Protected project, report and account endpoints return HTTP 401
  without a session, as expected.

Local logs and generated screenshots are in ignored build folders:

```text
code/frontend/build/analyze.log
code/frontend/build/all-tests.log
code/frontend/build/section-tests.log
code/frontend/build/visual-tests.log
code/frontend/build/release-build.log
code/frontend/build/preview-build.log
code/frontend/build/android-build.log
code/frontend/build/workflow-qa/
code/backend/target/surefire-reports/
code/backend/target/local-smoke.log
```

## Real integrations, mocks and remaining checks

Production uses the existing authenticated backend APIs. No production data is
mocked, and no credentials or fixture-login bypass is introduced in `lib/main.dart`.
The explicit `tool/preview.dart` entry point uses fake sessions, feature fixtures
and `WorkflowFixtureApi`; tests also use isolated fixtures. Preview mutations
change only their in-memory fixture state.

A signed-in browser acceptance pass against the shared PostgreSQL backend still
requires verified member and system-administrator test accounts. The isolated H2
server starts empty; email verification and live SMTP delivery were not exercised.
No shared account was suspended or restored during this work. The backend tests
exercise the real moderation/reporting services against their isolated databases.

Meeting-link launches are checked through a mocked platform channel; tests do
not join a real meeting. Career address refresh and channel eligibility are
covered with changing repository responses; no real application is submitted.

ACTION_TAKEN records an existing action rather than executing moderation. A
reviewer must first complete the relevant account, club or publication action,
then supply its committed action ID. Account audit details show action IDs.
The backend remains responsible for verifying evidence ownership, timing,
reversal state and reviewer authority. Concurrent changes return actionable
errors and can be retried after refreshing.

## Commit organization

Approval to commit and push was received after implementation and verification.
Changes are grouped into 20 focused commits, ordered so dependencies are introduced
before their consumers. The following feature boundaries guided that grouping;
`git log` records the actual commits. For future changes, `git add -p` can
separate mixed hunks while keeping intermediate commits buildable.

1. Refactor project models and dialogs into focused files.
2. Add shared response parsing, authenticated JSON and pagination helpers.
3. Fix project skill/membership contracts and visible parsing errors.
4. Follow all notification and management pages.
5. Add reporting models, repository, submission and history screens.
6. Add contextual reporting actions and workspace navigation.
7. Add account moderation and report-review administration.
8. Navigate notifications to their referenced resources.
9. Make mentorship meeting links actionable.
10. Resolve Career application destinations from current data.
11. Add contract, pagination, navigation, launch and responsive workflow tests.
12. Document delivery, verification and integration limits.

This provides meaningful commit boundaries. Add lines for useful behavior,
validation and tests; avoid padding, empty commits, or repeatedly changing the
same code solely to increase counts. Clear ownership and reviewable changes
provide stronger evidence of contribution than raw line totals.
