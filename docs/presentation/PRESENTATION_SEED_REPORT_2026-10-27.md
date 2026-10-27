# Presentation seed execution report — 2026-10-27

## Target and backup

- Source commit: `e83b1fdd9ab4bbea3479e202ef29f692d3cb15a1`
- Schema: exact successful Flyway V1-V27 history
- Target: trusted local configuration's existing Neon development database, direct TLS
- Pre-write archive: private custom-format backup stored outside the repository
- SHA-256 sidecar: stored beside the private archive
- Verification: `pg_restore --list` passed; full archive restore into a fresh local
  PostgreSQL database passed and contained V27, account data and session schema

The backup directory and files are mode-restricted and outside Git. Recovery must
be coordinated because a full restore also reverts unrelated changes made after
the backup.

## Dry-run and account decisions

The Neon dry-run planned 35 account inserts and one normalized-email reuse. User ID
1 matched `ayman@iut-dhaka.edu`, was already ACTIVE and SYSTEM_ADMIN, and retained
its ID/name. Its password was explicitly updated and active sessions were revoked
with `ACCOUNT_CHANGE`. `sayma@iut-dhaka.edu` and the other 34 accounts were inserted.
No anonymized or unexpected identity conflict was found. No unrelated account was
updated.

## Validation

- Current backend package build: passed with tests skipped for the packaging step.
- Fresh PostgreSQL 18.3 migration V1-V27: passed.
- Empty-database dry-run/apply/SQL verify/API verify: passed.
- Populated-database collision, catalogue reuse and unrelated-record preservation: passed.
- Existing mixed-case Ayman ID reuse, normalization, promotion and session revocation: passed.
- Intentional failure after account processing: exited non-zero and rolled back account changes,
  session revocation, manifest tables and all inserts.
- Completed rerun after a simulated notification read: no-op; read interaction preserved.
- Recommendation calculation/API: Abdullah 86.97, Tasnim 48.79, Nusrat 44.85.
- Neon SQL verification at manifest revision 3: passed.
- Neon-backed HTTP verification: nine representative logins (student, alumni and both named
  administrators) and all read/context assertions passed; pending actions were not consumed.
- Flutter execution: not run and Flutter files were not changed.

During post-write verification, a populated-vocabulary alias defect was detected:
the initial application could only attach pre-existing vocabulary. The account and
content transaction itself was valid, and unrelated rows were unaffected. Two
bounded, additive repairs were first validated locally, then applied only through
the dataset's durable ownership map. Manifest revision 3 contains the complete
intended profile, project, career and mentor associations. This repair history is
retained in the tooling rather than hidden.

## Presentation window

The base date is 2026-10-27 (Asia/Dhaka); the documented window ends 2026-12-26.
Upcoming event/project/mentorship examples are relative to the base date and remain
useful throughout the near-term presentation period.

## Report-scenario extension (manifest revision 5)

The existing revision-3 state was inspected before modification: two mapped reports
(`SUBMITTED` project and `UNDER_REVIEW` career post), Flyway V27, and the original
presentation ownership map were intact. The additive upgrade inserted eight reports,
two dedicated removed publication targets, five publication audits, eighteen report
audits, two verified action links, four reporter notifications, and ten ownership-map
rows. It updated only the manifest revision from 3 to 4.

A bounded revision-4-to-5 normalization then cleared three presentation-owned
`UNDER_REVIEW` report notes and six `UNDER_REVIEW` audit notes. Those notes cannot
be produced by the actual review-claim service; internal notes first become valid
at resolution. Terminal resolution notes were preserved. No accounts, passwords,
roles, sessions, targets, or unrelated rows were changed by this normalization.

Exact database counts before → after were:

| Table/ownership set | Before | After | Delta |
| --- | ---: | ---: | ---: |
| users | 40 | 40 | 0 |
| club announcements | 5 | 6 | +1 |
| club events | 3 | 4 | +1 |
| club publication audits | 2 | 7 | +5 |
| content reports | 3 | 11 | +8 |
| report audit logs | 4 | 22 | +18 |
| report action links | 0 | 2 | +2 |
| notifications | 40 | 44 | +4 |
| presentation manifest keys | 123 | 133 | +10 |

The presentation-owned total is 10 reports: 3 `SUBMITTED`, 3 `UNDER_REVIEW`,
2 `ACTION_TAKEN`, and 2 `NO_ACTION`. They cover `USER`, `CLUB`, `ANNOUNCEMENT`,
`EVENT`, `CHAT_MESSAGE`, `PROJECT`, and `CAREER_POST`. The chat reporter is an
actual participant. Both action-taken resolutions link committed `REMOVED`
publication audits created after report submission and against the exact targets.

Validation performed for this extension:

- Populated disposable PostgreSQL 18.3 revision 3 → 4: passed.
- Revision-5 SQL structural/semantic verification: passed.
- Rerun after a simulated notification-read interaction: no-op; interaction preserved.
- Local API verification: passed all report queue, lifecycle filter, privacy,
  evidence, notification, reporter ownership, and authorization assertions.
- Fresh private pre-write backup: custom-format archive, checksum, archive listing,
  full local restore, and V27/revision-3/two-report checks all passed.
- Neon report-only dry-run and atomic upgrade: passed.
- Neon revision-5 SQL verification: passed. The revision-4 correction dry run
  reported exactly three owned report-note and six owned audit-note clears.
- Neon-backed API verification: ten logins and all assertions passed without
  claiming or resolving any pending report. This included explicit checks that
  open reports and review-claim audits contain no impossible internal notes;
  Swagger returned HTTP 200.

A fresh pre-extension custom-format recovery archive and its SHA-256 sidecar were
stored privately outside the repository with mode-restricted permissions. The
earlier pre-presentation archive also remains available and its checksum was
reverified. A full restore is destructive to all later database activity, so
recovery must use a separate target for inspection or an explicitly coordinated
maintenance window. Operators should obtain the private archive location through
the project's trusted local operational handoff.
