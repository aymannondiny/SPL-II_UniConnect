# Club publication decisions

- Club-owned implementation is under `club.publication`, retaining the modular MVC
  boundary. It uses the authentication module's public account/session contracts.
- FR20–24 and FR84–90 govern drafts, announcement lifecycle, discovery and event
  history. Anonymous public read access follows the approved "any User" public
  publication rule. Management stays authenticated and context-scoped.
- Exact immutable author assignment IDs prevent rights from returning after
  revoke/regrant. Current administrators can manage all club content. A system
  administrator does not automatically become an author/operator.
- All management transactions lock the club before the actor account, matching
  assignment revocation/replacement. This serializes publishing against authority
  changes. Read-only public queries take no pessimistic write locks.
- Announcements and events are separate entities. Event registration link/deadline
  are optional informational metadata from FR88, not an RSVP subsystem.
- Announcement expiry is derived from stored PUBLISHED state plus expiresAt. Both
  database feed predicates and DTO mapping use the same captured UTC instant.
  EXPIRED is an effective API state, not a persisted state or scheduled job. This
  avoids delayed expiry while keeping public GETs read-only.
- Event timing is also derived, with inclusive start/end. Past events cannot be
  edited, preserving historical details; managers can soft-remove them with a
  reason. Historical backfill is allowed because the baseline only requires end
  after start, not future dates. This is distinct from allowing history edits.
- Suspended clubs retain public content; drafts/new publishing are blocked.
  Existing editable publications may be corrected, unpublished or removed.
- Versioned immutable application audit rows include before/after snapshots.
  Destructive visibility changes require confirmation/reason. There are no audit
  update/delete API routes. Database administrators retain normal database access;
  this is not a database-trigger-enforced tamper-proof logging system.
- Composite foreign keys bind author/actor user, club and assignment together;
  publication/audit foreign keys retain historical relationships. No applied
  V1–V10 migration is modified.
- Transition retries are idempotent; creation is not an idempotent API. A client
  should refresh its management list after an uncertain create response instead
  of blindly retrying. No mass-notification recipient set is invented.
- New SQL is V12. Coordinate mentorship as V11 and merge this migration first;
  never run two different migrations with the same version against shared Neon.
  If a teammate has already applied another V12, reconcile the migration sequence
  before applying this branch rather than changing checksums or enabling out-of-order.
- Flutter screens, subscriptions, announcement push notifications, publication
  WebSockets, club lifecycle, restoration and system moderation remain separate.
