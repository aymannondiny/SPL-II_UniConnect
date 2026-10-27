# UniConnect presentation walkthrough

All listed accounts use `Seed!234`. Pending actions are intentionally left
unconsumed so each can be demonstrated live.

| Account | Screen | Expected presentation |
| --- | --- | --- |
| `ayman@iut-dhaka.edu` | Administration → Reports / Club requests | SYSTEM_ADMINISTRATION context, ten varied report scenarios, two pending club requests |
| `sayma@iut-dhaka.edu` | Administration → Reports | Second ACTIVE administrator; suitable for a separate review session without sharing Ayman's session |
| `pres.farhan.rahman@iut-dhaka.edu` | Project Finder → My projects → Campus Services API | Open backend project; recommendations rank Abdullah 86.97, Tasnim 48.79, Nusrat 44.85; one pending applicant remains for review |
| `pres.abdullah.mamun@iut-dhaka.edu` | Members / Project Finder | Strong backend recommendation, accepted student connection with Farhan |
| `pres.tasnim.ahmed@iut-dhaka.edu` | Mentorship → My Mentorship | Enrolled in Backend Design Clinic and can see its meeting link; partial project recommendation match |
| `pres.nusrat.jahan@iut-dhaka.edu` | Mentorship → Hosting | Fourth-year student mentor, SQL clinic history, cancelled API group, accepted student–alumni connection |
| `pres.mahmud.hasan@iut-dhaka.edu` | Projects / Mentorship → Hosting | Accessible Campus Navigator owner and full Flutter Testing Workshop host |
| `pres.zubair.ahmed@iut-dhaka.edu` | Chat / Clubs / Mentorship | Unread club-planning conversation, Innovation Society representative context, Flutter workshop enrolment |
| `pres.sadia.afrin@iut-dhaka.edu` | Clubs → Innovation Society | Club administrator context, published/draft announcements and upcoming/active/past events |
| `pres.mariam.akter@iut-dhaka.edu` | Connections | Outgoing pending request to Farhan, suitable for cancellation demonstration if desired |
| `pres.farhan.rahman@iut-dhaka.edu` | Connections | Incoming pending request from Mariam, suitable for accept/reject demonstration |
| `pres.nabila.sultana@iut-dhaka.edu` | Reports / Connections | Own submitted, under-review, and action-taken outcomes; outgoing pending request to Sadia |
| `pres.arif.hossain@iut-dhaka.edu` | Career Board | Saved Product Intern post and pending student–alumni connection to Sabrina |
| `pres.sumaiya.noor@iut-dhaka.edu` | Projects / Career Board | Pending backend-project application, saved data role, closed ML mentorship enrolment |
| `pres.rayhan.kabir@iut-dhaka.edu` | Projects → Applied | Rejected embedded-project application retained as history |
| `pres.tahmid.hassan@iut-dhaka.edu` | Projects → Applied / Mentorship | Accepted mobile-project member; full Flutter workshop enrolment |
| `pres.jannat.ferdous@iut-dhaka.edu` | Projects → Applied | Pending sustainability-project application |
| `pres.fatima.zahra@iut-dhaka.edu` | Member profile | CONNECTIONS_ONLY privacy comparison; non-connected viewers see restricted details |
| `pres.rukaiya.islam@iut-dhaka.edu` | Member profile | Second CONNECTIONS_ONLY profile for privacy comparison |
| `pres.hamza.chowdhury@iut-dhaka.edu` | Member discovery | Suitable non-connected outsider for meeting-link and profile-privacy comparisons |
| `pres.ahmed.faisal@iut-dhaka.edu` | Mentorship / Chat / Career Board | Alumni backend mentor, natural mentoring chat, fictional backend internship author |
| `pres.sabrina.haque@iut-dhaka.edu` | Chat / Career Board | Alumni product mentor, student internship-advice chat, fictional product internship author |
| `pres.khadija.noor@iut-dhaka.edu` | Mentorship / Career Board | Alumni data mentor, closed ML review series, active data-role author |
| `pres.mohammad.rafiq@iut-dhaka.edu` | Mentorship / Chat / Career Board | Unavailable alumni mentor, mobile-project conversation, naturally expired Flutter internship |

Other catalogue accounts cover web, algorithms, robotics, embedded systems,
energy, manufacturing, civil engineering, data analysis, club events and alumni
connections. See the CSV catalogue for their exact role, programme/year and purpose.

## Reporting and moderation walkthrough

Select `SYSTEM_ADMINISTRATION` after administrator login. Reporter endpoints show
only the safe outcome fields; target snapshots, reviewer ownership, internal notes,
evidence links, and audit history are visible only in the administrator contract.

| Reporter login | Administrator | Target and mild fictional reason | Current state | Safe live demonstration |
| --- | --- | --- | --- | --- |
| `pres.nabila.sultana@iut-dhaka.edu` | Ayman | Project: **Campus Services API** — fictional description review | `SUBMITTED` | Ayman can claim it for review; leave unresolved if the submitted example is still needed |
| `pres.nabila.sultana@iut-dhaka.edu` | Sayma | Career post: **Graduate Software Engineer** — fictional closed-opportunity review | `UNDER_REVIEW` | Sayma can resolve `NO_ACTION`; she already owns the review |
| `pres.mariam.akter@iut-dhaka.edu` | Ayman or Sayma | User: **Rayhan Kabir** — repeated unrelated project promotion | `SUBMITTED` | Either administrator can claim it for review |
| `pres.hafsa.mahjabin@iut-dhaka.edu` | Ayman | Club: **UniConnect Robotics Circle** — repetitive promotional wording | `UNDER_REVIEW` | Ayman can dismiss it with `NO_ACTION`; he already owns the review |
| `pres.zubair.ahmed@iut-dhaka.edu` | Ayman or Sayma | Accessible Sadia message in **club-planning** — off-topic follow-up | `SUBMITTED` | Either administrator can claim it; Zubair is a legitimate conversation participant |
| `pres.samira.khan@iut-dhaka.edu` | Sayma | Event: **Open Source Orientation** — outdated participation details | `UNDER_REVIEW` | Sayma can dismiss it or first perform a supported moderation action; she owns the review |
| `pres.nabila.sultana@iut-dhaka.edu` | Ayman | Announcement: **Repeated prototype registration reminder** — duplicate promotion | `ACTION_TAKEN` | Read-only history demo: committed `REMOVED` publication audit is linked as evidence |
| `pres.arif.hossain@iut-dhaka.edu` | Sayma | Event: **Duplicate internship briefing listing** — conflicting duplicate details | `ACTION_TAKEN` | Read-only history demo: committed `REMOVED` publication audit is linked as evidence |
| `pres.aisha.siddika@iut-dhaka.edu` | Sayma | User: **Hamza Chowdhury** — possibly overstated activity participation | `NO_ACTION` | Compare reporter-safe resolution/notification with administrator-only notes; no pending action |
| `pres.jannat.ferdous@iut-dhaka.edu` | Ayman | Club: **UniConnect Career Forum** — allegedly duplicated career wording | `NO_ACTION` | Compare dismissed outcome and ordered audit history; no pending action |

Resolving a pending example is intentionally a real presentation interaction. The
manifest will not reset it on rerun. `ACTION_TAKEN` should be selected only after a
supported moderation action is committed and its real evidence ID is supplied.

Do not demonstrate registration, verification-code resend, password reset, or
external career application redirects with this dataset. The opportunity URLs and
meeting links use reserved `example.test` domains and are illustrative only.
