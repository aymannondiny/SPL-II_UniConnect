# Password recovery with six-digit codes

Sign-up verification and password recovery both send six-digit email codes.
They use separate challenges and endpoints: verifying a sign-up code cannot
reset a password, and resetting a password cannot activate an account.

## Public API

| Endpoint | JSON request | Success |
| --- | --- | --- |
| `POST /api/v1/auth/forgot-password` | `{"email":"member@iut-dhaka.edu"}` | 202, empty |
| `POST /api/v1/auth/verify-password-reset-code` | `{"email":"member@iut-dhaka.edu","code":"012345"}` | 204, empty |
| `POST /api/v1/auth/reset-password` | `{"email":"member@iut-dhaka.edu","code":"012345","newPassword":"new password"}` | 204, empty |

Codes are strings, preserving leading zeroes. The reset DTO requires a valid
email, exactly six ASCII digits, and an 8–72 character password. The password
policy additionally enforces the BCrypt maximum of 72 UTF-8 bytes. Passwords
are not trimmed or normalized; email addresses are trimmed and lowercased.

All three endpoints are public. Do not supply an invalid bearer token: explicitly
invalid credentials are rejected even on public endpoints.

## Issuance and limits

Forgot-password always returns generic 202 for unknown/ineligible accounts,
SMTP failure, cooldown suppression and hourly limit suppression. A 202 does
not confirm account existence, code issuance, or email delivery. The UI says
“If this account is eligible, a six-digit code will be sent.”

- Codes expire after ten minutes, including rejection at the exact expiry time.
- At most one code can be issued per account every 60 seconds.
- At most five codes can be issued per account in a rolling hour.
- Replacement codes differ from the previous code and revoke outstanding codes.
- Suppressed requests leave the current code usable.
- Five incorrect well-formed attempts revoke the current challenge.
- Wrong attempts persist even though the API returns a generic 400.
- Correct codes remain usable after fewer than five failed attempts.

The existing cryptographically secure verification-code generator supplies
codes and random per-challenge salts. Only salted, account-bound SHA-256
digests are persisted. Raw codes, passwords and authenticated session tokens
must never enter logs or analytics.

Account-scoped limits do not replace gateway/IP limits for public deployments.
SMTP is synchronous; response timing is not equalized.

## Preserved account and session behavior

Non-anonymized accounts with an email and password hash can recover, including
pending and suspended accounts. Recovery preserves role, verification and
account status. It cannot activate or unsuspend an account.

Requesting a code never changes the password or revokes authenticated sessions.
A successful reset changes the password, consumes the code, revokes outstanding
reset challenges and revokes every authenticated session in one transaction.
Old access and refresh tokens then fail. No session is created automatically;
the user logs in with the new password. Requests authorized before revocation
may finish, consistent with the existing session contract.

Issuance, redemption and session operations lock the owning user row. Concurrent
redemption has one winner; concurrent refresh cannot leave a usable replacement
session after reset commits. SMTP delivery failure rolls back issuance and
replacement revocation, preserving the previous usable code.

## Errors

- 400 `VALIDATION_FAILED`: malformed email/code or invalid password length.
- 400 `MALFORMED_REQUEST`: invalid JSON.
- 400 `INVALID_PASSWORD`: password policy failure, including excessive UTF-8 bytes.
- 400 `INVALID_PASSWORD_RESET_CODE`: unknown email, wrong, expired, used, revoked,
  exhausted or legacy challenge, or ineligible account.

Error responses never echo codes or passwords. Reset DTO string output is redacted.

## Migration and SMTP

Flyway V28 adds challenge salt, failed-attempt count, a count constraint and an
issuance index to the existing password-reset table. It revokes outstanding
legacy links without changing account/password/session data. Historical Flyway
migrations remain unchanged. Users with old links must request a fresh code.

The existing `MAIL_*` settings and `PASSWORD_RESET_FROM` are reused. The sender
defaults to `VERIFICATION_FROM`. `PASSWORD_RESET_URL` is no longer used: reset
emails contain a code and expiry instructions, never a URL. Deploy backend and
frontend together because the reset request changed from `token/newPassword`
to `email/code/newPassword`.

Email/database commits are not atomic: SMTP acceptance followed by a failed
database commit can still produce an unusable code. Durable outbox delivery and
expired-challenge cleanup remain separate work.

## Frontend

The canonical shared web/Android client is `code/frontend`; `mobile` is archived.
Recovery has three separate pages. Enter an email and select Send verification
code to automatically open `/verify-password-reset`. It displays six digit boxes,
the normalized email, expiry instructions and resend controls. Only a successful
backend code check opens `/reset-password`, which contains password and
confirmation fields. Verification does not consume the code, change the password,
revoke sessions or extend expiry. Reset revalidates and atomically consumes it.
Both endpoints share the same failed-attempt counter. Codes remain only in route
memory and never enter URLs or persistent storage. Reloading the password page
restarts recovery. Errors permit retry; success prompts a fresh login.

## Verification

Run `./mvnw clean verify` from `code/backend`, and `flutter analyze`,
`flutter test`, and `flutter build web --release --no-web-resources-cdn` from
`code/frontend`. Recovery tests cover expiry, cooldown, hourly limits, persisted
attempt exhaustion, replacement, rollback, account states, API validation,
concurrent reset/refresh, password changes and session revocation. Migration
tests exercise an upgrade from V27 with an outstanding legacy link.

For a real HTTP and local SMTP smoke test, start the backend with the test
profile, test classpath, port 8087 and SMTP `127.0.0.1:1026`. Then run
`python tool/password_recovery_smoke.py` from `code/backend`. The script uses
synthetic accounts and an in-memory SMTP sink; it sends no external email and
does not print secrets. Use an isolated local database only. `--keep-serving`
leaves the local SMTP fixture available for frontend request previews.
