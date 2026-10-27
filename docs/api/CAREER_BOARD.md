# Career Board Backend API

The agreed Career Board backend scope, including CAREER_POST reporting, is
complete. Frontend integration and confirmed integration fixes remain. Flutter
screens, notifications, administrative removal, reopening, author deletion, and
internal applications are outside this phase.

All endpoints require `Authorization: Bearer <access-token>` and return `Cache-Control: no-store`.
Pagination uses `page` 0–100000 and `size` 1–50.

## Time and lifecycle

- `applicationDeadline` is a calendar date in `Asia/Dhaka`.
- A `PUBLISHED` post is active through the complete deadline date and expires at the start of the following
  local day.
- `EXPIRED` is derived and returned by the API; it is not persisted or applied by a scheduler.
- Persisted timestamps are UTC `LocalDateTime` values under the repository's existing UTC convention.
- Stored statuses are `PUBLISHED`, `CLOSED`, and `REMOVED`.
- An author can close a post permanently. Reopening and author deletion are unavailable.

## Post request

`POST /api/v1/career/posts` and `PUT /api/v1/career/posts/{postId}` use:

```json
{
  "title": "Backend Engineer",
  "companyName": "Example Ltd",
  "description": "Build reliable services",
  "qualifications": "Java and SQL experience",
  "location": "Dhaka",
  "employmentType": "FULL_TIME",
  "workMode": "HYBRID",
  "salaryRange": "BDT 80k-120k",
  "applicationUrl": "https://jobs.example.test/backend",
  "applicationEmail": "careers@example.test",
  "applicationDeadline": "2026-11-30",
  "skills": [
    {"name": "Java", "required": true}
  ]
}
```

Required fields are `title`, `companyName`, `description`, `qualifications`, `employmentType`, `workMode`,
`applicationDeadline`, and `skills`. At least one application URL or email is required. URLs must be absolute
HTTPS URLs without embedded credentials. Skill names are whitespace-normalized, case-normalized, and unique
within the post.

## Alumni author endpoints

| Method and path | Result |
| --- | --- |
| `POST /api/v1/career/posts` | ACTIVE ALUMNI publishes a post; `201` with `CareerPostResponse`. |
| `GET /api/v1/career/posts/mine?page=0&size=20` | Lists the ACTIVE ALUMNI author's published, derived-expired and closed posts. |
| `PUT /api/v1/career/posts/{postId}` | Author replaces permitted fields while the post is `PUBLISHED` and not expired. |
| `POST /api/v1/career/posts/{postId}/close` | Permanently closes the author's post. Identical retries return the existing closed representation. |

Non-owners receive 404 for author-owned resources so ownership is not disclosed.

## Browsing and student endpoints

| Method and path | Result |
| --- | --- |
| `GET /api/v1/career/posts` | ACTIVE STUDENT or ALUMNI browses active posts. |
| `GET /api/v1/career/posts/{postId}` | Students read active or their saved closed/expired posts; alumni read active posts or their own closed/expired posts. |
| `POST /api/v1/career/posts/{postId}/save` | Saves an active post; optional body is `{"note":"..."}`. |
| `DELETE /api/v1/career/posts/{postId}/save` | Deletes only the student's bookmark; returns `204`. |
| `GET /api/v1/career/saved` | Lists bookmarks, including closed and expired posts. |
| `PATCH /api/v1/career/saved/{savedJobId}` | Replaces the bookmark's optional note with `{"note":"..."}`. |
| `GET /api/v1/career/posts/{postId}/apply` | Revalidates activity and returns a `302` external redirect. |

Alumni use the same browse filters, then switch to `/posts/mine` for their complete author history. Alumni responses set `canApply=false`; saving and external application actions remain student-only. This follows the approved role-dashboard change on 27 October 2026, extending the earlier student-only browsing baseline.

Browse filters combine with AND:

- `employmentType`: `INTERNSHIP`, `PART_TIME`, `FULL_TIME`, or `CONTRACT`
- `workMode`: `ONSITE`, `REMOTE`, or `HYBRID`
- `location`: case-insensitive contains match
- `skill`: normalized exact skill match
- `sort`: `POSTED_AT_DESC` (default) or `DEADLINE_ASC`

`/apply` accepts optional `channel=URL|EMAIL`. If exactly one channel exists it is inferred. If both exist,
the caller must select one. URL redirects use the stored HTTPS URL; email redirects use `mailto:`. The backend
does not fetch the destination and creates no application or applicant record.

## Response and privacy behavior

`CareerPostResponse.status` is one of `PUBLISHED`, `EXPIRED`, `CLOSED`, `REMOVED`, or `UNAVAILABLE`.
`canApply` is authoritative for the returned instant and `/apply` rechecks it transactionally.

- Suspension prevents the author from authenticating or changing posts but does not silently hide an already
  published post. Content removal is a separate future moderation action.
- Career's anonymization hook marks the author's posts unavailable, removes application URL/email, hides them
  from active browsing, and preserves bookmarks and non-application historical content with `Former User`.
  Stable author IDs are not returned for anonymized posts.
- A removed saved post is a tombstone: only the post ID, `REMOVED` status, bookmark metadata, and empty safe
  collections remain. Title, company, body, author, deadline, timestamps, skills, and application data are null
  or empty.
- Closed and expired saved posts retain their content and configured application method for review, but
  `canApply=false` and `/apply` rejects them.

## Content reporting

The separate report submission route accepts `targetType=CAREER_POST` from any
authenticated ACTIVE user who can open the post through Career's ordinary detail
rules. Active posts are reportable without requiring Student, save, apply, edit,
or author authority. An author or a Student with an existing save may also report
the retained closed/expired post they can open. Removed, missing, and inaccessible
posts use the canonical 404.

The immutable snapshot contains only ordinary visible post detail and captures
the author as owner. It excludes bookmark state and private saved-job notes.
ACTION_TAKEN may link only an existing unreversed suspension of that captured
author; reporting adds no administrator career-post removal power.

## Errors

Every error uses the shared `ApiError` contract.

| HTTP | Important codes |
| --- | --- |
| 400 | `VALIDATION_FAILED`, `INVALID_CAREER_REQUEST`, `INVALID_APPLICATION_URL`, `APPLICATION_CHANNEL_REQUIRED`, `INVALID_APPLICATION_CHANNEL`, `INVALID_PAGE`, `INVALID_PARAMETER` |
| 401 | `INVALID_SESSION` |
| 403 | `ACCESS_DENIED` |
| 404 | `RESOURCE_NOT_FOUND` |
| 409 | `INVALID_JOB_POST_STATE`, `DUPLICATE_SAVED_JOB` |

The database unique constraint on `(student_user_id, job_post_id)` is authoritative for concurrent duplicate
saves. Post mutations use row locks after the actor account/session lock.
