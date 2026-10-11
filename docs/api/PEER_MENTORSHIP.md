# Peer Mentorship API Specification

This document details the Peer Mentorship endpoints introduced in `feature/peer_mentorship` under Flyway migration `V9`.

## Architecture & Privacy Policies

1. **Eligibility Rule (M1)**:
   - Senior Students (`PlatformRole == STUDENT` with `yearOfStudy >= 2`) and verified `ALUMNI` can register as peer mentors.
   - Junior students (`yearOfStudy < 2`) and administrators cannot register as mentors.
   - Profile completion is required prior to mentor registration.
2. **Mentor Directory Visibility (M11)**:
   - Only mentors with status `AVAILABLE` are listed in the public directory.
   - When a mentor sets status to `UNAVAILABLE`, they are excluded from the public directory and public profile lookup.
   - Mentors can always access their own profile via `/api/v1/mentorship/mentors/me`.

## Endpoints

All endpoints require a valid bearer session header: `Authorization: Bearer <token>`.

| Method | Path | Description | Response Status |
| --- | --- | --- | --- |
| `POST` | `/api/v1/mentorship/mentors` | Register as a peer mentor | `201 Created` |
| `GET` | `/api/v1/mentorship/mentors/me` | Retrieve own mentor profile | `200 OK` |
| `PATCH` | `/api/v1/mentorship/mentors/me/status` | Update availability status (`AVAILABLE` / `UNAVAILABLE`) | `200 OK` |
| `GET` | `/api/v1/mentorship/mentors` | Search and browse available mentors in directory | `200 OK` |
| `GET` | `/api/v1/mentorship/mentors/{id}` | View detailed mentor profile by ID | `200 OK` |

---

### 1. Register as Mentor
`POST /api/v1/mentorship/mentors`

#### Request Body
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

#### Response (`201 Created`)
```json
{
  "mentorProfileId": 1,
  "userId": 42,
  "fullName": "Alice Rahman",
  "role": "STUDENT",
  "departmentName": "Computer Science and Engineering",
  "yearOfStudy": 3,
  "graduationYear": null,
  "profilePhotoUrl": null,
  "mentoringBio": "Experienced in Algorithms, Data Structures, and Spring Boot development.",
  "status": "AVAILABLE",
  "expertise": [
    {
      "expertiseId": 1,
      "topic": "Algorithms",
      "description": "Graph algorithms and dynamic programming"
    },
    {
      "expertiseId": 2,
      "topic": "Spring Boot",
      "description": "REST APIs and modular monolith design"
    }
  ],
  "registeredAt": "2026-10-11T14:45:00Z",
  "updatedAt": "2026-10-11T14:45:00Z"
}
```

---

### 2. Update Mentor Availability Status
`PATCH /api/v1/mentorship/mentors/me/status`

#### Request Body
```json
{
  "status": "UNAVAILABLE"
}
```

#### Response (`200 OK`)
```json
{
  "mentorProfileId": 1,
  "userId": 42,
  "fullName": "Alice Rahman",
  "role": "STUDENT",
  "status": "UNAVAILABLE",
  ...
}
```

---

### 3. Mentor Directory Search
`GET /api/v1/mentorship/mentors?topic=algorithms&page=0&size=20`

#### Response (`200 OK`)
```json
{
  "items": [
    {
      "mentorProfileId": 1,
      "userId": 42,
      "fullName": "Alice Rahman",
      "role": "STUDENT",
      "departmentName": "Computer Science and Engineering",
      "yearOfStudy": 3,
      "graduationYear": null,
      "profilePhotoUrl": null,
      "status": "AVAILABLE",
      "expertiseTopics": [
        "Algorithms",
        "Spring Boot"
      ]
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 1
}
```
