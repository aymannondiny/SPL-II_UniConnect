# Club lifecycle administration

Requires a current session for an ACTIVE, non-anonymized SYSTEM_ADMIN with
SYSTEM_ADMINISTRATION selected. Personal or club context is insufficient.
All successful responses use Cache-Control: no-store.

| Method | Path | Result |
| --- | --- | --- |
| GET | /api/v1/admin/clubs/{id} | ClubResponse, including a removed club |
| POST | /api/v1/admin/clubs/{id}/publishing/suspend | ACTIVE -> PUBLISHING_SUSPENDED |
| POST | /api/v1/admin/clubs/{id}/publishing/restore | PUBLISHING_SUSPENDED -> ACTIVE |
| POST | /api/v1/admin/clubs/{id}/remove | ACTIVE or PUBLISHING_SUSPENDED -> REMOVED |
| GET | /api/v1/admin/clubs/{id}/audit?page=0&size=20 | Retained authority and lifecycle audit |

POST body (required for every request, including retries):

```json
{"reason":"Reviewed by system administration","confirm":true}
```

Reason must be nonblank and at most 1000 characters. All successful operations
return HTTP 200 with ClubResponse. A valid authorized retry targeting the existing
state returns the unchanged record and emits no additional audit or notification.
Removal is terminal: suspend/restore against REMOVED return 409 INVALID_CLUB_STATE.
Restoration requires exactly one current ACTIVE, non-anonymized STUDENT
administrator; otherwise 409 INELIGIBLE_CLUB_ADMINISTRATOR. Reactivating the
original administrator can satisfy this eligibility rule, but neither reactivation
nor administrator replacement restores publishing: a system administrator must
explicitly use the restoration endpoint.

Suspension keeps the club, published announcements and published events visible.
Existing permitted edits, unpublishing and removal remain available; new publishing
returns 403. Existing draft creation follows the publications API's ACTIVE-club
requirement. Suspension retains role assignments and selected club contexts.

Removal hides the club and all its publications from normal browsing and direct
public access. Publication rows, authorship and audits are retained. Current role
assignments are revoked, their selected contexts in every session reset to PERSONAL,
and one existing CLUB_ROLE_REVOKED notification is sent per assignment. Personal
sessions and other selected club contexts remain usable. Revoking the administrator
frees their one-club administrator slot. No restoration endpoint exists for removal.

Each actual transition appends a club audit with actor, reason, previousState,
newState and timestamp. targetAssignmentId is null for lifecycle events; older
assignment audit rows retain their target and have null state fields. Suspension
and restoration notify the current administrator once per transition using
PUBLISHING_SUSPENDED/PUBLISHING_RESTORED and referenceType CLUB. Restoration
notifications have no authority-granting effect. No all-member broadcast occurs.

Removed club metadata and club authority/lifecycle audit remain available through
the system administration endpoints above. A general moderation archive for
publication bodies is outside this slice.

## Verify locally

Run with Java 21 before starting the backend against Neon:

```bash
cd code/backend
./mvnw -Dtest=ClubLifecycleIntegrationTests,ClubLifecycleMigrationTests test
./mvnw clean verify
```

The club lifecycle schema remains owned by Java migration
V13__extend_club_lifecycle_audits. Account moderation adds V14 without changing
V1-V13.

Use a disposable test club for removal:
1. Publish an announcement and event; also create an unpublished announcement.
2. As SYSTEM_ADMIN in SYSTEM_ADMINISTRATION, suspend publishing with a reason.
3. Public announcement/event reads still return 200. Publishing the draft or a new
   event returns 403 in the operator's CLUB context.
4. Restore publishing; the current administrator receives PUBLISHING_RESTORED.
   Repeat restoration and verify no duplicate audit/notification.
5. Remove the test club with confirmation. Public reads return 404; operators'
   selected contexts fall back to PERSONAL. Existing records remain in the database.
6. System admin GET and audit remain accessible; restoring the removed club is 409.

Account suspension/reactivation and automatic publishing suspension are documented
in [Account moderation](ACCOUNT_MODERATION.md). Account anonymization, content
reports, and Flutter administration screens remain separate work.
