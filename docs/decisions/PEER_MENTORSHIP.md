# Peer Mentorship Lifecycle Decisions

## Decision

Mentorship is a finite series with authoritative dated occurrences. One current enrollment covers
the remaining meetings that have not started. Schedule values use Asia/Dhaka local time and
lifecycle audit timestamps use UTC through the injected `Clock`.

Recurring requests use the existing `WEEKLY` or `BIWEEKLY` products and are bounded by either an
end date or a meeting count of 1–52. Legacy recurring rows already produced at most 12 meetings,
whether or not an end date was stored; V26 preserves that established cap while materializing the
same dates. An unbounded legacy row is recorded as `meeting_count = 12`. The migration does not
invent an end date or reinterpret stored local times.

## Lifecycle model

- `enrollment_open` records explicit open/closed enrollment. `FULL` is calculated from active
  enrollment and capacity. Completion is calculated from occurrence time.
- Leave ends one participation period; rejoin inserts a new period. A nullable active marker plus a
  unique constraint permits history while enforcing one active user/series enrollment.
- Closing does not cancel meetings or complete the series. Reopening requires a future occurrence
  and vacancy. Mentor availability blocks new join/rejoin but never cancels or silently reopens a
  series.
- Cancelling a series marks only not-yet-started occurrences cancelled and retains earlier and
  ongoing occurrences plus participation history.

## Conflict and concurrency model

Hosted occurrence overlap uses half-open intervals, so adjacent meetings are valid. Series create
and edit lock the host mentor before checking every proposed occurrence. Join/rejoin checks only
future meetings hosted by the applicant and locks an applicant mentor profile when one exists.
Series mutations take a pessimistic series lock; the database uniqueness constraint is the final
guard against duplicate active enrollment.

Occurrence starts are not made unique by V26: V11 permitted duplicate legacy dates, and the forward
migration preserves every such row and identifier. Host/series locking prevents new service writes
from racing; schedule reconciliation retains every matching legacy row and only removes future rows
whose complete start/end window is changed.

## Privacy model

Meeting links are mapped into DTOs only for the host or a current participant while an ongoing or
future occurrence remains. The host alone can retrieve a roster. Participants can retrieve only
their own private enrollment details and history. Historical participation does not reveal a link,
and there is no administrator bypass.

## Deferred scope

Cross-module search, complete account anonymization, a dedicated notification-target resolver,
attendance, per-meeting enrollment, schedulers, recommendations, and advanced calendar features
remain outside this correction.
