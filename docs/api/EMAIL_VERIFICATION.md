# Email verification codes

Implements FR_2 and FR_73. Authentication owns the challenge and account-activation lifecycle.

## API contract

All endpoints are public POST operations. Registration and verification do not create a login session.

| Endpoint | Request JSON | Success |
|---|---|---|
| `POST /api/v1/auth/register` | Existing registration contract | `201`, existing account DTO with `PENDING_VERIFICATION` |
| `POST /api/v1/auth/verify-email` | `{"email":"student@iut-dhaka.edu","code":"012345"}` | `204`, empty body |
| `POST /api/v1/auth/resend-verification` | `{"email":"student@iut-dhaka.edu"}` | `202`, empty body |

The registration response remains:

```json
{
  "userId": 42,
  "fullName": "Student Member",
  "email": "student@iut-dhaka.edu",
  "platformRole": "STUDENT",
  "accountStatus": "PENDING_VERIFICATION"
}
```

It never includes the code, password, password hash, or session credentials. Email and code are strings. The verification code must match `[0-9]{6}`; leading zeros are significant.

Errors use the canonical `ApiError` body. Relevant codes are:

| HTTP | `code` | Meaning |
|---|---|---|
| `400` | `VALIDATION_FAILED` | A request field is absent or malformed. `fieldErrors` identifies it. |
| `400` | `MALFORMED_REQUEST` | JSON cannot be read. |
| `400` | `INVALID_VERIFICATION_CODE` | The email/code pair or account/challenge state is unusable. |
| `503` | `VERIFICATION_EMAIL_UNAVAILABLE` | Initial registration delivery failed and registration was rolled back. |

`INVALID_VERIFICATION_CODE` deliberately covers wrong email, wrong code, expiry, five-attempt exhaustion, revocation, prior use, and an ineligible account without exposing which condition applied. Resend returns the same empty `202` for every validly formed request: successful issuance, unknown account, ACTIVE/SUSPENDED/anonymized account, cooldown suppression, rolling-limit suppression, and sanitized SMTP failure. It does not confirm account state, code issuance, or delivery, and no suppression-specific body or header is returned. Identical responses do not guarantee identical processing time; deployment-level timing protections remain separate work.

## Challenge and abuse controls

Codes are uniformly sampled from the one-million-value six-digit space with `SecureRandom`. Each challenge has a separate 256-bit random salt. The persisted SHA-256 digest is bound to the salt, account ID, normalized email, and code; plaintext codes are never persisted or returned. Digest checks use a constant-time byte comparison. Request DTO string output redacts the code.

Each challenge expires 10 minutes after issuance. The expiry boundary itself is expired. A challenge is single-use and accepts at most five incorrect, well-formed codes. The fifth incorrect attempt revokes it. Verification transactions explicitly commit expected invalid-code failures so incremented attempt counts are durable; account row locking serializes attempts and prevents lost increments.

Resend has two persistent account-scoped controls: 60 seconds between successful issuances and at most five successful issuances in a rolling hour, including initial registration. These controls use challenge history in the database, not process memory or frontend timers. Suppressed requests are internal no-ops that still return the generic `202`. These controls do not replace broader IP-, network-, device-, or global abuse controls, which remain separate work.

A successful resend revokes every outstanding challenge and creates a replacement. Generation checks the immediately previous salted digest and retries if the same numeric code was drawn, so the preceding email cannot accidentally become valid again. SMTP is synchronous inside the transaction: delivery failure rolls back the new challenge and revocations, preserving the previous usable challenge and issuance allowance. A database transaction cannot guarantee inbox delivery. A message can be accepted by SMTP and still be delayed, rejected later, or become unusable if the database commit subsequently fails.

## Persistence and concurrency

Flyway `V27__replace_email_verification_links_with_codes.java` is a forward-only migration. It retains the `email_verification_tokens` table and Java `EmailVerificationToken` entity names for compatibility with the already-applied V3 migration, but rows now represent code challenges. The legacy global digest uniqueness constraint is removed, `token_hash` is renamed `code_digest`, and `code_salt` plus constrained `failed_attempts` are added.

Every outstanding legacy link is revoked during migration. Account rows are not changed, so ACTIVE accounts remain ACTIVE and existing pending accounts recover by submitting their email to resend. No old link can satisfy the new request contract.

Verify, resend, and account moderation follow the existing owner-account pessimistic-write-lock convention. Verification locks by normalized email before reading its challenge and never searches by numeric code alone. Account activation and challenge consumption are atomic. Concurrent verify calls produce at most one success; concurrent wrong attempts retain every increment; concurrent resends serialize cooldown and issuance checks; and verify/resend observes one consistent account-locked order.

## SMTP setup

| Variable | Local default | Purpose |
|---|---|---|
| `MAIL_HOST` | `localhost` | SMTP server |
| `MAIL_PORT` | `1025` | SMTP port |
| `MAIL_USERNAME` | empty | SMTP username |
| `MAIL_PASSWORD` | empty | SMTP password; keep out of Git |
| `MAIL_SMTP_AUTH` | `false` | Enable SMTP authentication |
| `MAIL_STARTTLS` | `false` | Enable and require STARTTLS |
| `VERIFICATION_FROM` | `no-reply@uniconnect.local` | Provider-approved sender address |

The message displays the six-digit code and its 10-minute expiry in plain text. Email verification no longer uses or requires `VERIFICATION_URL`. Password recovery also uses six-digit codes; see [Password reset](PASSWORD_RESET.md). Use an SMTP capture server such as Mailpit for development and automated tests; never use real university recipients in tests.

## Deployment and Flutter handoff

This is an intentional breaking verification-contract change. Remove the old link-token parsing, fragment cleanup, and automatic link submission from Flutter. Password-reset links have also been replaced by code entry in the current recovery contract.

Deploy Flyway V27 and the backend before deploying a Flutter build that sends the new body, because the new frontend cannot verify against the old backend. The old Flutter verification screen likewise cannot verify against the new backend, so use an atomic/maintenance-window release where possible, or keep the interval between backend and Flutter deployments short. After the backend migration, previously emailed verification links are unusable; pending users recover through the resend-by-email flow and receive a code.

Run backend verification with Java 21:

```bash
cd code/backend
./mvnw clean verify
```

The default suite uses isolated H2 databases in PostgreSQL mode, an injected clock, and captured/mocked mail. The same verification integration suite can be pointed at a disposable PostgreSQL database with the `verification.integration.*` system properties. `PostgresEmailVerificationMigrationTests` is enabled only when `verification.postgres.url` is supplied; it exercises a V26 schema containing representative legacy verification data and then applies V27. Neither path accesses Neon or sends real email.
