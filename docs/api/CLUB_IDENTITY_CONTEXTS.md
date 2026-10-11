# Club identity, roles, and dashboard contexts

All endpoints require a bearer session for an ACTIVE, non-anonymized account. Responses use `Cache-Control: no-store`. Times are UTC. A dashboard selection belongs to one authenticated session; the bearer token does not change when switching dashboards.

## Endpoints

| Method | Path | Access / result |
| --- | --- | --- |
| GET | `/api/v1/auth/contexts` | Current selection, selection time, available contexts |
| PUT | `/api/v1/auth/contexts/active` | Select an available context; returns updated context list |
| GET | `/api/v1/clubs?search=&page=0&size=20` | Browse non-removed clubs; name/category search, name ordering |
| GET | `/api/v1/clubs/{id}` | Club profile |
| POST | `/api/v1/admin/clubs` | Selected SYSTEM_ADMINISTRATION; create club and first administrator atomically, 201 |
| POST | `/api/v1/admin/clubs/{id}/administrator/replace` | Selected SYSTEM_ADMINISTRATION; replace administrator, 200 |
| GET | `/api/v1/admin/clubs/{id}/audit?page=0&size=20` | Selected SYSTEM_ADMINISTRATION; retained audit trail |
| GET | `/api/v1/clubs/{id}/operators?status=CURRENT&page=0&size=20` | Selected administrator context for this club; status CURRENT, REVOKED, ALL |
| POST | `/api/v1/clubs/{id}/representatives` | Selected administrator context for this club; grant representative, 201 |
| POST | `/api/v1/clubs/{id}/representatives/{assignmentId}/revoke` | Selected administrator context for this club; revoke representative, 200 |

Page starts at 0; size 1–50. Directory and operators use `items`, `page`, `size`, `totalElements`.

## Context selection

Every new login starts in PERSONAL. Refresh keeps the selection. A separate login has its own selection. Existing sessions migrate to PERSONAL.

```json
{"contextType":"SYSTEM_ADMINISTRATION"}
```

Only system administrators can select SYSTEM_ADMINISTRATION. For CLUB, use an assignment ID returned by GET contexts, not a user ID or club ID:

```json
{"contextType":"CLUB","assignmentId":1}
```

Return to personal with `{"contextType":"PERSONAL"}`. Omit assignmentId for non-club contexts. Available context entries contain `contextType`, `assignmentId`, `clubId`, `clubName`, `clubRole`; irrelevant values are null. The response contains `activeContext`, `selectedAt`, and `availableContexts`.

Club permissions are revalidated for each protected action. Representatives can select a club dashboard but cannot manage operators. Other existing APIs keep their existing authorization rules.

## Creation and assignments

Create as a system administrator after selecting SYSTEM_ADMINISTRATION:

```json
{
  "clubName":"UniConnect Computing Club",
  "category":"Technology",
  "description":"Student programming and software engineering activities.",
  "administratorUserId":2
}
```

Required fields: name (150 characters), category (100), description (5000), administratorUserId. Optional `logoUrl` (HTTPS URL, 2048 characters; stored only, not fetched) and `contactEmail` (320). Names are unique after trimming and case normalization.

Only ACTIVE, non-anonymized STUDENT accounts can receive roles. Each club has one current administrator. A student can administer at most one club and represent other clubs. A student cannot hold two current roles in the same club.

Assign representative body: `{"userId":3}`. Response includes assignment `id`, clubId, userId, fullName, role, current, assignedBy, assignedAt, revokedBy, revokedAt.

Revoke representative:

```json
{"reason":"Representative duties completed.","confirmed":true}
```

Replace administrator as system administrator:

```json
{"userId":3,"reason":"Approved handover of club administration.","confirmed":true}
```

Replacement revokes the previous administrator and grants the replacement in one transaction. Promoting an existing representative revokes their representative assignment and creates a new administrator assignment. Historical assignments remain available. Revoked assignments immediately reset affected sessions to PERSONAL; users must select their new assignment explicitly.

Each grant/revocation generates a notification through the existing notification endpoints: CLUB_ROLE_GRANTED / CLUB_ROLE_REVOKED, referenceType CLUB, referenceId club ID. Notifications do not grant access.

## Errors

400: invalid fields, confirmation missing/false, ineligible assignee, invalid context shape or pagination. 401: missing/expired/revoked session. 403: wrong role, wrong selected context, another person's assignment, representative attempting management. 404: unavailable club/member/assignment. 409: duplicate name, administrator already assigned, role already assigned, or assignment already revoked. Error bodies use the existing ApiError contract.

## Manual acceptance checks

1. With a system administrator token, GET contexts, select SYSTEM_ADMINISTRATION, create a club with an existing ACTIVE student as administrator. Expect 201. Verify duplicate normalized name returns 409.
2. As the student administrator, GET contexts. Attempt representative assignment from PERSONAL (403); select the returned CLUB assignment, retry with another ACTIVE student (201).
3. As the representative, GET contexts, select CLUB, and try listing operators or assigning another representative (403). Verify the grant notification.
4. As administrator, list CURRENT and ALL operators. Revoke the representative with confirmed=false (400), then confirmed=true (200). As representative, GET contexts: PERSONAL selected, revoked option absent. Selecting the old assignment returns 403. Verify one revocation notification.
5. As system administrator, replace the administrator with the other student. Verify old administrator's sessions lose that club context and old management requests fail. New administrator selects their new assignment and can list ALL operators. Check audit history.
6. Log in twice as a club operator. Switching one session leaves the other unchanged. Refresh the selected session and verify its selection survives.
7. Verify chat, connections, and existing notifications still work. Club directory must not expose removed clubs; publishing-suspended clubs remain visible.

This module provides identity and operator access. Announcements, events, club lifecycle actions, and Flutter screens are separate work.
