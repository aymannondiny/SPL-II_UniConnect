# Content reporting decisions

- This phase is backend-only. Reporter and administration Flutter screens remain
  separate work.
- Supported targets are USER, CLUB, ANNOUNCEMENT, EVENT, and CHAT_MESSAGE.
  PROJECT and CAREER_POST are deferred until their owning modules and access
  contracts exist; no placeholder entity or polymorphic fake is introduced.
- Any ACTIVE, non-anonymized authenticated user may submit regardless of selected
  context. Target access is delegated to the owning module, and inaccessible and
  nonexistent targets both produce 404.
- The immutable snapshot contains only target-specific evidence the reporter could
  access. Delete-for-everyone chat text may be retained for administrators;
  reporter DTOs never expose any snapshot.
- The lifecycle is SUBMITTED, UNDER_REVIEW, then ACTION_TAKEN or NO_ACTION. The
  first reviewer owns resolution. Database row locks serialize claims and terminal
  decisions.
- One open report is allowed per reporter and target. The database unique key is
  nullable after resolution, allowing a later report and independent reporters.
- Report resolution is evidence linking, not action execution. Existing account,
  club, and publication services validate their own committed audit records.
  Existing permissions remain authoritative for executing those actions.
- ACTION_TAKEN accepts only the approved target/action matrix. Current target
  status is never sufficient. Reversed evidence is rejected when resolving, while
  the copied action link remains historical if an action is reversed later.
- Resolution and reversal serialize on the referenced account action or club
  suspension audit row. Reversal retains its existing account/club lock order and
  takes the evidence-row lock last, avoiding a new moderation/report lock cycle.
- Identical retries are no-ops; conflicting terminal retries are 409. Resolution,
  audit, action link, and the generic REPORT_RESOLVED notification are atomic.
- Warnings, administrator chat hiding, new publication-removal permissions,
  project/career targets, and generalized cross-module moderation are deferred.
