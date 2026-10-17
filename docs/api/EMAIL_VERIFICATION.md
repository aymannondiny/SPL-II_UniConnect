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

The email link is `VERIFICATION_URL#token=<opaque token>`. The fragment keeps the token out of HTTP URL/access logs. The Flutter frontend captures the fragment in memory, replaces the address with `/verify-email`, and automatically POSTs the token when the page opens. It displays success only after `204`. This implements the requested click-to-verify experience; an email scanner that executes the Flutter app may also consume a link. A confirmation button can be restored if scanner resistance becomes a requirement. Do not paste real tokens into shared logs or issue comments.

## Flutter integration

Run Flutter web at a fixed origin:

```bash
flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8080
```

Set `REST_ALLOWED_ORIGINS=http://localhost:3000` and `VERIFICATION_URL=http://localhost:3000/verify-email` on the backend. The existing REST CORS configuration allows only configured exact origins; the dev profile defaults to local frontend origins, while other profiles require explicit configuration. For hosted builds, use the public HTTPS frontend URL and configure the web host to serve `index.html` for `/verify-email` and other Flutter routes. Flutter uses path routing so the SMTP token fragment does not conflict with hash routing. API_BASE_URL is a build-time setting.

The verification page shares signup's responsive shell, campus images and theme toggle. It handles missing, invalid, used, expired and replaced links, supports retry after transport/server failures, and offers an IUT-email replacement form. Replacement acknowledgments do not claim successful delivery or reveal whether an account exists. Refreshing the cleaned URL has no token and shows recovery; it never claims verification from local state.

The **Click to log in** button currently opens the same explicit coming-next dialog used by signup. The login frontend is a separate feature and has not been implemented. Verification creates no session and stores no authentication credentials.

The repository `.env.example` includes the SMTP settings. Spring does not load that file automatically; export the variables in the backend process before starting it. Local defaults require an SMTP capture server on port 1025. Delivery to actual IUT inboxes requires provider credentials, an approved sender, TLS and a reachable frontend URL. Localhost links work only on the machine serving the app; use a reachable development or hosted URL for other devices.

## Validation

Frontend checks:

```bash
cd code/frontend
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release --dart-define=API_BASE_URL=http://localhost:8080
```

Frontend tests use fake repositories or HTTP clients. They cover link parsing, API contracts, safe failures, loading versus confirmed success, replacement requests, retry, disposal and responsive layouts at 1440×900, 390×844 and 320×640, including theme switching. Backend CORS tests cover allowed and rejected preflight origins.

A local integration check on 2026-10-16 ran the release web app against the real Spring services, an isolated H2 database and a local SMTP capture server. Registration returned `201`, the SMTP adapter delivered a message containing the frontend link, opening that link displayed verified success, backend login then returned `200`, and token replay returned `400 INVALID_VERIFICATION_TOKEN`. Browser checks covered desktop and mobile success, both themes, narrow-screen recovery and the login notice. This check did not test external SMTP authentication, TLS, provider acceptance, delivery to a real IUT inbox, or production PostgreSQL.

Run `cd code/backend && ./mvnw clean verify` with Java 21. Integration tests use Flyway and H2 in PostgreSQL mode, a mocked email sender, and a controlled clock. They cover hash-only persistence, activation, exact expiry, replay, replacement, account eligibility, error contracts, delivery rollback, non-disclosing resend, and concurrent consumption. SMTP adapter tests check link construction and sanitized failures. A live SMTP provider and Neon are not used by these tests.
