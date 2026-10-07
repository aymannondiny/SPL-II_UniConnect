# Forgot password and password reset

Implements FR_4 and the PasswordResetToken model from the approved authentication design.

## API

| Method and path | Request | Success |
|---|---|---|
| POST `/api/v1/auth/forgot-password` | `{"email":"member@iut-dhaka.edu"}` | 202, empty |
| POST `/api/v1/auth/reset-password` | `{"token":"<reset token>","newPassword":"new password"}` | 204, empty |

Both routes are public. Clear Swagger's Authorize value before calling them: an explicitly supplied invalid bearer token is rejected even on public endpoints.

Forgot-password returns the same empty response for existing, unknown, anonymized, or credential-less accounts and for SMTP delivery failure. Clients should say: “If this account is eligible, a reset link will be sent.” This response does not confirm delivery. Synchronous SMTP means response timing is not equalized; deploy request throttling before public exposure.

Non-anonymized accounts with an email and password hash can reset, including PENDING_VERIFICATION and SUSPENDED accounts. Reset preserves status, email-verification state, and role. It cannot activate or unsuspend an account. Only eligible ACTIVE accounts can subsequently log in.

Passwords follow the existing 8–72 character rule and are additionally limited to 72 UTF-8 bytes for BCrypt. Passwords are neither trimmed nor normalized. Successful reset does not automatically log in.

## Token lifecycle and transactions

Links expire after one hour (an implementation choice within FR_4's time-limited requirement), exactly at the expiry instant. Tokens contain 32 cryptographically random bytes, encoded as URL-safe Base64; only SHA-256 hashes are stored. Reset tokens are separate from email verification and session tokens.

A new request revokes previous unused reset links. Requesting a reset never changes the password or revokes sessions. On successful redemption, one transaction changes the BCrypt password hash, marks the token used, revokes other outstanding reset tokens, and revokes every authenticated session. Old access and refresh tokens then fail. The user must log in with the new password.

Flyway V5 owns `password_reset_tokens`; previous migrations are untouched. Controllers call PasswordResetService, which owns business rules and transactions and uses repositories. The shared opaque-token generator is renamed from SessionTokenGenerator to AuthenticationTokenGenerator without changing session token behavior.

Issuance, redemption, login, refresh, and revocation serialize on the owning user row. Redemption resolves a scalar owner ID before acquiring that lock and loads token state afterwards. Concurrent redemption has one winner. A concurrent refresh cannot leave a usable replacement after reset commits. Requests already authorized before revocation may finish, as documented for sessions.

SMTP sending occurs within the issuance transaction, consistent with email verification. Delivery failure rolls back token creation and old-link revocation; the controller still returns generic 202 and logs only a sanitized warning. Email and database commits are not atomic: an SMTP acceptance followed by a database failure can produce an unusable link. Durable delivery/retry via an outbox and automatic expired-token cleanup remain separate work.

## Errors

All errors use ApiError:

- 400 `VALIDATION_FAILED`: missing fields, invalid email, token too long, or password outside the character limits.
- 400 `MALFORMED_REQUEST`: invalid JSON.
- 400 `INVALID_PASSWORD`: service validation, including passwords exceeding 72 UTF-8 bytes.
- 400 `INVALID_PASSWORD_RESET_TOKEN`: malformed, unknown, expired, used, revoked, or no-longer-eligible token.

No error returns the submitted token or password. PasswordResetDeliveryException is caught after rollback at the request endpoint; its internal delivery code is not exposed there.

## Email and frontend configuration

Reuse the existing `MAIL_*` SMTP settings. `PASSWORD_RESET_FROM` defaults to `VERIFICATION_FROM`, so an existing authenticated sender configuration works without a second mailbox. `PASSWORD_RESET_URL` defaults to `http://localhost:3000/reset-password` and must be an absolute HTTP(S) frontend URL with no fragment or credentials. Use HTTPS outside local development.

The email link is `<PASSWORD_RESET_URL>#token=<raw token>`. The frontend confirmation page is not included in this backend phase. Clicking the default link will not work until a frontend is running at that address. A future page must read the fragment, remove it from browser history, collect a new password, and POST both values to the reset endpoint. Do not reset on a GET request or merely on opening the email link. Keep passwords and tokens out of logs, analytics, and source control.

## Manual Swagger check

1. Start with the existing DB and SMTP environment; Flyway applies V5 on startup.
2. Log in to a verified test account and keep its access and refresh tokens locally for the revocation check. Clear Swagger authorization.
3. Call forgot-password with that account's email: expect 202 and a real email.
4. Copy only the value after `#token=` from the email into reset-password, with a new password: expect 204. No frontend page is needed for this manual check.
5. Repeat the same reset token: expect 400. Old-password login must return 401; new-password login must return 200.
6. Authorize with the saved old access token and call `me`: expect 401. Clear authorization and refresh with the saved old refresh token: expect 401.
7. Request two links in succession: the first must fail with 400; the second must work.

Run `./mvnw clean verify` for regression, HTTP contract, token expiry/replacement, SMTP failure rollback, status preservation, atomic rollback, and concurrency tests. Tests use isolated H2 in PostgreSQL mode, not Neon or real SMTP. Verify V5 and real delivery in the development environment before merging.
