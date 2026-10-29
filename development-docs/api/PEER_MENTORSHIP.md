# Peer Mentorship API Specification

This document describes the Peer Mentorship API introduced by `V11` and corrected by forward migration `V26`.

## Architecture & Privacy Policies

1. **Eligibility Rule (M1)**:
   - Senior Students (`PlatformRole == STUDENT` with `yearOfStudy >= 2`) and verified `ALUMNI` can register as peer mentors.
   - Junior students (`yearOfStudy < 2`) and administrators cannot register as mentors.
   - Profile completion is required prior to mentor registration.
2. **Approved Expertise & Skill Entity Mapping**:
   - `MentorExpertise` links directly to the shared `Skill` entity via `skill_id` foreign key.
   - Skills are resolved or registered through the `ProfileQueryService` module boundary.
3. **Profile Privacy Rules**:
   - Academic details (`departmentName`, `yearOfStudy`, `graduationYear`) respect the user's `ProfileVisibility` configuration.
   - If visibility is set to `CONNECTIONS_ONLY`, viewers who are not accepted connections will see `null` for these academic fields, while the mentor's name and expertise remain visible.
4. **Mentor Directory Visibility & Stable Pagination**:
   - Only mentors with status `AVAILABLE` and whose accounts are `ACTIVE` and non-anonymized are returned.
   - Filtering is executed at the database query and count query level to ensure accurate `totalElements` without empty pages.
   - Directory results use stable tie-breaker sorting: `registeredAt DESC, mentorProfileId DESC`.
5. **Series, enrollment, and time**:
   - `ONE_TIME`, `WEEKLY`, and `BIWEEKLY` are the only schedule products. Series are finite: `recurrenceEndDate` or `meetingCount` (1–52) bounds recurring schedules. For compatibility, an omitted recurring bound means the established 12 meetings.
   - Schedule dates/times and persisted occurrence times are Asia/Dhaka local values. Lifecycle timestamps are UTC.
   - Dated `MentorshipOccurrence` rows are authoritative. Edits retain matching future rows and replace only changed future meetings; cancellation cancels only future meetings. Past and ongoing rows retain their IDs and values.
   - A Student or Alumni enrollment covers remaining unstarted meetings. Leave/rejoin creates a new enrollment period and retains earlier timestamps and private notes.
6. **Availability, conflicts, and locking**:
   - Enrollment closure, derived fullness, mentor availability, completion, and cancellation are independent states.
   - Hosted occurrences conflict with `[start,end)` semantics; cancelled occurrences do not block time. Create/update serialize on the host mentor, while join/rejoin checks only meetings the applicant hosts.
   - Join, leave, capacity, close/reopen, and cancel lock the series so concurrent requests cannot overbook or duplicate transitions.
7. **Response privacy**:
   - Meeting links are emitted only to the host or a currently enrolled participant while an ongoing/future meeting remains. A historical enrollment period never receives a link, even when its participant later rejoins. This applies to browse, detail, hosted, current-series, participation-history, and enrollment responses.
   - Only the host can retrieve the roster. A participant can retrieve their own enrollment periods and private join message/goals.
   - No administrator bypass is provided. ACTIVE/non-anonymized account checks remain mandatory.

---

## Endpoints

All endpoints require a valid bearer session header: `Authorization: Bearer <token>`.

### Mentor Profiles (`/api/v1/mentorship/mentors`)

| Method | Path | Description | Response Status |
| --- | --- | --- | --- |
| `POST` | `/api/v1/mentorship/mentors` | Register as a peer mentor | `201 Created` |
| `GET` | `/api/v1/mentorship/mentors/me` | Retrieve own mentor profile | `200 OK` |
| `PATCH` | `/api/v1/mentorship/mentors/me/status` | Update availability status (`AVAILABLE` / `UNAVAILABLE`) | `200 OK` |
| `GET` | `/api/v1/mentorship/mentors` | Search and browse available mentors in directory | `200 OK` |
| `GET` | `/api/v1/mentorship/mentors/{id}` | View detailed mentor profile by ID | `200 OK` |

### Mentorship Slots (`/api/v1/mentorship/slots`)

