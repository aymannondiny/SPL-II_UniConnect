# Email verification frontend handoff

The active shared web/Android client in `code/frontend` now uses the backend's
email plus six-digit verification-code contract. No backend code was changed.

## Behavior

- Registration immediately opens code entry with a prefilled email and check-inbox instructions.
- Login offers verification recovery with its entered email carried forward.
- Direct `/verify-email` entry permits email and code input without an automatic request.
- Codes remain strings, including leading zeros, and accept exactly six ASCII digits.
- The keyboard supports numeric entry and one-time-code autofill.
- Verification requires HTTP 204 and then automatically opens login.
- Invalid codes and transport errors permit correction or retry.
- Resend needs only a valid university email, expects HTTP 202, and uses conditional wording.
- The UI explains expiry, attempt limits, issuance intervals, and hourly limits.
- Simultaneous verification/resend requests and duplicate submissions are prevented.
- Old verification-token models, fragment handling, and link-status/recovery widgets were removed.
- Password recovery now also uses code entry; see [its current API](api/PASSWORD_RESET.md).

## Structure

The API repository, request controller, validation rules, code input, form,
and page lifecycle each have one responsibility. The page
keeps the established responsive authentication shell and themes. New production
files are small; no padding or redundant abstractions were added for line count.

## Validation performed

- Dart formatting on every changed/new Dart file.
- `flutter analyze`: no issues (lint and static type checks).
- `flutter test --no-pub`: 393 passed in the final full regression run.
- Focused verification/registration run after automatic signup and login navigation
  tests: 21 passed.
- `flutter build web`: passed, including the Wasm dry run.
- `flutter build apk --debug`: passed.
- `git diff --check`: passed.
- Browser review of the production web build: 1440x1000 desktop, 390x844 mobile,
  and 320x640 mobile. Verified readable layouts, scrolling to resend, dark/light
  themes, empty-input validation, leading-zero entry, and connection-error recovery.
- Widget tests cover desktop and mobile layouts down to 320 pixels, success to
  login, invalid-code retry, resend without code entry, and disposal during a request.

## Real versus mocked

Production code uses the real HTTP client. No fake code, delivery, verification
success, or session is injected into the running app. Unit tests mock HTTP;
widget/controller tests use controlled repository fakes. These tests verify UI
and API-contract behavior, not actual SMTP delivery or database activation.

No backend was listening on `localhost:8080` during this review. The browser
showed the expected connection error for synthetic test input. Live registration,
code delivery, expiry/attempt enforcement, replacement-code activation, and
subsequent login still require the current backend with Flyway V27, database,
and SMTP running. Use frontend port 3000 for the backend's default development
CORS configuration. The standalone production visual preview on port 3001 needs
that origin explicitly allowed before live cross-origin integration testing.
Physical Android devices also need a reachable `API_BASE_URL`; emulator defaults
already use `10.0.2.2:8080`. No Android emulator/device session was exercised.

## Contribution workflow

Keep commits focused on a meaningful
behavior and include its relevant tests. Potential review topics for this work
are the new API contract, request-state handling, code-entry UI, registration/login
handoff, retirement of link handling, and integration documentation. Several topics
share interfaces, so combine dependent changes when necessary to keep each commit
compiling and tested. Use interactive staging when preparing commits later.

For future work, add useful regression cases and accessibility improvements in
separate tested commits, and commit each completed bug fix or feature increment.
Avoid empty commits, repeated format changes, duplicate code, or artificial line
padding. More commits should reflect more reviewable progress.
