# Club announcements and events

This backend slice implements requirements FR20–24 and FR84–90 on top of club
identity, assignments and session contexts. Flutter screens are separate work.

## Access and ownership

Public announcement/event reads do not require login or club membership. Published
content from ACTIVE and PUBLISHING_SUSPENDED clubs remains visible. Removed clubs
are excluded. When sending an Authorization header, it must still contain a valid
session token; omit it for anonymous reads.

Management requires an ACTIVE student, a current assignment for the requested
club, and that assignment selected as the session's CLUB context. An administrator
can manage all publications in the club. Representatives can manage only items
created under their **exact current assignment ID**. Revoking and granting a new
assignment does not restore rights over old publications. Original author user and
assignment IDs never change, including administrator edits and handovers.

Use `GET /api/v1/auth/contexts`, then `PUT /api/v1/auth/contexts/active`:

```json
{"contextType":"CLUB","assignmentId":3}
```

Use the actual assignment returned for the logged-in account. A SYSTEM_ADMIN
selection does not confer club publishing permission.

## Public reads

| Method | Path | Behavior |
| --- | --- | --- |
| GET | `/api/v1/announcements` | Published, non-expired feed |
| GET | `/api/v1/announcements/{id}` | Public announcement; hidden states return 404 |
| GET | `/api/v1/events` | UPCOMING and ACTIVE events |
| GET | `/api/v1/events/{id}` | Published current or past event |
| GET | `/api/v1/clubs/{clubId}/events/history` | PAST published events for this club |

All lists use `page=0&size=20`; page range 0–100000, size 1–50. Responses use
`{items,page,size,totalElements}`. Filters apply before pagination and counting.
All responses use `Cache-Control: no-store`.

Announcement filters: `clubId`, `category` (exact match ignoring case), `priority`
(NORMAL, IMPORTANT, URGENT), `publishedFrom` (inclusive), `publishedBefore`
(exclusive). Date-times are UTC ISO local date-times, e.g. `2026-10-12T00:00:00`.
For one day use midnight that day through midnight the following day. Results are
ordered by publishedAt descending, then ID descending. Priorities do not reorder
this feed.

Current-event filters: `clubId`, `category`, `timing` (UPCOMING or ACTIVE).
Results are ordered by startsAt ascending, then ID ascending. The history endpoint
orders by endsAt descending, then ID descending. Use the clubId filters to populate
the announcements/current-events sections of a club profile.

## Management routes

Base: `/api/v1/clubs/{clubId}/publications`. Bearer authentication is required.

| Method | Suffix | Behavior |
| --- | --- | --- |
| POST | `/announcements` | Create UNPUBLISHED draft or PUBLISHED announcement; 201 |
| GET | `/announcements` | Manage own assignment's items, or all for administrator |
| GET | `/announcements/{id}` | Authorized detail, including draft/expired/removed |
| PUT | `/announcements/{id}` | Replace editable content fields |
| POST | `/announcements/{id}/publish` | Publish or republish a draft |
| POST | `/announcements/{id}/unpublish` | Hide a published announcement with confirmation/reason |
| POST | `/announcements/{id}/remove` | Soft-remove with confirmation/reason |
| POST | `/events` | Publish an event; 201 |
| GET | `/events` | Manage own assignment's events, or all for administrator |
| GET | `/events/{id}` | Authorized event detail, including removed |
| PUT | `/events/{id}` | Replace a current event's editable fields |
| POST | `/events/{id}/remove` | Soft-remove with confirmation/reason |
| GET | `/audit` | Administrator-only publication change history |

All non-create successes return 200 with a response body. Management lists accept
`status` or omit it for all states. Events also accept `timing` (including PAST).
Audit history is paginated, newest first, with actor/assignment, action, reason,
UTC timestamp, and before/after response snapshots encoded as JSON strings.

### Announcement requests

Creation:

```json
{
  "title": "Java workshop",
  "content": "Join our introductory Java workshop in Lab 1.",
  "priority": "NORMAL",
  "status": "UNPUBLISHED",
  "expiresAt": null
}
```

Edit uses the same fields **without status**. PUT replaces all editable fields;
null/omitted expiresAt clears the expiry. Title is required, max 200 characters;
content is required, max 10000; priority is required. A supplied expiry must be
later than the current time. Publishing revalidates a draft's expiry.

Publishing takes no body. Unpublishing and removing require:

```json
{"confirm":true,"reason":"Correcting the publication before publishing again."}
```

Reason must be nonblank, max 1000 characters. The same shape removes events.

