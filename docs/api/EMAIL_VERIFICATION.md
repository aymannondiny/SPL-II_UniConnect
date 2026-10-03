# Email verification

Implements FR_2 and FR_73. Authentication owns the token and activation lifecycle.

## API

| Endpoint | Request JSON | Success |
|---|---|---|
| `POST /api/v1/auth/register` | Existing registration contract | `201`, existing user DTO with `PENDING_VERIFICATION` |
| `POST /api/v1/auth/verify-email` | `{"token":"<token from email>"}` | `204`, empty body |
| `POST /api/v1/auth/resend-verification` | `{"email":"member@iut-dhaka.edu"}` | `202`, empty body |

All three endpoints are public POST operations. Verification does not create a session. Login remains a separate phase.

Registration sends a verification email. Tokens contain 32 cryptographically random bytes encoded as URL-safe Base64 without padding. Only a SHA-256 hash is persisted. Each token expires exactly 24 hours after issuance, using UTC timestamps. Invalid, expired, consumed, and revoked tokens receive `400 INVALID_VERIFICATION_TOKEN` through the existing `ApiError` contract. DTO validation and malformed JSON retain the existing error contract.

Verification only transitions a non-anonymized `PENDING_VERIFICATION` account to `ACTIVE`. Used tokens cannot activate another account or reactivate a suspended account. Resend normalizes email casing and replaces outstanding links only for eligible pending accounts. It also supports pending accounts created before this migration.

Resend returns the same empty `202` for unknown, active, suspended, and anonymized accounts. It also returns `202` when SMTP delivery fails: this acknowledges the request, not delivery. A sanitized server warning records delivery failure; the transaction rolls back and the old link remains valid. No email address or token is included in that warning. Synchronous delivery can still create timing differences; deployment-level rate limiting and abuse monitoring should cover these public endpoints.

## Persistence and concurrency

Flyway `V3__create_email_verification_tokens.sql` adds the token table, owner foreign key, unique hash, and owner index. Existing migrations are unchanged and Hibernate continues to validate the schema.

The service owns transactions. Verification and resend acquire a pessimistic write lock on the owning user before reading or replacing token state. Concurrent consumers therefore cannot both succeed. Account activation and token consumption commit together.

SMTP delivery is synchronous within the transaction for this initial implementation. A delivery failure during registration returns `503 VERIFICATION_EMAIL_UNAVAILABLE` and rolls back both user and token. A resend failure rolls back token replacement. SMTP and database commits are not atomic: an SMTP timeout or later database commit failure may leave a delivered but unusable link. Users can retry registration or request a replacement. A durable outbox/retry worker is not implemented in this phase.

## SMTP setup

| Variable | Local default | Purpose |
|---|---|---|
| `MAIL_HOST` | `localhost` | SMTP server |
| `MAIL_PORT` | `1025` | SMTP port |
| `MAIL_USERNAME` | empty | SMTP username |
| `MAIL_PASSWORD` | empty | SMTP password; keep out of Git |
| `MAIL_SMTP_AUTH` | `false` | Enable SMTP authentication |
| `MAIL_STARTTLS` | `false` | Enable and require STARTTLS |
| `VERIFICATION_FROM` | `no-reply@uniconnect.local` | Sender address approved by the provider |
| `VERIFICATION_URL` | `http://localhost:3000/verify-email` | Frontend confirmation page URL |

Use an SMTP capture server such as Mailpit at localhost:1025 for development. Production requires the actual provider settings, authenticated TLS, an approved sender, and an HTTPS frontend URL. Connection/read/write timeouts are five seconds. Do not enable mail debug or HTTP request-body logging containing tokens.

The email link is `VERIFICATION_URL#token=<opaque token>`. The fragment keeps the token out of HTTP URL/access logs. The frontend must read the fragment, remove it from browser history, and POST the token only after the user confirms. Loading the email link does not activate the account; this avoids email scanners consuming links. The Flutter verification page is not included in this backend phase. Until it exists, copy the token from the captured email into Swagger's verification request. Do not paste real tokens into shared logs or issue comments.

## Validation

Run `cd code/backend && ./mvnw clean verify` with Java 21. Integration tests use Flyway and H2 in PostgreSQL mode, a mocked email sender, and a controlled clock. They cover hash-only persistence, activation, exact expiry, replay, replacement, account eligibility, error contracts, delivery rollback, non-disclosing resend, and concurrent consumption. SMTP adapter tests check link construction and sanitized failures. A live SMTP provider and Neon are not used by these tests.
