# Club lifecycle decisions

Implements FR_70, FR_71 and FR_83 using the existing modular MVC club boundary.

- ClubLifecycleService owns transactions, authority checks and lifecycle orchestration.
  Controllers return DTOs; cross-module account/session/notification access uses services.
- Lock order is club, all involved accounts by ascending ID, then session. Publication,
  replacement, revocation and context selection already use this order. Concurrent
  duplicate transitions serialize and create one audit/notification.
- Removal revokes all current assignments while preserving rows, author references,
  personal sessions and other clubs. This releases current-role uniqueness keys and
  prevents stale club contexts from being selected again.
- Suspend/restore leave assignments intact. Restoration requires an eligible current
  student administrator. A reactivated original administrator can satisfy eligibility,
  but account restoration never changes club state; publishing restoration remains an
  explicit system-administration action. Account suspension automatically suspends
  ACTIVE clubs currently administered by the target and preserves assignments.
- Existing ClubAudit is extended with previous/new state and a nullable assignment
  target. SQL constrains valid lifecycle transitions separately from authority events.
  The typed clubId is always required. A general multi-target ModerationAction model
  remains the club-owned history; account moderation uses its approved dedicated
  ModerationAction and AuditLog records without replacing club lifecycle audits.
- Audits are append-only through the application (@Immutable, no mutation endpoints).
  This does not prevent privileged database administrators from modifying rows.
- Notification recipient policy: current administrator for suspend/restore; existing
  role-revocation notifications for every assignment revoked on removal. Event keys
  use the lifecycle audit ID, permitting subsequent distinct suspend/restore cycles.
- Java V13 discovers V10's unnamed action constraint by its definition (as V9 did
  for notification checks). It preserves old rows, adds state-shape checks and extends
  notification checks. Applied V1-V12 are not rewritten.
- Removed metadata and club audit remain system-admin-readable. Public and operator
  access stay hidden. Publication history is retained for later moderation tooling.
