# Project Teammate Finder API

All routes use `/api/v1/projects`, require a bearer session, return `Cache-Control: no-store`, and require the current account to be an ACTIVE, non-anonymized STUDENT. Lifecycle timestamps are UTC. `applicationDeadline` is a date and remains valid through that calendar day in `Asia/Dhaka`.

## Project routes

| Method | Route | Behavior |
| --- | --- | --- |
| `POST` | `/api/v1/projects` | Creates an OPEN recruitment listing and its sole CREATOR membership atomically. Capacity is 2–100 and includes the creator. At least one skill must be required. |
| `GET` | `/api/v1/projects` | Paginated browse. Supports `status`, `availability`, `departmentId`, `skill`, `sort`, `page`, and `size`. |
| `GET` | `/api/v1/projects/mine` | Creator's non-deleted OPEN and CLOSED projects, including expired projects. |
| `GET` | `/api/v1/projects/{projectId}` | Direct details, including closed or expired projects and the viewer's lifetime application status. Deleted projects return 404. |
| `PUT` | `/api/v1/projects/{projectId}` | Creator-only edit. Capacity cannot fall below current membership. A new valid deadline can restore an expired OPEN project's availability. |
| `POST` | `/api/v1/projects/{projectId}/close` | Creator-only, idempotent close. Pending applications remain reviewable. |
| `POST` | `/api/v1/projects/{projectId}/reopen` | Creator-only reopen; requires CLOSED, a vacancy, and a deadline valid today or later. |
| `DELETE` | `/api/v1/projects/{projectId}` | Creator-only terminal soft deletion with `{ "confirmed": true }`. Cancels pending applications and notifies each affected applicant once. |
| `GET` | `/api/v1/projects/{projectId}/members` | Lists retained creator/teammate memberships. |
| `GET` | `/api/v1/projects/{projectId}/audit` | Creator-only paginated audit history. |

## Candidate search routes

Candidate search is FR_29 filtering, not FR_30 recommendation scoring. It never creates a project, application, audit, notification, recommendation, or skill-vocabulary row.

| Method | Route | Behavior |
| --- | --- | --- |
| `GET` | `/api/v1/projects/candidates` | Standalone teammate search. Requires at least one `requiredSkills` value. Supports `optionalSkills`, `departmentId`, `yearOfStudy`, `projectAvailable`, `sort`, `page`, and `size`. |
| `GET` | `/api/v1/projects/{projectId}/candidates` | Creator-only search using the project's stored skills. Requires OPEN, non-expired recruitment with a vacancy. Excludes current members and every lifetime applicant before count and pagination. |

Candidates must possess every normalized required skill. Optional skills never affect eligibility, count, ordering, or pagination; they only appear in `relevantSkills` when the visible candidate profile contains them. Each relevant skill is labelled `REQUIRED` or `OPTIONAL`. Skills are trimmed, internal whitespace is collapsed, names are lowercased, duplicates within each list are removed, overlap between the lists is rejected, and the combined limit is 10.

Candidate role is always STUDENT. Searcher and candidates must be ACTIVE and non-anonymized. Department, study year, and project availability combine with AND. Omitting `projectAvailable` includes both available and unavailable Students. `sort` is `NAME_ASC` by default or `NAME_DESC`; normalized name and user ID provide deterministic ordering. Pagination defaults to page 0 and size 20, with size 1–50.

Profile privacy is applied in query predicates, counts, ordering, and pagination. Skills, study year, and availability are protected details, so a `CONNECTIONS_ONLY` candidate requires an accepted connection. Results contain only user ID, name, photo, department, programme, study year, project availability, visible requested-skill intersection, and any current connection summary. Use the user ID with `GET /api/v1/members/{userId}` for the permitted profile. Email, student number, application messages, scores, percentages, ranks, and inferred explanations are absent.

Candidate matching and `projectAvailable` are discovery rules only. They do not change `canApply` or application submission: an otherwise eligible Student may browse and apply without matching project skills or opting into candidate discovery.

`sort` is `CREATED_DESC` by default or `DEADLINE_ASC`.

`title` identifies the recruitment listing; it does not assert that the team already has a finalized project idea. Students may recruit around a shared area or working style, form the team, and decide the topic together. Title validation remains required and limited to 200 characters. A team-first request can look like:

```json
{
  "title": "Form a team for an AI course project",
  "description": "Looking for teammates who want to explore ideas together before selecting our final topic.",
  "teamSizeLimit": 4,
  "duration": "One semester",
  "courseName": "CSE 455",
  "applicationDeadline": "2026-10-31",
  "skills": [
    { "name": "Python", "required": true },
    { "name": "Machine Learning", "required": false }
  ]
}
```

`canApply` is a viewer-specific UI hint. It is false for the creator, any existing member, anyone with a lifetime application, and whenever the project is closed, expired, full, deleted, or its creator is not currently eligible. Mutation endpoints independently recheck every rule and do not trust this response flag.

### Status and availability filters

`status` is stored lifecycle state: `OPEN`, `CLOSED`, or `DELETED`. Deleted projects are excluded regardless of filter.

`availability` is derived and never stored:

- `AVAILABLE`: OPEN, deadline not passed, and at least one vacancy.
- `FULL`: OPEN, deadline not passed, and membership count equals capacity.
- `EXPIRED`: OPEN and the Dhaka-local deadline has passed.
- `CLOSED`: stored status is CLOSED.

With neither `status` nor `availability`, browsing returns OPEN projects whose deadline is today or later, including both AVAILABLE and FULL projects. A supplied `status` removes that default expiry restriction. A supplied `availability` selects its derived state. When both are supplied they combine with AND, so contradictory combinations return an empty page. Full OPEN projects remain visible but reject applications.

`departmentId` uses the creator's current profile department, not a project snapshot. All supplied filters combine with AND.

## Application routes

| Method | Route | Behavior |
| --- | --- | --- |
| `POST` | `/api/v1/projects/{projectId}/applications` | Creates one lifetime PENDING application. Optional `message` is at most 500 characters. Creator, members, expired/closed/full projects, and projects whose creator is suspended reject the request. |
| `GET` | `/api/v1/projects/{projectId}/applications` | Creator-only list. Pending applications remain reviewable after close or expiry. |
| `POST` | `/api/v1/projects/applications/{applicationId}/accept` | Atomically rechecks applicant eligibility and capacity, accepts, creates one TEAMMATE membership, audits, and notifies. |
| `POST` | `/api/v1/projects/applications/{applicationId}/reject` | Atomically rejects, audits, and notifies. |

Applications cannot be withdrawn or recreated. Identical terminal review retries return the existing result without duplicate memberships, audits, or notifications. A conflicting review returns `409 INVALID_PROJECT_STATE`.

## Concurrency and privacy

Project actions lock all involved account rows in ascending user ID order before the project row. This serializes account suspension with create/apply/manage/review operations and serializes acceptance, capacity changes, and deletion on the project row. Database uniqueness protects lifetime applications, memberships, the sole creator membership, and recipient/event notification delivery.

`ProjectOwnerPrivacyService.redactOwner` is the project-owned hook for a future account-anonymization transaction. Its caller must already hold the account lock and an active transaction. It redacts creator attribution, terminally soft-deletes owned projects, cancels every pending application, and emits one deletion notification per cancelled application. This milestone does not implement account anonymization itself.

## Deferred

FR_30 recommendation scoring, project reporting, administrative removal, member leave/removal, ownership transfer, attachments, Flutter work, and automatic chat creation remain outside this milestone.
