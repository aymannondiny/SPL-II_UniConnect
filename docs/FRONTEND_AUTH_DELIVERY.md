Current profile/home work supersedes the temporary signed-in handoff described
below. See [Profile setup and home delivery](FRONTEND_PROFILE_HOME_DELIVERY.md).

# Login and password recovery delivery

Implemented on 2026-10-17 against the root updated HTML wireframe and the current
Flutter registration/email-verification screens. The work is organized on the
`codex/frontend-login-recovery` feature branch; merging remains a separate action.

## Responsibilities

| Layer | Responsibility |
| --- | --- |
| Models | Session/account response parsing, safe failures, login validation, reset links/password rules |
| Data | Shared auth HTTP/error boundary, session API contracts, recovery API contracts |
| Controllers | In-memory session lifecycle and serialized refresh; recovery submission state |
| Views | Page composition and dependency lifetime |
| Widgets | Form input, validation presentation, headings, actions, notices, signed-in handoff |
| Core | Route registration, initial deep links, fragment cleanup, shared theme preference |

No production fixture, demo account, fake login, or fake reset delivery is used.
Test repositories and HTTP fixtures live under `test/` only. Credentials are not
stored in URLs, logs, analytics, or localStorage. Reset-token links use fragments,
which are removed from the current browser history entry after capture.

## Integration boundaries

Use the running backend at `http://localhost:8080` and Flutter on port 3000;
these origins match the documented dev CORS policy. Real successful login needs
a verified, ACTIVE test account. Recovery email delivery needs working backend
SMTP and a frontend `PASSWORD_RESET_URL` pointing to `/reset-password`.

The authenticated home/profile UI is still pending. Successful login currently
shows the name and email returned by `/auth/me` and a working logout action.
Credentials last only while the login page is mounted; page reload requires a
new login. A future authenticated application shell should own this controller
when protected destinations are added.

## Verification

Run from `code/frontend`:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-pub --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8080
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=3000 --no-pub --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8080
```

The tests cover exact REST paths, payload normalization, password preservation,
bearer placement, malformed responses, network/credential failures, duplicate
submissions, rotating refresh credentials, logout/retry, disposal, reset token
parsing, UTF-8 password limits, reset confirmation, and theme continuity.
Widget flows exercise 1440×900, 390×844, and 320×640 in both themes.

Verified on 2026-10-17: formatting check (70 Dart files, no changes), Flutter
analysis (no issues), all 58 unit/widget tests, release web build, and
`git diff --check` passed. The app ran on `127.0.0.1:3000` against the existing
development backend on port 8080. Browser inspection covered desktop and mobile
login themes, 320-pixel scrolling, recovery navigation, the reset form, and
reset-token fragment removal. A synthetic invalid login reached the real backend
and displayed the expected generic credential rejection without mocks.

Successful login, refresh, logout, password-request acceptance, and password reset
are exercised with test-only repositories/HTTP mocks. Live SMTP delivery and a
successful real-account login must be checked with a team-owned test account.

## Meaningful commit groups for review

The implementation is split into these cohesive increments in dependency order.
Route-name constants precede screens, router cases follow their page classes,
and deep-link entry handling is separated from shared theme state.

1. `feat(auth): model session and account contracts`
2. `feat(auth): add safe HTTP transport and session repository`
3. `test(auth): verify session API payloads and failures`
4. `feat(auth): manage in-memory sessions and token rotation`
5. `test(auth): cover session concurrency and logout lifecycle`
6. `feat(auth): add shared form presentation widgets`
7. `feat(auth): implement password recovery contracts and route names`
8. `feat(auth): build password recovery and reset screens`
9. `feat(auth): build wireframe login and signed-in handoff`
10. `feat(routing): connect authentication screens and email handoffs`
11. `feat(routing): handle login and reset deep links at startup`
12. `feat(theme): preserve appearance across auth navigation`
13. `test(auth): verify responsive login and recovery flows`
14. `docs(frontend): record setup validation and integration boundaries`

Future commits should come from independently useful, reviewable increments. For future
work, profile setup, session-expiry UX, accessibility improvements, and a protected
home shell each provide substantial contributions with their own tests. Follow
the team's merge strategy if preserving individual commits matters; squashing
combines them in the target branch's history.
