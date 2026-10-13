# Peer Mentorship API Specification

This document details the Peer Mentorship endpoints introduced in `feature/peer_mentorship` under Flyway migration `V11`.

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
5. **Milestone Status & Scope Clarification**:
   - **Current Milestone Completion**: ~50% complete.
   - **Implemented**: Mentor registration (US40/US41), shared skills alignment, profile privacy controls, directory search with topic filter, mentorship slot publishing (US42), slot browsing (US44), slot enrollment (US45), releasing slot place (US46), slot details updating (US47), closing enrollment (US48), session cancellation (US49), and personal session tracking (US50).
   - **Pending Workflows**:
     - Multi-criteria department and year filters on mentor directory search (required by FR43 / US43).
     - Automated recurrence occurrence generation for weekly/biweekly schedules.
     - Mentee/mentor notification delivery on slot cancellations and enrollment events.

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
| `POST` | `/api/v1/mentorship/slots/{id}/cancel` | Cancel slot and active enrollments (US49) | `200 OK` |
| `GET` | `/api/v1/mentorship/slots/my-mentoring` | List slots created by authenticated mentor (US50) | `200 OK` |
| `GET` | `/api/v1/mentorship/slots/my-enrolled` | List slots joined by authenticated mentee (US50) | `200 OK` |

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
