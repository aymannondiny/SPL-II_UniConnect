# Account moderation administration

These endpoints require a valid session belonging to an ACTIVE, non-anonymized
SYSTEM_ADMIN with SYSTEM_ADMINISTRATION selected. Responses use
`Cache-Control: no-store`.

| Method | Path | Result |
| --- | --- | --- |
| GET | `/api/v1/admin/accounts?search=&role=&status=&page=0&size=20` | Filtered account page |
| GET | `/api/v1/admin/accounts/{id}` | Account administration details |
| POST | `/api/v1/admin/accounts/{id}/suspend` | ACTIVE member to SUSPENDED |
| POST | `/api/v1/admin/accounts/{id}/restore` | SUSPENDED member to ACTIVE |
| GET | `/api/v1/admin/accounts/{id}/audit?page=0&size=20` | Retained moderation history |

Both transition requests require a nonblank reason of at most 1000 characters
and explicit confirmation:

```json
{"reason":"Reviewed under the account policy","confirm":true}
```

Only non-anonymized STUDENT and ALUMNI accounts are eligible. SYSTEM_ADMIN
accounts, including the caller, are excluded. An authorized request for the
already-desired state is a validated no-op with no additional audit or
notification. Other state transitions return the canonical 409
`INVALID_ACCOUNT_STATE` error.

Suspension changes the account state, revokes every session, suspends each ACTIVE
club currently administered by the account, records immutable audit history, and
queues generic notifications in one transaction. The full reason is returned only
by the system-administration audit endpoint. Club assignments, publications, and
history remain intact. An already-suspended club gets no duplicate transition.

After commit, authenticated chat sockets for the account are closed with policy
code 1008. The five-second session-validation sweep remains a fallback. Every
subsequent HTTP and socket authorization check independently rejects the revoked
session; socket closure is not the security boundary. A transaction rollback
delivers no closure event.

Restoration never revives old access or refresh credentials and never restores
club publishing. Reactivating the original administrator can make that
administrator eligible again, but an authorized system administrator must still
explicitly call `/api/v1/admin/clubs/{id}/publishing/restore`.
Suspension has no automatic expiry or scheduled reactivation; an authorized
system administrator must explicitly call the restoration endpoint.

## Concurrency and transaction boundary

Each suspension attempt discovers candidate club IDs, locks those clubs in
ascending order, locks the actor and target accounts in ascending order, and then
runs a fresh scalar assignment query. This preserves the global club-before-account-
before-session ordering. If the fresh query finds a club that was not locked, the
entire attempt rolls back and retries in a new transaction, up to three attempts.

At READ_COMMITTED, an assignment writer that wins the target-account lock commits
before the fresh query and is detected; a writer that loses the lock resumes after
suspension and fails the ACTIVE-account eligibility check. The fresh scalar query
does not reuse managed assignment entities from the persistence context. Existing
candidate assignments are also checked again while their club and account locks are
held, so replacement away from the target is not incorrectly suspended.

The automated ordering tests use H2 in PostgreSQL compatibility mode. They verify
the application choreography, but do not prove PostgreSQL lock behavior; repeat
these cases against disposable PostgreSQL in integration infrastructure.

Flyway V14 creates `moderation_actions` and immutable `audit_logs`, links reversal
actions, and extends the existing notification type/reference checks. V1-V13 are
unchanged. The upgrade test migrates a populated V13 schema and verifies that users,
sessions, and notifications are retained.

Complete FR_66 account anonymization, warnings, and Flutter administration
screens are deferred. Existing Project and Career privacy hooks remain intact as
future anonymization integration surfaces. Existing suspension audit records may
be linked by the separate [content-report review workflow](CONTENT_REPORTING.md);
resolving a report never calls this moderation operation. PROJECT and CAREER_POST
reports accept only an unreversed suspension of their captured creator/author;
subject, time, action type, and reversal state are verified under the existing
evidence lock.

## Manual Swagger check

1. Sign in as an ACTIVE SYSTEM_ADMIN, authorize Swagger with its access token, and
   PUT `/api/v1/auth/contexts/active` with
   `{"contextType":"SYSTEM_ADMINISTRATION","assignmentId":null}`.
2. Search `/api/v1/admin/accounts`, open an ACTIVE STUDENT or ALUMNI, and retain a
   separate live token/socket for that member.
3. POST `/{id}/suspend` with confirmation and a reason. Verify the response is
   SUSPENDED, the old REST token returns 401, refresh returns 401, and the socket
   closes. For an administered ACTIVE club, verify PUBLISHING_SUSPENDED while its
   assignment and published content remain.
4. Repeat suspension and verify the audit and notification counts do not change.
   Read `/{id}/audit` as the system admin to see the full reason; the member's
   notification text must be generic.
5. POST `/{id}/restore`. Verify old tokens still return 401 and a fresh login works.
   The club must remain PUBLISHING_SUSPENDED until the system admin explicitly calls
   `/api/v1/admin/clubs/{clubId}/publishing/restore`.
6. Confirm a SYSTEM_ADMIN target, a pending target, a false confirmation, a blank
   reason, or PERSONAL context produces the documented canonical error response.
