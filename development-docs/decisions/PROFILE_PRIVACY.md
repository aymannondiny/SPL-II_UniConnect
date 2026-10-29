# Profile discovery and privacy decision

Accepted by the project owner on 2026-10-08. Applies to FR_9, FR_76 and
profile-dependent discovery in the corrected requirements baseline.

- All ACTIVE members can discover basic personal profile fields: name, role,
  photo, department and programme.
- Additional profile details use ALL_MEMBERS or CONNECTIONS_ONLY visibility.
- CONNECTIONS_ONLY is the initial/default value for both new and existing profiles.
- Email and student number are private; they are never included in cross-user DTOs.
- Only accepted connections unlock restricted details. Pending or closed requests do not.
- Privacy applies to search predicates/counts, not just response serialization.
- Suspended/anonymized accounts are excluded from discovery.
- SYSTEM_ADMIN does not bypass detail visibility in ordinary member discovery.

Implementation and endpoint walkthrough: [Discovery and connections](../api/DISCOVERY_CONNECTIONS.md).
