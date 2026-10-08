# Personal profiles and administrator-managed academic catalog

Backend implementation of profile creation/editing in FR_6, FR_7, FR_8 and availability persistence in FR_75. Academic catalog administration is the confirmed project decision: system administrators maintain Department → Programme → ProgrammeDegree. No university catalog or administrator credentials are seeded.

This phase provides **owner-only** profile APIs. FR_9 cross-user profile viewing, privacy controls, connection indicators, FR_76 alumni discovery, availability filtering in discovery, club contexts, frontend screens, and file upload remain separate work. Do not expose the owner response as a public profile response.

## Authentication and ownership

All routes require a valid access token. Only an ACTIVE, non-anonymized SYSTEM_ADMIN can manage the catalog. Profile type must match the current canonical PlatformRole: STUDENT or ALUMNI. SYSTEM_ADMIN has no personal-profile subtype.

The authenticated principal determines the owner; request bodies contain no user ID, email, role, or account status. Services recheck the session and current account under the owning user lock through Authentication's ProfileAccountService. Profile never accesses Authentication repositories. The current role is read from the database, not trusted from a passed principal. Pending, suspended, anonymized, expired, and revoked credentials fail existing authentication rules.

## Academic catalog API

| Method | Path | Result |
|---|---|---|
| GET | `/api/v1/profile/academic-options` | 200; departments, programmes, active degrees |
| GET | `/api/v1/admin/academics` | 200; complete catalog, including inactive degrees |
| POST | `/api/v1/admin/academics/departments` | 201; created department |
| PUT | `/api/v1/admin/academics/departments/{id}` | 200; renamed department |
| POST | `/api/v1/admin/academics/programmes` | 201; created programme |
| PUT | `/api/v1/admin/academics/programmes/{id}` | 200; renamed programme |
| POST | `/api/v1/admin/academics/degrees` | 201; created degree option |
| PUT | `/api/v1/admin/academics/degrees/{id}` | 200; revised rules/active flag |

Department body:

```json
{"name":"Computer Science and Engineering","code":"CSE"}
```

Programme body (replace the example ID with the department response ID):

```json
{"name":"Software Engineering","code":"SWE","departmentId":1}
```

Degree body (replace programmeId with its response ID):

```json
{"programmeId":1,"degreeLevel":"BACHELOR","durationYears":4,"minimumYear":1,"maximumYear":4,"active":true}
```

These are illustrative inputs, not an authoritative IUT catalog. DegreeLevel values are DIPLOMA, BACHELOR, MASTER, DOCTORATE. Duration and year limits are integers from 1 to 20; minimum cannot exceed maximum. Administrators must enter the university's approved offerings and valid study-year ranges. Department/programme codes are globally unique within their table, normalized to uppercase, and contain 1–30 letters, digits, underscores, or hyphens. Names allow 150 characters. A programme has one option per degree level.

Parents and degree level are immutable after creation. Rename a department/programme without changing its ID. Create another option for a different hierarchy/level. Degree rules can change only while no profile uses the option. Deactivation is always allowed and does not delete history: new selections must be active, but existing profiles may retain and edit their current inactive option. Reactivation restores it to the selection list. No DELETE routes are exposed.

An authenticated list can include departments/programmes without an active degree; clients must only offer degree IDs present in its `degrees` list. Owner profile responses contain their current academic labels and degree state even if that degree is inactive.

## Personal profile API

| Method | Path | Result |
|---|---|---|
| GET | `/api/v1/profile/me` | 200 profile, or 404 if none exists |
| PUT | `/api/v1/profile/me/student` | 200; create or replace editable Student fields |
| PUT | `/api/v1/profile/me/alumni` | 200; create or replace editable Alumni fields |
| PATCH | `/api/v1/profile/me/availability` | 200; update both Student preferences |

PUT is a complete replacement of editable fields. Supply required fields and skill/interest arrays every time; optional fields omitted or blank become null, and empty arrays clear the corresponding associations. Creation and update both return 200; profile ID and createdAt remain stable on update. Last committed edit wins; there is no client version/ETag contract in this phase.

Student example:

```json
{
  "fullName":"Example Student",
  "programmeDegreeId":1,
  "bio":"Interested in backend development",
  "profilePhotoUrl":null,
  "skills":["Java","SQL"],
  "interests":["Robotics"],
  "studentNumber":"230042141",
  "yearOfStudy":2,
  "expectedGraduationYear":2029,
  "projectAvailability":true,
  "mentorshipAvailability":false
}
```

Alumni example:

```json
{
  "fullName":"Example Alumni",
  "programmeDegreeId":1,
  "bio":null,
  "profilePhotoUrl":null,
  "skills":["Software Engineering"],
  "interests":[],
  "graduationYear":2024,
  "currentCompany":"Example company",
  "currentPosition":"Software Engineer",
  "industry":"Software",
  "careerBackground":null,
  "linkedinUrl":"https://www.linkedin.com/in/example"
}
```

