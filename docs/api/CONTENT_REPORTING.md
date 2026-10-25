# Content reporting and moderation review

This bounded backend phase implements report submission, retained evidence, review,
resolution, notification, and audit history. The shared Flutter app now includes
report submission, personal history, and administrator review/resolution screens.
Warnings remain separate work. See the [frontend delivery notes](../FRONTEND_WORKFLOW_FIXES.md).

## Access and privacy

Any authenticated ACTIVE, non-anonymized account may submit, list, and read its own
reports. The selected dashboard context does not change submission authority.
Reporter reads are owner-only; another reporter receives the same 404 shape as a
missing report. Reporter responses never contain the immutable target snapshot,
review notes, action evidence, or audit history.

Administration routes require an ACTIVE SYSTEM_ADMIN with
`SYSTEM_ADMINISTRATION` selected. Administrative responses include the retained
snapshot, reviewer, internal notes, verified action link, and transition history.
All successful reporting responses use `Cache-Control: no-store`.

Supported targets are `USER`, `CLUB`, `ANNOUNCEMENT`, `EVENT`, `CHAT_MESSAGE`,
`PROJECT`, and `CAREER_POST`. A target must be accessible to the reporter at submission time:
users follow profile visibility, clubs follow club visibility, public publications
are reportable, and a current club administrator or the publication's current
author assignment may report its non-public publication. Chat messages require
conversation participation and current visibility. Project and Career own their
detail-access checks: accessible closed/expired content remains reportable, while
deleted, removed, missing, or otherwise inaccessible content returns the same 404.
Project reporting does not require Student eligibility, application eligibility,
membership, or management authority. Career reporting does not require save,
apply, edit, or management authority. A delete-for-self message is
not reportable by that participant. A delete-for-everyone tombstone remains
reportable when otherwise visible; its retained original text is administrator-only
evidence. Inaccessible and nonexistent targets both return 404.

## API

| Method | Path | Success |
| --- | --- | --- |
| POST | `/api/v1/reports` | 201 reporter-safe report |
| GET | `/api/v1/reports?page=0&size=20` | 200 current reporter's page |
| GET | `/api/v1/reports/{id}` | 200 current reporter's report |
| GET | `/api/v1/admin/reports?status=&targetType=&page=0&size=20` | 200 moderation queue |
| GET | `/api/v1/admin/reports/{id}` | 200 evidence and retained history |
| POST | `/api/v1/admin/reports/{id}/review` | 200 claimed report |
| POST | `/api/v1/admin/reports/{id}/resolve` | 200 terminal report |

Submit body:

```json
{"targetType":"ANNOUNCEMENT","targetId":42,"reason":"This content appears to violate the publication policy."}
```

Only one open report may exist for the same reporter, target type, and target ID.
A concurrent duplicate returns 409 `DUPLICATE_OPEN_REPORT`. Different reporters
retain separate reports, and the reporter may submit a later report after the
earlier report reaches a terminal state.

## Review and resolution

The lifecycle is `SUBMITTED -> UNDER_REVIEW -> ACTION_TAKEN | NO_ACTION`. The
first administrator to claim a submitted report becomes its reviewer. Only that
administrator may resolve it in this phase. Row locking serializes claim and
resolution attempts so concurrent requests cannot overwrite a decision.

Both terminal outcomes require a reporter-visible `resolutionSummary` of at most
1000 characters. `internalNotes` are optional, administrator-only, and at most
2000 characters.

NO_ACTION body:

```json
{
  "outcome":"NO_ACTION",
  "resolutionSummary":"We reviewed the report and no policy action was required.",
  "internalNotes":"Administrative rationale; never returned to the reporter.",
  "actionEvidence":null
}
```

ACTION_TAKEN does not execute an action. It links an action already committed
through its owning module:

