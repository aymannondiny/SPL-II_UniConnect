# Login and authenticated sessions

Implements FR_3 and the AuthenticatedSession lifecycle. Registration and verification remain unchanged.

## API

| Method and path | Request | Success |
|---|---|---|
| POST `/api/v1/auth/login` | `{"email":"member@iut-dhaka.edu","password":"your password"}` | 200 session response |
| POST `/api/v1/auth/refresh` | `{"refreshToken":"<current refresh token>"}` | 200 replacement session response |
| GET `/api/v1/auth/me` | `Authorization: Bearer <access token>` | 200 current account |
| POST `/api/v1/auth/logout` | `Authorization: Bearer <access token>` | 204 empty |

Login and refresh are public POST routes. Do not attach an expired access token to either request. An explicitly supplied invalid Authorization header is rejected, including on public endpoints.

The session response contains `sessionId` (UUID), `tokenType` (`Bearer`), `accessToken`, `refreshToken`, `accessExpiresAt`, and `expiresAt`. Times are ISO-8601 UTC instants. Access lasts 15 minutes. The session lasts seven days from login; refresh never extends this absolute deadline. Refresh rotates **both** credentials and immediately invalidates the old access token. Only one concurrent use of a refresh token can succeed. Previous refresh tokens receive 401 without revoking the winning replacement. There is no replay grace period or token-family reuse detection in this phase.

`me` returns `userId`, `fullName`, `email`, `platformRole`, and `accountStatus`; no hashes or JPA entities. Token and current-user responses use `Cache-Control: no-store`.

## Errors

All errors use the existing ApiError shape.

- 401 `INVALID_CREDENTIALS`: unknown email, wrong password, pending, suspended, or anonymized account. The message does not disclose which condition occurred. Missing accounts still incur a password-hash comparison; this does not promise perfectly equal timing.
- 401 `INVALID_SESSION`: an unusable refresh token, or session failure inside a controller service.
- 401 `AUTHENTICATION_REQUIRED`: missing, malformed, expired, or revoked access credentials at the security boundary.
- 403 `ACCESS_DENIED`: authenticated account lacks required authority.
- 400 `VALIDATION_FAILED` / `MALFORMED_REQUEST`: existing validation/JSON contract.

## Persistence and architecture

Flyway V4 owns `authenticated_sessions`. Each row holds a UUID, canonical User FK, unique SHA-256 access/refresh hashes, issue/access/session expiry timestamps, last-seen timestamp, and optional revocation timestamp/reason. Credentials contain 32 cryptographically random bytes encoded as URL-safe Base64. Raw tokens exist only in the response and client storage. `lastSeenAt` records issuance/refresh, not every API request.

The class diagram's refresh-token hash is retained; access-token hash and access expiry extend that model for opaque bearer access. This design uses database-backed tokens rather than JWTs because every protected request must already check current session and account state. No signing-key setup is required.

Controllers call SessionService; it owns transactions and repositories. The security filter also calls this service, never a repository. Every bearer request loads the session and current User, verifies both expiries/revocation/ACTIVE/non-anonymized status, and derives authority from the current PlatformRole. HTTP authentication is stateless: no login cookie, Basic authentication, form login, or servlet session is used. CSRF remains disabled for this header-only credential transport; introducing cookies requires a separate CSRF design. Use HTTPS outside local development.

Login, refresh, logout and bulk revocation serialize on the owning user row. Refresh locates the scalar owner first and loads mutable session state after locking, preventing concurrent replay. Account administration must lock the same user and call `SessionService.revokeAllForAccount` in the same transaction as suspension/anonymization. That method requires an existing transaction. Reactivation must never clear revocation. This phase supplies and tests the integration contract; moderation endpoints are not implemented. Direct SQL changes to account status alone do not revoke sessions permanently.

A request already authorized before a concurrent revocation may finish; subsequent authentication checks reject revoked access. Features needing stronger guarantees must recheck authorization inside their protected write transaction.

## Client integration and manual check

1. Register and verify an account using the existing workflow.
2. Call login in Swagger; copy its **accessToken** into Authorize (`sessionBearer`).
3. Call `me`: expect 200 and the ACTIVE account.
4. Call refresh with the refresh token, without the old Authorization header. Replace both stored tokens together, then update Swagger Authorize.
5. Call logout: expect 204. `me` with that access token and refresh with that refresh token must now return 401.

Clients must serialize refresh calls. A lost refresh response requires logging in again. Logout revokes the current session only; other device sessions remain valid. If access already expired, refresh before logout, or discard local credentials (which by itself does not revoke the server session).

Keep tokens out of logs, URLs, analytics, issue reports, and source control. Native clients should use OS-protected credential storage. The web frontend should keep tokens in memory for this initial flow, accepting re-login on reload; persistent web login needs a separately reviewed storage/CSRF design. Do not silently put refresh tokens in localStorage.

## Scope and deployment

Password reset, context selection, frontend screens, all-device logout UI, rate limiting, session cleanup, and administration endpoints remain separate work. Deploy public login/refresh behind rate limiting before public exposure. Expired/revoked sessions remain for now; no automatic cleanup job is added. Tests use H2 in PostgreSQL mode; validate V4 and locking against PostgreSQL in the integration environment as well.
