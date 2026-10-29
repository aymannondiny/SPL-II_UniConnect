# Club Home overview

27 October 2026.

## Problem and result

Club Home and Club workspace previously both rendered ClubManagementPanel.
Club Home now renders a separate read-only ClubHomePage. Club workspace retains
the existing profile, announcement and event management tools.

The overview shows the selected club and assignment, publishing availability,
upcoming/live event count, current published announcement count, draft count,
and up to three upcoming/live events sorted by start time. Removed events,
past events and expired announcements do not inflate the current summaries.
The Open club workspace action leads to the existing management destination.

Loading and failure states do not invent zero counts. Retry and manual refresh
reload the snapshot. Returning to Home from management refreshes it automatically.
The snapshot uses the existing club detail and paginated managed publication APIs.
Representative summaries reflect the publications returned for their assignment;
they are not guaranteed to be whole-club totals.

## Files and design

- club_overview.dart: snapshot loading and summary calculations.
- club_home_page.dart: overview lifecycle and read-only page presentation.
- club_overview_metrics.dart: responsive summary cards.
- workspace_destination_builder.dart: distinct Home destination and management link.
- Focused calculation, responsive widget, retry/refresh and navigation regression tests.

The existing SectionCard, theme colors, typography, button styles and workspace
shell are reused. Summary cards wrap into one column on narrow screens. No new
UI dependency, backend endpoint, schema migration or authorization rule was added.

## Verification

- Full frontend suite: 399 tests passed. The additional retry/refresh regression
  test was then added and passed separately (400 passing tests across these runs).
- Flutter analyze --no-pub: no issues (lint and Dart type analysis).
- Dart formatting: 358 files checked, zero changes required.
- git diff --check: passed.
- Production release web build: passed, including Wasm compatibility dry run.
- Separate fixture preview release build: passed.
- Updated preview served HTTP 200 at http://127.0.0.1:3002/.
- Rendered overview captures inspected at 1440 and 320 pixels. Widget layout checks
  cover widths 1440, 390 and 320 in both light and dark themes without exceptions.
- Existing full-shell role navigation checks cover 1440x900, 390x844 and 320x640.
- Running in-app mobile browser verified student-to-club switching, distinct Home,
  Open club workspace, Events, New event dialog, Cancel and return to Home.
- SDK used: installed Flutter 3.47.7 / Dart 3.13.5; repository pin unchanged.

Screenshots: code/frontend/build/role-qa/club-home-{1440,390,320}-{light,dark}.png.
The screenshot files are generated evidence, not committed source artifacts.

## Real APIs, fixtures and integration limits

Production uses the existing authenticated ClubRepository. No production mocks
were added. tool/preview.dart remains an explicit fixture entry point. Its managed
publication fixtures now filter by the requested club instead of returning every
club's publications. Preview writes are not proof of persistent server changes.

A live authenticated club-admin session and event creation against the backend
were not exercised. End-to-end integration requires a running backend/database,
an active student account and current club administrator/representative assignment.
Publishing must be enabled to create new events. The overview adds no new backend
integration requirement. Backend tests were not rerun because backend code did not
change. Browser verification was mobile; desktop visual verification used rendered
Flutter widgets and full-shell widget navigation tests.

## Suggested commits (none created)

Each group should be independently reviewable and include its relevant tests:

1. Add club overview snapshot and summary calculations, with unit tests.
2. Add themed responsive club Home and metric cards, with layout/refresh tests.
3. Route club Home separately from management, with navigation regression coverage.
4. Scope preview publication fixtures to their club.
5. Document behavior, verification and integration boundaries.

Use these meaningful boundaries when authorized to commit. Further contributions
should address real follow-up issues (for example accessible date/time pickers or
persistent preview publication fixtures), each implemented and verified separately.
Avoid empty commits, whitespace-only churn and duplicated code for contribution counts.
No commit, push or merge was performed.
