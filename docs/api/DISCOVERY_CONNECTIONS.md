# Member discovery, profile privacy, and connections

Base commit: `a467a1d`. Flyway V7 adds privacy preferences, connection history,
and persistent connection notifications. Run `./mvnw clean verify` before use.

## Agreed privacy policy

All authenticated ACTIVE members may discover the basic personal profile of
another ACTIVE Student or Alumni: user ID, name, platform role, photo,
department, and programme. An account without a personal profile has no
member-profile result. Administrators have no personal profile and are not
listed in discovery; they have no bypass for restricted profile details.

Additional details (degree, bio, skills, interests, study year, graduation year,
availability, and Alumni professional details including LinkedIn URL) use one
owner-controlled preference:

- `CONNECTIONS_ONLY` (default, including existing profiles migrated by V7).
- `ALL_MEMBERS` (all authenticated ACTIVE members).

Owners can always read their own details. Public DTOs never contain email or
student number, even for accepted connections. Owners retain student number
through the existing `/api/v1/profile/me` endpoint. Existing profile PUTs do not
change privacy preferences.

Pending requests do not unlock details. Removing an accepted connection removes
its visibility entitlement immediately for subsequent requests. Account
suspension/anonymization excludes the target from discovery and profile viewing.
Search filtering, count, and pagination all apply the same visibility rule; a
hidden skill/company/year/availability cannot be inferred from a filtered hit.
Shared skills/interests are returned only when the target's details are visible.

## API

