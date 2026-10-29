# Password quality and confirmation

Registration and reset-password flows now use the same local password rules in
`code/frontend`, the standalone `mobile` client, and backend services. Login does
not apply new-password rules, so existing users are not locked out.

## Validation

- Require 8–72 UTF-16 code units and at most 72 UTF-8 bytes, matching the existing
  BCrypt storage limit. Spaces are preserved; passwords are never trimmed.
- Reject whitespace-only and ASCII numeric-only values, including `12345678`.
- Reject common substrings: password, qwerty, letmein, welcome, admin, iloveyou,
  uniconnect, abcde. Matching is case insensitive and normalizes common
  substitutions: 0/o, 1/i, 3/e, 4/a, 5/s, 7/t, @/a, $/s.
- Reject four consecutive copies of one character and whole-password repetition
  of a shorter pattern.
- Reject four-character forward or reverse runs from the alphabet, digits,
  qwertyuiop, asdfghjkl, or zxcvbnm.

The backend enforces these rules for both registration and reset. The public API
contract does not change. Confirmation is a local input and is never transmitted.

## Meter

0: empty. 1/weak: fails validation. 2/fair: accepted, but below the following
thresholds. 3/good: at least 12 characters excluding surrounding whitespace, or
three character types. 4/strong: at least 12 characters excluding surrounding
whitespace and three types (lowercase, uppercase, digits, non-whitespace symbols),
or at least four distinct alphabetic words of three or more letters, totalling
at least 20 characters excluding surrounding whitespace. Predictability checks
always run before scoring.

Examples: `12345678` and `P@ssw0rd123!` are rejected; `Reef7!ox` is good;
`R7!mQ2#vL9@x` and `reef violet lantern otter` receive the strong estimate.
These examples are public test fixtures and should not be used as real passwords.

This is a bounded local heuristic, not a comprehensive dictionary, a cracking-time
estimate, or a breached-password check. No new external service or mock runtime
security dependency is introduced. Future breach screening can strengthen it.

## UI and verification

The shared app uses one confirmation widget for registration and reset, with
separate visibility control, exact matching, autofill hints, and disabled state
while submitting. It inherits existing light/dark themes. The standalone mobile
client retains its existing confirmation controls and gains the equivalent meter.

Regression tests cover numeric passwords, substitutions, sequences, repetition,
byte limits, passphrase scoring, confirmation mismatch, and registration/reset
at desktop, mobile, and narrow-mobile sizes in both themes. Layout review tests
write rendered PNGs under `code/frontend/build/password-review` (ignored by Git).
UI repositories in interaction tests are fakes; backend integration tests use H2
and mocked mail delivery. Real database and SMTP deployment still require the
existing environment configuration. No schema migration is required.

## Suggested commit boundaries (not executed)

1. Backend password policy and service integration.
2. Backend policy and authentication regression tests plus valid fixtures.
3. Shared Flutter password policy and validation adapters.
4. Reusable confirmation field and registration/reset integration.
5. Shared Flutter policy, form, responsive and screenshot regression tests.
6. Standalone mobile policy, meters, secret preservation and tests.
7. Password-policy documentation and verification results.

Each commit should be coherent and reviewable; combine boundaries when needed
so commits compile and tests pass. Do not pad source files or create empty,
cosmetic-only commits merely to inflate contribution metrics. Use further real
fixes, test coverage, accessibility work, and documentation for future commits.

## Standalone mobile integration limitation

The older `mobile` workspace already uses `/api/auth/*` endpoints and a `role`
registration field. The current backend uses `/api/v1/auth/*` and `platformRole`.
The shared `code/frontend` app uses the current API contract. This change aligns
password behavior in both clients but does not migrate the older mobile client's
entire authentication transport. Its live registration/login/reset integration
remains blocked by that pre-existing contract mismatch. Its password policy and
meter run locally. Passwords now retain exact whitespace through its provider and
transport as well as its forms.

## Verification results (26 October 2026)

- Shared frontend: `flutter analyze --no-pub` clean; full `flutter test --no-pub`
  passed 341 tests; an additional confirmation edit/visibility test passed.
- Standalone mobile: analysis clean; 14 tests passed in the full run; the new
  exact-password transport test passed separately.
- Both clients: `flutter build web --release --no-pub` succeeded.
- Backend: Maven `verify` succeeded. Surefire reports 348 tests, zero failures,
  zero errors, three skipped (345 executed). The skipped tests require a
  PostgreSQL migration URL and the unavailable `uniconnect_smoke` database.
- Desktop/mobile render inspection: 1440x1000 and 390x844, light and dark themes,
  screenshots reviewed. Registration/reset interaction tests additionally cover
  1440x900, 390x844, and 320x640 in both themes. No overflow exceptions occurred.
- App launched using Flutter web-server at `http://127.0.0.1:5173/#/sign-up`.
  Browser automation timed out twice; visual QA used rendered Flutter screenshots
  with bundled app fonts, not a live browser interaction session.
- `git diff --check` passed. No commits, pushes, or merges were performed.

## UI follow-up

Removed the email caption. Password guidance is hidden initially and while
starting to type, and appears with validation errors after leaving an invalid
password field or submitting the form. It disappears after successful validation.
Applied to registration and reset in both clients; the strength meter remains.
Focused shared authentication tests and a new guidance visibility test passed;
mobile tests (15) passed, analysis is clean, and both release web builds passed.
Desktop/mobile rendered layouts were checked again. The updated release preview
is served on the existing port 5173.

The implementation was initially left uncommitted for review. The user subsequently
authorized focused commits and a push to the existing branch.