The programme represents the academic major; department comes from that programme. Clients cannot submit contradictory department/major values. Full name updates the canonical User atomically with the profile, so `/api/v1/auth/me` reflects the same name. Email, role, and account status are unchanged.

Validation choices:

- Full name: required, trimmed, at most 100 characters.
- Student number: required and unique, 1–40 letters/digits/hyphens, normalized to uppercase. It is owner-only data, not a public identifier.
- Study year: within the selected degree's configured inclusive range.
- Expected graduation: optional, 1900–2200 and not before the current UTC year. Alumni graduation: required, 1900–current UTC year, capped at 2200.
- Skills/interests: at most 30 submitted entries each, 1–60 characters per entry. Trim, collapse whitespace, lowercase, and deduplicate. Shared canonical vocabulary is created on first use; category is optional and unset in this phase.
- Bio/career background: at most 2000 characters; company/position 150; industry 100.
- URLs: optional, at most 2048 characters, absolute HTTP(S), no embedded credentials. LinkedIn URL must use linkedin.com or a subdomain. URLs are stored only; the backend does not fetch them. Clients must render profile text safely, not as trusted HTML. Photo upload/storage is not implemented.

Availability body:

```json
{"projectAvailability":false,"mentorshipAvailability":true}
```

This changes only preferences and updatedAt; it requires an existing Student profile.

Responses contain academic labels, skills/interests, timestamps, and role-specific details (`student` or `alumni`). They contain no email, password hash, credentials, or JPA objects. Owner reads and profile writes use `Cache-Control: no-store`.

## Persistence and errors

Flyway V6 owns the academic catalog, canonical skill/interest vocabulary, and personal profiles. PersonalProfile is abstract with StudentProfile/AlumniProfile subclasses, persisted with JPA single-table inheritance. The database enforces one profile per user, unique student number, unique catalog codes/options, role-specific field presence, and foreign keys. Matching profile type to current User role is a service invariant; any future role-conversion workflow must migrate the profile atomically.

Services own transactions. Writes lock the account, then degree option, so deactivation/range updates serialize with degree selection. Name, profile, associations and new vocabulary are committed or rolled back together. Concurrent first use of the same vocabulary name across different degrees may produce a unique-constraint conflict; retry the request after reloading. A user's concurrent profile PUTs serialize and keep one profile.

ApiError is preserved:

- 400 `VALIDATION_FAILED`, `MALFORMED_REQUEST`, `INVALID_PROFILE_URL`, `INVALID_STUDY_YEAR`, `INVALID_GRADUATION_YEAR`, `INVALID_STUDY_YEAR_RANGE`, `INACTIVE_ACADEMIC_OPTION`.
- 401 existing authentication/session errors.
- 403 `ACCESS_DENIED` for role restrictions.
- 404 `RESOURCE_NOT_FOUND` for missing profile or academic entry.
- 409 `ACADEMIC_PARENT_IMMUTABLE`, `ACADEMIC_OPTION_IN_USE`, `PROFILE_TYPE_CONFLICT` for lifecycle conflicts.
- 409 `PROFILE_DATA_CONFLICT` for database integrity conflicts, including duplicate student number/catalog code or concurrent vocabulary creation. Responses do not reveal the other owner's identity or submitted values.

The profile tables are ready to be erased by the future account-anonymization transaction, including join rows. This change does not implement an anonymization endpoint or automatic cleanup.

## Manual verification

1. Run `./mvnw clean verify`; start the dev backend with your existing environment. Verify Flyway applies V6.
2. Use a dedicated verified SYSTEM_ADMIN test account. There is no public admin registration or default admin password. Initial provisioning must be performed by a trusted database operator using the existing canonical User; never add a public role-promotion endpoint for testing.
3. Log in and Authorize in Swagger; create a department, programme, and degree, keeping returned IDs.
4. Log in as an ACTIVE STUDENT. Catalog writes must return 403. Read academic-options and create a Student profile using the degree ID. Read it, update it, then PATCH availability. Confirm `/auth/me` shows any changed name.
5. Log in as another Student: `/profile/me` must show only their profile or 404. Reusing the first Student's studentNumber must return 409.
6. Log in as ACTIVE ALUMNI: create an Alumni profile. Calling the Student PUT must return 403. Invalid LinkedIn host or future graduation year must return 400.
7. As administrator, deactivate the degree. It disappears from active options; existing owners can retain it, while new selection fails with 400. Changing an in-use degree's study-year range returns 409.

Automated tests use H2 in PostgreSQL mode and mock the clock. Validate migration and locking behavior on development PostgreSQL as well. No real university data or privileged account is created by the tests.