All endpoints require a current bearer session. Responses use `Cache-Control:
no-store`; errors use the canonical ApiError contract. IDs identify records,
not permission. Callers cannot supply a requester or owner ID.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/v1/profile/me/privacy` | Read own visibility preference |
| PATCH | `/api/v1/profile/me/privacy` | Save `detailsVisibility` |
| GET | `/api/v1/members` | Search permitted member profiles |
| GET | `/api/v1/members/{userId}` | View permitted member profile |
| POST | `/api/v1/connections` | Send request; returns 201 |
| GET | `/api/v1/connections` | Paginated own connections/requests/history |
| GET | `/api/v1/connections/{id}` | Participant-only record, including history |
| POST | `/api/v1/connections/{id}/accept` | Receiver accepts PENDING |
| POST | `/api/v1/connections/{id}/reject` | Receiver rejects PENDING |
| POST | `/api/v1/connections/{id}/cancel` | Requester cancels PENDING |
| POST | `/api/v1/connections/{id}/remove` | Either participant removes ACCEPTED |
| GET | `/api/v1/notifications` | Paginated own notifications |
| PATCH | `/api/v1/notifications/{id}/read` | Mark own notification read |

Privacy request:

```json
{"detailsVisibility":"ALL_MEMBERS"}
```

Connection request (use the recipient's actual user ID):

```json
{"receiverId":2,"introductoryMessage":"Hello! I would like to connect."}
```

Other successful operations return 200. Invalid transitions and duplicate open
pairs return 409. Self-requests and invalid input return 400. A participant using
the wrong action returns 403. Outsiders receive 404 for connection records.

### Discovery filters

`name`, `role` (`STUDENT` or `ALUMNI`), `departmentId`, `programmeId`, `skills`,
`yearOfStudy`, `projectAvailable`, `mentorshipAvailable`, `company`, `industry`,
`graduationYear`. Name/company/industry are case-insensitive literal substring
matches, so `%` and `_` are not wildcard syntax. Skills are normalized exact
matches; all supplied skills must match (maximum 10). Use `role=STUDENT` for
teammate searches. Mixing incompatible Student and Alumni filters returns no
results. Empty text filters are ignored. The viewer is excluded from search.

Sorting: `NAME_ASC` (default) or `NAME_DESC`, with user ID as a stable tiebreaker.
Pagination: `page=0`, `size=20` by default; size 1–50, page 0–100000.
Results contain `items`, `page`, `size`, `totalElements`.

Example: `/api/v1/members?role=STUDENT&skills=java&skills=sql&projectAvailable=true`.
Only profiles whose details the viewer may access can match these detail filters.

Each result includes `detailsVisible`; hidden `details` are omitted. An open
relationship is represented by `connection: {id,status,outgoing}`. No open
relationship means this property is omitted. Terminal records remain accessible
through the participant-only connection APIs.

### Connection lists

Defaults: `status=ACCEPTED`, `direction=ALL`, `sort=NEWEST`, `page=0`, `size=20`.
Status supports PENDING, ACCEPTED, REJECTED, CANCELLED, REMOVED. Direction supports
ALL, INCOMING, OUTGOING (original requester direction). `sort=NAME` and a literal
case-insensitive `name` filter are also supported.

`totalElements` is a database-derived count under the supplied filters; the
unfiltered ACCEPTED list supplies the mutual connection count. Historical
records and accepted relationships with unavailable accounts are retained;
those peers display `Unavailable member`. They are still excluded from discovery.
No connection count is stored on User.

### Eligibility and concurrency

Sending and accepting require both accounts to be ACTIVE and non-anonymized.
Reject/cancel/remove allow an ACTIVE actor to close an eligible relationship
state even when the other account is unavailable. Both accounts are locked in
ascending user-ID order before reading mutable connection state. Session validity
is checked again under the account lock. At most one PENDING or ACCEPTED row can
exist per unordered pair. Nullable open-pair keys and a database unique constraint
also enforce the invariant outside application code. Closed rows preserve history;
a new request gets a new ID, and previously closed relationships are not reopened.

Duplicate actions return 409; they never create a second acceptance notification.
The current phase permits a new request after rejection, cancellation, or removal;
there is no cooldown or blocking feature in the approved baseline.

### Notifications and chat boundary

A request saves one `CONNECTION_REQUESTED` notification for its receiver.
Acceptance saves one `CONNECTION_ACCEPTED` notification for the requester.
Notifications commit/roll back with the relationship change and have a unique
(recipient, eventKey) constraint. Generic messages contain no copied private
profile data. Read state is recipient-only and marking read is idempotent.

Following a CONNECTION reference must call the protected connection endpoint;
the notification itself grants no access. This phase delivers polling and mark-read
only; live push, other notification types, dismissal/unread UI, and chat are later
work. No Conversation or ordinary Message is created here. Future chat must check
accepted connection state and current account eligibility before every send,
while retaining history after removal.

## Swagger walkthrough

1. Use two ACTIVE Student/Alumni accounts with personal profiles, A and B.
2. As A, `GET /members` (under `/api/v1`) returns B's basic profile with
   `detailsVisible=false`. A skills filter matching B returns no hit yet.
3. As B, GET own privacy: expect CONNECTIONS_ONLY. PATCH ALL_MEMBERS; as A,
   confirm B's details and matching skills become visible. Restore CONNECTIONS_ONLY.
4. As A, POST a request to B. Expect 201 PENDING. Repeat/reverse: expect 409.
5. As B, GET `/connections?status=PENDING&direction=INCOMING`; expect A's request.
   GET notifications; expect exactly one request notification.
6. As A, try accepting: expect 403. As B, accept: expect 200 ACCEPTED.
7. As A, view B and filter by B's skills: details/results now visible. Email and
   student number must be absent. GET notifications: one acceptance notification.
8. Remove as either participant. Expect REMOVED, accepted count drops, B's private
   details and filtered hits disappear, and the old connection record remains.
9. Send a new request, then exercise reject/cancel with the proper actor.
10. Refresh access tokens when needed. Do not paste authorization headers.

## Verification status

The patch includes 19 new Spring integration tests for privacy, filter non-disclosure,
lifecycle/ownership, database uniqueness, concurrent opposite requests and state
transitions, notification atomicity/ownership, revoked sessions, pagination, and
OpenAPI. Existing profile behavior remains covered by the earlier tests.

Full Maven verification must be run in Java 21 with dependency access. The authoring
workspace checked Java syntax and patch applicability but could not compile or run
the suite because Maven Central was unreachable and only Java 17 was installed.