UNPUBLISHED drafts are never public. Publishing sets publishedAt. Unpublishing
retains that timestamp and authorship; republishing sets a new publishedAt and
retains the earlier cycle in audit history. Repeating publish on an already
published item, unpublish on an already unpublished item, or remove on an already
removed item returns the current representation without another audit record.
Permission and confirmation checks still apply.

At `now >= expiresAt`, a published announcement is effectively EXPIRED. Feeds
exclude it immediately; management returns EXPIRED. It cannot be edited,
unpublished or republished, but can be removed. Expiry can be changed/cleared
before that boundary. Unpublished drafts do not automatically expire, but a stale
expiry must be corrected before publishing. Removed announcements cannot return
to publication in this slice.

### Event request

Replace the example dates with suitable future UTC times before testing:

```json
{
  "title": "Java workshop",
  "description": "Hands-on Java practice for students.",
  "location": "Lab 1",
  "registrationUrl": "https://example.org/workshop-registration",
  "registrationDeadline": "2026-11-01T08:00:00",
  "startsAt": "2026-11-01T09:00:00",
  "endsAt": "2026-11-01T11:00:00"
}
```

Required: title (max 200), description (max 10000), startsAt and endsAt.
`endsAt > startsAt`. Optional location max 500; registrationUrl max 2048 and an
absolute HTTPS URL without embedded credentials; optional registrationDeadline
must be at or before startsAt. URLs are stored as metadata, never fetched by the
backend. There is no RSVP, attendance, participant or ticket model.

UPCOMING means now < startsAt. ACTIVE includes both start and end instants. PAST
means now > endsAt. Past events remain accessible through detail/history and
cannot be edited. Existing historical events may be entered with past dates;
there is no requirement to rewrite their actual dates to the future.

Event PUT replaces the same fields as creation. Optional null values clear fields.
Removed events are excluded from public detail/current/history, but their content,
authorship and removal audit remain available to authorized managers.

## Publishing suspension

PUBLISHING_SUSPENDED blocks new announcements (including drafts), publication of
drafts, and new events. Existing published content remains visible. Authorized
operators may correct existing editable content, unpublish or remove it. Removal
of the club hides its publications and blocks management. Club lifecycle and
system moderation endpoints are separate work; do not change production status
by hand just to exercise these cases. Automated tests cover these states.

## Errors

| Status | Meaning |
| --- | --- |
| 400 | Invalid fields, enum, time range, page, URL or missing confirmation |
| 401 | Missing/expired/invalid session for management |
| 403 | Wrong context, assignment, ownership, or publishing-suspended club |
| 404 | Missing item, wrong club path, or non-public item on public detail |
| 409 | Expired/removed announcement or past/removed event cannot make requested transition |

Service validation uses `INVALID_PUBLICATION_REQUEST`; disallowed state transitions
use `INVALID_PUBLICATION_STATE`. Standard framework/body validation uses the
existing shared ApiError codes. No public feed creates notifications for every
account; there is no defined subscription/recipient audience in this feature.

## Local verification and Swagger walkthrough

1. Run `./mvnw -Dtest=ClubPublicationIntegrationTests,ClubPublicationMigrationTests,ClubMigrationTests test`
   in `code/backend`, then `./mvnw clean verify` before committing.
2. Start the backend normally. Flyway applies V12; do not create tables manually
   in Neon or rewrite V1–V11. Verify there is no other pending migration named V12.
3. Log in as the current club administrator, select their CLUB assignment, and
   create an UNPUBLISHED announcement. Save its returned ID.
4. Confirm it is present in the management list and absent from the public feed.
   Public detail must return 404. Publish it and repeat publish: the ID and
   publishedAt stay the same, with one publish transition in `/audit`.
5. Edit, unpublish, republish and remove it. Check public visibility after each
   transition and inspect the administrator's audit history.
6. Test a published announcement with expiry a minute ahead; after expiry it
   disappears publicly and appears as EXPIRED in management. Editing returns 409.
7. Create an event with start/end a few minutes ahead. Check UPCOMING, then ACTIVE,
   then the club history after the end. Remove it and confirm public exclusion.
8. Use a current representative account to create another draft/event. Another
   representative cannot manage it; the administrator can. Revocation blocks
   access immediately. Regranting a new assignment does not restore old ownership.
9. Confirm public feeds work without Authorization, but management does not.

Frontend: render text as text, convert UTC timestamps to the viewer's timezone,
refresh lists at relevant expiry/start/end boundaries, and rely on backend errors
for authoritative permissions. No WebSocket publication updates are included.
