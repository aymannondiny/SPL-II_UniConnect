# Account moderation decisions

- Scope is backend account search/details, suspension/restoration, retained audit,
  notifications, session invalidation, and the required club publishing effect.
  Account removal/anonymization, warnings, and Flutter administration screens are
  excluded. The reporting module may verify retained suspension evidence through
  this service, but it never executes account moderation during resolution.
- The actor must be an ACTIVE, non-anonymized SYSTEM_ADMIN with a current session
  and SYSTEM_ADMINISTRATION selected. Eligible targets are non-anonymized STUDENT
  or ALUMNI accounts. SYSTEM_ADMIN targets, including self, are excluded.
- Suspension and restoration both require confirmation and a retained reason.
  Authorized repeated requests in the desired state are no-ops, producing no new
  action, audit, or notification.
- `ModerationAction` records the actor, target, reason, state transition, time, and
  optional reversal time. Its one-to-one immutable `AuditLog` is the admin-only
  event history. The reversal timestamp is additive metadata; no audit row is
  rewritten or deleted. Notifications contain generic text and never the reason.
- Account state change, all-session revocation, automatic club suspension, audit,
  and durable notifications share one transaction. Socket closure is an
  AFTER_COMMIT event, so rollback cannot disconnect a client. Authorization still
  rejects revoked sessions independently of delivery of that event.
- Suspension uses discover clubs, lock clubs by ID, lock involved accounts by ID,
  fresh assignment recheck, then sessions. An added club causes rollback and a
  bounded fresh-transaction retry. Assignment replacement uses the same locks and
  rechecks eligibility under them.
- Account restoration never revives sessions or restores club publishing.
  Reactivating the original administrator may satisfy FR_70/FR_83 administrator
  eligibility, but an authorized system administrator must explicitly use the
  existing publishing-restoration endpoint.
- Existing club notification recipients remain unchanged: the current club
  administrator receives publishing lifecycle notifications. The affected account
  separately receives its generic account-status notification.
- V14 adds the approved account moderation/audit tables and extends notification
  constraints. Applied V1-V13 remain unchanged.
