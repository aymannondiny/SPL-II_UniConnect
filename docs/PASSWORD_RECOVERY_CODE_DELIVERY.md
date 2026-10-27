# Password recovery code delivery

## Three-page follow-up

The current UI has separate email, six-box verification and new-password pages.
Sending the code navigates automatically. Page two calls the public
`verify-password-reset-code` endpoint; only success opens page three. The code is
kept in memory, never in the URL. Refreshing the final page restarts recovery.
Final reset rechecks the code; verification neither consumes nor extends it.
Wrong verification attempts share the existing five-attempt limit.

Follow-up checks: 30 backend recovery/security tests and 27 frontend
contract/behavior/routing/visual tests pass. Flutter analysis has no issues.
Backend packaging and the production web build pass. The HTTP/SMTP smoke test
also passes the intermediate code-verification endpoint. The running browser
automatically advances from email entry to the six-box page at
`/verify-password-reset`. Desktop and mobile screenshots cover all three pages.
The full-suite totals recorded below are the preceding code-flow baseline.

## Behavior

The canonical shared Flutter client and backend now use six-digit email codes
for both sign-up verification and password recovery. Forgot password requests
a code. Reset password submits the email, code and new password together.
There is no link click or automatic credential change. Leading zeroes survive
transport and input. Password confirmation and existing password limits remain.

Recovery follows sign-up's ten-minute challenge lifetime, five failed attempts,
60-second resend spacing and five issuances per rolling hour. It retains
non-disclosing responses, SMTP rollback, account-state preservation, single-use
redemption and atomic all-session revocation. User row locks serialize concurrent
reset, issuance and refresh. Password and session storage remain unchanged.

V28 revokes outstanding legacy reset links and adds salt, attempt count,
constraints and an issuance index. Historical migrations are untouched. Old
links must be replaced by a new code request. Deploy both application layers
together because the reset JSON contract has intentionally changed.

## Structure

Domain records own challenge expiry and attempt state. The service owns recovery
transactions and issuance rules; the repository owns queries; the sender owns
email delivery; the DTO owns request validation. The existing cryptographic
code generator is reused. Recovery and sign-up use separate challenge tables.

Flutter retains the existing repository/controller/page/widget boundaries and
shared responsive shell. Obsolete reset-link parsing and browser-history helpers
are removed. New test files separate security, migration and visual verification.
Each new implementation file has one purpose. No filler code or redundant
abstractions are introduced to increase line counts.

## Verification and fixtures

- Recovery integration/security/SMTP/migration tests: 21 passing checks.
- Clean backend `verify`: 362 tests discovered, 358 passed, four pre-existing
  opt-in PostgreSQL checks skipped, no failures or errors; executable JAR built.
- Frontend regression suite: 406 passing tests.
- Flutter static analysis: no issues.
- Dart formatting: all 14 changed Dart files pass without changes.
- Production web release build: passes, including the Wasm compatibility dry run.
- Live HTTP/SMTP smoke: passes registration, sign-up verification, code delivery,
  wrong-code retry, reset, replay rejection, old-password rejection and access/
  refresh session revocation. Emails contain codes and no URLs.
- Live browser request: real frontend/backend/CORS acceptance confirmed for a
  synthetic unknown email, followed by code entry with the email preserved.
- Responsive behavior: 1440×900, 390×844 and 320×640 in both themes.
- Visual renders: request and reset forms at 1440×1000 and 390×1100 in both themes,
  saved under `code/frontend/build/recovery-review`.

Production frontend repositories make real HTTP calls. Widget behavior tests
inject repositories. Backend integration tests use isolated H2 and mocked mail
delivery/clock to exercise expiry, rollback and concurrency deterministically.
The local HTTP smoke runner uses real controllers, services, persistence and
SMTP serialization with synthetic accounts, H2 and a local in-memory mail sink.
No university emails are sent. The archived `mobile` package is not the active
client and is intentionally unchanged.

External SMTP delivery, deployed PostgreSQL behavior and a physical Android
device remain separate environment checks. The pre-existing opt-in PostgreSQL
tests require explicitly supplied isolated database properties.

The running preview uses `http://127.0.0.1:3014/forgot-password` and the isolated
backend on port 8087. SMTP goes only to the local fixture on port 1026; it will
not deliver messages to a real inbox. All runtime fixture data disappears when
the backend stops. There is no local API-contract or CORS integration blocker.

## Runtime commands

From `code/backend`, using Java 21 and an installed Python runtime:

```powershell
.\mvnw.cmd spring-boot:run '-Dspring-boot.run.profiles=test' '-Dspring-boot.run.useTestClasspath=true' '-Dspring-boot.run.arguments=--server.address=127.0.0.1 --server.port=8087 --spring.mail.host=127.0.0.1 --spring.mail.port=1026 --uniconnect.cors.allowed-origins=http://127.0.0.1:3014'
python tool/password_recovery_smoke.py --keep-serving
```

Run the smoke script in a second terminal after the backend is ready. It prints
only a pass summary, never codes, passwords or session credentials. Stop these
processes when the isolated preview is no longer needed. Data is in memory.

From `code/frontend`:

```powershell
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=3014 --dart-define=API_BASE_URL=http://127.0.0.1:8087
```

## Commit organization

After user authorization, related changes are grouped into nine focused commits.
Existing tests travel with the implementation they validate so commits remain buildable.

1. `feat(auth): migrate password recovery challenge storage` — V28 and upgrade regression test.
2. `feat(auth): redeem six-digit password recovery codes` — DTO, controller, service,
   entity/repository, SMTP sender, configuration and adapted backend regression tests.
3. `test(auth): cover recovery rate and attempt limits` — dedicated security scenarios.
4. `feat(auth-ui): add three-step password recovery` — frontend contract,
   controller, screens, navigation cleanup, code navigation/retry and adapted existing tests.
5. `test(auth-ui): add responsive recovery renders` — dedicated visual QA test.
6. `test(auth): add local SMTP smoke fixture` — SMTP test sink.
7. `test(auth): exercise recovery through HTTP and SMTP` — smoke runner depending on the sink.
8. `docs(auth): document recovery code API and rollout` — API and handoff updates.
9. `docs(auth): record recovery verification and runtime setup` — this delivery report and frontend guide.

Meaningful implementations, regression tests, reproducible tools and documentation
provide useful contribution volume. Avoid empty commits, repeated formatting
changes, artificial file splits or padding; they make review and maintenance harder.
