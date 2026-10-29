# Frontend and backend audit

Date: 26 October 2026

## Scope

Reviewed the maintained Flutter application in `code/frontend` (245 Dart source
files), its shared theme, feature views, repositories and models, and the Spring
backend's controller contracts (25 controller files), DTOs and test setup.
`mobile/README.md` explicitly identifies `mobile` as an archived prototype, so it
has not been restyled. The shared application serves both web and Android.

This is a source and automated-test audit. It does not certify that every page
has been manually inspected in a browser or against a deployed backend with
student, alumni, club and administrator accounts.

## Mismatches corrected

| Finding | Change |
| --- | --- |
| No explicit bundled application font; rendering depended on platform defaults. | Bundle Roboto as `UniConnectSans`, including regular, medium, bold and black weights and their italics, with its license. Apply it through both themes. |
| Project finder, discovery and mentorship used heavier page headings than careers, clubs and administration. | Centralize headline weights in `AppTheme`; remove individual page overrides. |
| The editable profile used the larger onboarding headline. | Use the standard workspace headline while editing; retain the larger onboarding heading. |
| Club description used a larger text role than other workspace introductions. | Use the shared body-medium role. |
| Default cards used a different shape from shared section cards. | Set a 24-pixel default card radius in both themes. Specialized message bubbles and compact tiles retain their intended shapes. |
| Inputs used a border with no visible focus outline. | Add a two-pixel theme-primary focus border in both themes. |
| Chat duplicated theme colors for its standalone header and composer. | Read the scaffold and input colors from the active shared theme. |
| Standalone chat always showed four notifications, irrespective of server data. | Remove the fabricated count and retain the notifications shortcut. |
| Standalone chat advertised cross-module search, while its implementation only filtered conversation names. | Label it `Search conversations`, matching the embedded chat and implemented behavior. |
| Deleted outgoing messages changed their bubble background but retained the outgoing timestamp color. | Use the surface foreground for the deleted timestamp; add tests requiring at least 4.5:1 contrast in both themes. |
| Chat text used isolated fractional font sizes. | Use the shared body-medium and label-small styles. |
| Project and mentorship tabs differed in padding, corner radius and label style. | Align their geometry and use the shared label-large text role. |
| Registration allowed names longer than later profile updates permit, and email addresses longer than storage permits. | Validate trimmed names at 100 characters and normalized emails at 320 characters before submission. |

## Frontend/backend observations

- Repository endpoint families correspond to backend controllers for
  authentication, profiles/catalogs, discovery/connections, clubs/publications,
  chat, notifications, careers, projects, mentorship, reporting and administration.
  No missing endpoint was identified in the reviewed request paths. This is not
  a complete proof of all request/response combinations.
- Chat's 5,000-character message limit agrees with `SendMessageRequest`.
- Notification single-read expects HTTP 200, while mark-all-read and delete
  expect HTTP 204; those agree with `NotificationController`.
- Current mentorship cards request `my-current-series`, matching the backend's
  card-summary endpoint rather than its separate enrollment-record endpoint.
- Backend follow-up: add maximum lengths to `RegisterRequest` as well. Its
  full-name and email fields have no `@Size` annotation, although profile name
  updates enforce 100 characters and the persisted email column allows 320.
  Frontend validation now protects the UI flow; direct API callers still need
  equivalent server validation.
- Cross-module search is outside the implemented scope documented in the root
  README. Keep search labels limited to the actual destination or filter until
  that capability exists.
- Notification target navigation uses client-side reference-type routing and
  authorized resource fetches. The dedicated target-resolution endpoint remains
  a documented backend gap; avoid adding a client call to a nonexistent API.

## Recommended next frontend work

1. Extract a shared responsive page header and reusable counted-tab widget.
   Typography is now centralized, but project, mentorship, careers, clubs and
   administration still maintain their own header/control structures.
2. Standardize loading, empty, retry and validation presentation across feature
   pages. Preserve meaningful differences between forms, directories and chat.
3. Introduce paged notification loading before histories become large.
   `ApiNotificationRepository.list()` currently loads all pages, and the visible
   notification page polls every ten seconds. Consider a backend unread-count
   endpoint or push updates before adding a live header badge.
4. Persist the theme preference. `app.dart` currently initializes dark mode on
   each new app instance; the toggle uses an in-memory notifier.
5. Add representative screenshot baselines at desktop and narrow mobile widths,
   plus large-text checks. Existing widget tests cover many responsive flows,
   but do not guarantee pixel-level visual consistency across all screens.
6. Perform a signed-in acceptance pass for each platform role against a local
   backend: registration/login, privacy, connections, messages, club contexts,
   career application redirects, projects, mentorship and moderation.

The burgundy light palette, green/gold dark palette, photographic auth hero and
home banner are intentional variations. Different heading sizes for onboarding,
page titles, sections and cards are also intentional; all inherit the same font.

## Validation

- `flutter analyze --no-pub`: passed after the final source changes.
- Full existing Flutter suite: 301 tests passed.
- New deleted-message tests: passed in light and dark modes, checking timestamp
  contrast and the shared font family.
- Final affected profile, onboarding, club, mentorship and contrast widget tests:
  33 passed.
- Registration boundary and sign-up widget tests: 5 passed.
- Flutter web release build: passed, including the Wasm compatibility dry run.
  The generated font manifest includes every declared `UniConnectSans` asset.
- `git diff --check`: passed.
- Maven `verify` using the existing local dependency cache: build passed;
  335 tests reported, zero failures/errors, three skipped.

Backend tests use the `test` profile with isolated H2 databases, not the shared hosted database.
No backend implementation or database migrations were changed. No commit or
push was performed.
