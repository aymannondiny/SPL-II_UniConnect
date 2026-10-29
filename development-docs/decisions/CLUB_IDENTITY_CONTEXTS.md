# Club identity and session contexts

Scope: club creation, administrator replacement, representative assignments, club directory, session dashboard contexts, access notifications, and operator audit history. Announcements/events and account/club lifecycle endpoints are deferred.

- `revokedAt IS NULL` is the only definition of a current assignment; there is no expiry. Nullable unique current-role keys enforce one current role per user/club and at most one administrator per club/student in PostgreSQL and H2.
- Exactly one administrator is maintained by atomic creation/replacement services. The database enforces at most one; arbitrary direct SQL must not be used to mutate assignments.
- Existing representative promotion creates a new administrator assignment after revocation, preserving authorship references for future announcements.
- Club profiles remain visible during PUBLISHING_SUSPENDED. REMOVED clubs are excluded. These status values are reserved for the later lifecycle module; this patch exposes no status-changing endpoint.
- Selected dashboard context is session state, not a source of authority. Every management action validates current account status, assignment ownership/current role, club ID, and selected context. Existing personal/chat APIs retain their permissions.
- Revocation clears selections referencing the assignment across all sessions in the same transaction. Refresh retains context; a new login defaults to PERSONAL. A stale/unavailable selection falls back to PERSONAL when contexts are read.
- Lock order: existing club row, all involved account rows in ascending user ID, then sessions. Club creation has no pre-existing club row and locks accounts before insertion. Account locks serialize assignments across different clubs. Context switching follows this same order. Future lifecycle services must preserve this order; do not lock an account and then an existing club.
- Future suspension/anonymization integration must also suspend publishing for a club whose administrator becomes ineligible, according to the approved lifecycle rules. Current club actions already reject ineligible actors and assignees, but this module does not implement account lifecycle transitions.
- Audit entities are immutable through the application and retained with actor, acting assignment, target assignment, action, reason, and timestamp. Grant/revoke records and retained assignments capture the transition history. This is not a database-level tamper-proof audit store.
- Notifications, audit, role changes, and context invalidation share one transaction. Unique recipient/event keys prevent duplicate grant/revoke notifications.
- V9 is a Java Flyway migration because V7's unnamed notification CHECK constraints have database-generated names. It locates exactly the two original enum checks and replaces them without touching rows. V10 adds clubs, assignments, audit, and session context columns. Existing migration files are unchanged.

Verification includes service/HTTP permission boundaries, inactive assignees, rollback, concurrent assignment/context revocation, session refresh/isolation, and upgrade from V8 with existing notification/session data. Run the full backend suite on Java 21 before merging. PostgreSQL/Neon migration smoke testing remains necessary in the development environment.