| Method | Path | Description | Response Status |
| --- | --- | --- | --- |
| `POST` | `/api/v1/mentorship/slots` | Publish a new mentorship slot (US42) | `201 Created` |
| `GET` | `/api/v1/mentorship/slots` | Browse open mentorship slots (US44) | `200 OK` |
| `GET` | `/api/v1/mentorship/slots/{id}` | View mentorship slot details (US44) | `200 OK` |
| `PUT` | `/api/v1/mentorship/slots/{id}` | Update mentorship slot details (US47) | `200 OK` |
| `POST` | `/api/v1/mentorship/slots/{id}/join` | Join / reserve place in open slot (US45) | `200 OK` |
| `POST` | `/api/v1/mentorship/slots/{id}/leave` | Leave / release place in slot (US46) | `200 OK` |
| `POST` | `/api/v1/mentorship/slots/{id}/close` | Close slot enrollment (US48) | `200 OK` |
| `POST` | `/api/v1/mentorship/slots/{id}/reopen` | Reopen enrollment when a future meeting and vacancy remain | `200 OK` |
| `POST` | `/api/v1/mentorship/slots/{id}/cancel` | Cancel the series and future occurrences (US49) | `200 OK` |
| `GET` | `/api/v1/mentorship/slots/my-mentoring` | List slots created by authenticated mentor (US50) | `200 OK` |
| `GET` | `/api/v1/mentorship/slots/my-enrolled` | Original contract: list current enrollment records for authenticated mentee (US50) | `200 OK` |
| `GET` | `/api/v1/mentorship/slots/my-current-series` | Additive card-ready summaries for current participation | `200 OK` |
| `GET` | `/api/v1/mentorship/slots/my-participation` | List current and historical participation periods | `200 OK` |
| `GET` | `/api/v1/mentorship/slots/enrollments/{enrollmentId}` | Retrieve own enrollment, or retrieve as its host | `200 OK` |
| `GET` | `/api/v1/mentorship/slots/{id}/enrollments` | List enrolled attendees for host mentor | `200 OK` |

---

### Request & Response Examples

#### 1. Register as Mentor
`POST /api/v1/mentorship/mentors`

```json
{
  "mentoringBio": "Experienced in Algorithms, Data Structures, and Spring Boot development.",
  "expertise": [
    {
      "topic": "Algorithms",
      "description": "Graph algorithms and dynamic programming"
    },
    {
      "topic": "Spring Boot",
      "description": "REST APIs and modular monolith design"
    }
  ]
}
```

#### 2. Publish a Mentorship Slot
`POST /api/v1/mentorship/slots`

```json
{
  "topic": "Graph Theory Deep Dive",
  "description": "Interactive study session covering shortest path algorithms and minimum spanning trees.",
  "scheduleType": "WEEKLY",
  "startDate": "2026-10-20",
  "startTime": "14:00:00",
  "endTime": "15:30:00",
  "meetingCount": 8,
  "mode": "ONLINE",
  "meetingLink": "https://meet.uniconnect.local/graphs",
  "capacity": 5
}
```

Response:
```json
{
  "slotId": 1,
  "mentorProfileId": 1,
  "mentorUserId": 42,
  "mentorName": "Alice Rahman",
  "topic": "Graph Theory Deep Dive",
  "description": "Interactive study session covering shortest path algorithms and minimum spanning trees.",
  "scheduleType": "WEEKLY",
  "startDate": "2026-10-20",
  "startTime": "14:00:00",
  "endTime": "15:30:00",
  "recurrenceEndDate": null,
  "mode": "ONLINE",
  "location": null,
  "meetingLink": "https://meet.uniconnect.local/graphs",
  "capacity": 5,
  "currentMenteeCount": 0,
  "status": "OPEN",
  "createdAt": "2026-10-15T10:00:00Z",
  "updatedAt": "2026-10-15T10:00:00Z"
}
```

Slot responses preserve existing fields and add `meetingCount`, `enrollmentOpen`, `vacancies`,
`ongoingOccurrenceStartsAt`, `nextOccurrenceStartsAt`, and `occurrenceDetails`. `status` is the
effective API label (`OPEN`, `FULL`, `CLOSED`, `CANCELLED`, or `COMPLETED`); `FULL` and
`COMPLETED` are derived rather than permanent enrollment-closure transitions.

For recurring create requests that omit both bounds, `meetingCount` is `12` and the detail response
contains all twelve persisted dates in `occurrences` and all twelve rows in `occurrenceDetails`.
Summary responses carry the actual `meetingCount` but intentionally omit the full dated schedule;
clients needing every occurrence must retrieve slot detail.

#### 3. Join an Open Slot
`POST /api/v1/mentorship/slots/1/join`

```json
{
  "joinMessage": "Excited to prepare for competitive programming contests!",
  "learningGoal": "Master Dijkstra and Floyd-Warshall algorithms."
}
```

Response:
```json
{
  "enrollmentId": 1,
  "slotId": 1,
  "slotTopic": "Graph Theory Deep Dive",
  "menteeId": 55,
  "menteeName": "Bob Ahmed",
  "joinMessage": "Excited to prepare for competitive programming contests!",
  "learningGoal": "Master Dijkstra and Floyd-Warshall algorithms.",
  "status": "ACTIVE",
  "joinedAt": "2026-10-15T10:15:00Z",
  "leftAt": null
}
```
