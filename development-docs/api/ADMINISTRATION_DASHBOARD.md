# Administration dashboard summary

`GET /api/v1/admin/dashboard/summary` returns the four authoritative counts
shown by the Engineering Mode administrator dashboard.

The request requires an active `SYSTEM_ADMIN` session with the
`SYSTEM_ADMINISTRATION` context selected. The response is marked `no-store`.

```json
{
  "totalUsers": 38,
  "activeClubs": 6,
  "publishedPosts": 14,
  "openReports": 3
}
```

Definitions:

- `totalUsers`: every retained account that has not been anonymized, including
  active, suspended, and pending-verification accounts and system
  administrators.
- `activeClubs`: clubs whose lifecycle status is exactly `ACTIVE`.
  Publishing-suspended, archived, and removed clubs are excluded.
- `publishedPosts`: currently visible `PUBLISHED` club announcements plus
  `PUBLISHED` club events belonging to non-archived, non-removed clubs.
  Expired or removed announcements and removed events are excluded. Past
  published events remain available through event history and are included.
- `openReports`: reports in `SUBMITTED` or `UNDER_REVIEW` status.

The frontend treats a numeric zero as a successful authoritative result. It
shows a loading indicator while the request is pending and an explicit retryable
unavailable state for authorization, network, timeout, or malformed-response
failures. It never converts a failed request to zero.