```json
{
  "outcome":"ACTION_TAKEN",
  "resolutionSummary":"We reviewed the report and completed an appropriate action.",
  "internalNotes":"Verified against the retained moderation audit.",
  "actionEvidence":{"source":"ACCOUNT_MODERATION","id":17}
}
```

Evidence sources are `ACCOUNT_MODERATION`, `CLUB_LIFECYCLE`, and `PUBLICATION`.
The server verifies the retained audit record, action kind, timestamp, target and
captured author/club relationship. It rejects unrelated evidence, account
suspensions that were reactivated, and club publishing suspensions followed by a
restore. It never treats current target status alone as evidence.

Account suspension validation locks the referenced moderation action through the
report transaction; account restoration locks that same row after its established
ordered account locks. Club validation similarly locks the referenced suspension
audit, and publishing restoration locks that audit after its established club and
account locks. Therefore a reversal committed first invalidates resolution, while
a reversal that follows a committed resolution cannot erase its copied evidence.

The qualifying matrix is:

| Report target | Accepted committed evidence |
| --- | --- |
| USER | Suspension of that account |
| CLUB | Publishing suspension or removal of that club |
| ANNOUNCEMENT / EVENT | Removal of that publication, suspension of its captured author, or publishing suspension/removal of its captured parent club |
| CHAT_MESSAGE | Suspension of the captured sender |
| PROJECT | Suspension of the captured project creator |
| CAREER_POST | Suspension of the captured career-post author |

Publication removal continues to use existing club-operator permissions. This
phase adds no administrator publication-removal permission, chat hiding, warning,
or moderation-action endpoint.

An identical review or terminal-resolution retry is a no-op: it creates no second
audit, action link, or notification. A different terminal payload or outcome
returns 409 `REPORT_ALREADY_RESOLVED`. Invalid lifecycle/concurrency and evidence
conditions return their documented 409 ApiError codes. Validation returns 400,
invalid/inactive sessions 401, missing administration/reviewer authority 403, and
hidden/missing resources 404. Swagger documents each success and error status.

Resolution state, transition audit, optional action link, and exactly one generic
`REPORT_RESOLVED` notification commit in one transaction. A failure rolls all of
them back. The action link stores immutable action identity, subject, type, and
time, so later reversal does not erase historical evidence. Resolving a report by
itself never changes an account, club, publication, or message.

## Migration and automated verification

Flyway V17 creates `content_reports`, `report_audit_logs`, and
`report_action_links`, and extends notification constraints for `REPORT_RESOLVED`.
Flyway V25 extends the reporting target constraint with `PROJECT` and
`CAREER_POST`; it changes no existing report, action-link, foreign-key, index, or
duplicate-open-report rule. V1-V16 are inherited unchanged. V17 retains the
connection, club, direct-message, and account-status notification combinations
introduced through V16. `ContentReportingMigrationTests` checks both the populated
V16-to-V17 compatibility boundary and a populated V24-to-V25 upgrade that retains
existing reports and module rows while enforcing the extended target constraint.
Run each method against its own empty disposable PostgreSQL database:

```bash
./mvnw '-Dtest=ContentReportingMigrationTests#v17UpgradesPopulatedV16SchemaAndEnforcesReportingInvariants' \
  -Dcontent.reporting.migration.url=jdbc:postgresql://localhost:5432/uniconnect_reporting_v17_test \
  -Dcontent.reporting.migration.username=postgres \
  -Dcontent.reporting.migration.password=local-test-only test

./mvnw '-Dtest=ContentReportingMigrationTests#v25UpgradesPopulatedV24SchemaAndPreservesExistingReports' \
  -Dcontent.reporting.migration.url=jdbc:postgresql://localhost:5432/uniconnect_reporting_v25_test \
  -Dcontent.reporting.migration.username=postgres \
  -Dcontent.reporting.migration.password=local-test-only test
```

Use only a disposable database: the test migrates and writes its schema. Keep
credentials out of shell history in shared environments.
