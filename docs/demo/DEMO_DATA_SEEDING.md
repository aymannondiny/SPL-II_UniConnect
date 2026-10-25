# UniConnect complete demo fixture

Based on main `5e5f9959c12fd61279839de1cc34c806c08b2151` (PR #93), schema V26.
This is **opt-in, synthetic local demo data**, outside Flyway and application startup.
It does not change backend source, existing migrations, frontend code, or CI.
It is not a production migration, import tool, or anonymization implementation.

The fixture covers every implemented business module. Authentication verification,
reset and session tables intentionally start empty: no fabricated verification/reset
or session tokens. Pending Student deliberately cannot sign in or verify until you
explicitly exercise normal APIs and configure mail. All URLs use reserved `.test`
examples; every account email ends in `@iut-dhaka.edu`. Those email addresses are
synthetic identifiers, not permission to send email to real university mailboxes.
Keep SMTP at **127.0.0.1:1**, with no real mail credentials, throughout demo use.

## Files

- `scripts/demo-seed/seed.sh`: explicit loopback apply/verify command.
- `scripts/demo-seed/seed.sql`: one transactional seed, schema and empty-data guards.
- `scripts/demo-seed/checks.sql`: 66 fail-fast pristine-fixture assertions.
- `scripts/demo-seed/verify.sql`: read-only SQL verification and non-secret inventory.
- `scripts/demo-seed/accounts.csv`: account IDs/emails/roles/statuses, no hashes/tokens.
- `scripts/demo-seed/verify-api.py`: optional localhost API acceptance checks (Python standard library).
- This guide: setup, exact fixture IDs, expected behavior, reset and contribution handoff.

## Apply the patch

Run from a clean checkout of current main. The patch only adds the listed files.
If a file already exists, review the collision; do not use `--reject` or overwrite it.

```bash
git switch main
git pull --ff-only origin main
git status --short
git switch -c chore/demo-data-seeding
git apply --check /path/to/uniconnect-demo-seed.patch
git apply /path/to/uniconnect-demo-seed.patch
git diff --check
```

`git apply` creates the files; it does not insert database data. Your teammate
should review the fixtures, run both verification steps, and make any necessary
corrections before committing the contribution. Record the fixture design, review
and verification work accurately in the commit and PR description.

## Prepare a NEW local database

Use PostgreSQL 16+ and Java 21 with the repository Maven wrapper. The commands below
create a fresh cluster instead of reusing any older Swagger databases. The example
ports are PostgreSQL **55445**, backend **18084**. Check both before proceeding:

```bash
ss -ltnp 'sport = :55445'
ss -ltnp 'sport = :18084'
```

If either is occupied, leave it alone and choose another unused local port; adjust
all commands consistently. Run PostgreSQL commands as your normal user, not root.
`pg_config --bindir` must refer to the PostgreSQL server installation; on the
original Kali setup `/usr/lib/postgresql/18/bin` also works.

```bash
pg_bin="$(pg_config --bindir)"
demo_dir="$(mktemp -d /tmp/uniconnect-demo.XXXXXXXX)"
echo "Keep this cleanup path: $demo_dir"
"$pg_bin/initdb" -D "$demo_dir/data" --username=uniconnect_demo   --auth-local=trust --auth-host=trust --encoding=UTF8
"$pg_bin/pg_ctl" -D "$demo_dir/data" -l "$demo_dir/postgres.log"   -o "-h 127.0.0.1 -p 55445 -k $demo_dir" start
"$pg_bin/createdb" -h 127.0.0.1 -p 55445 -U uniconnect_demo uniconnect_demo
```

Trust authentication is limited to this fresh loopback-only demo cluster. Never
copy that authentication configuration onto an existing/shared server.

Build the backend and apply migrations through normal Spring Boot startup:

```bash
cd code/backend
./mvnw -DskipTests package
cd ../..
java -jar code/backend/target/backend-0.0.1-SNAPSHOT.jar   --spring.profiles.active=dev   --server.address=127.0.0.1 --server.port=18084   --spring.datasource.url=jdbc:postgresql://127.0.0.1:55445/uniconnect_demo   --spring.datasource.username=uniconnect_demo --spring.datasource.password=   --spring.flyway.url=jdbc:postgresql://127.0.0.1:55445/uniconnect_demo   --spring.flyway.user=uniconnect_demo --spring.flyway.password=   --spring.mail.host=127.0.0.1 --spring.mail.port=1   --spring.mail.username= --spring.mail.password=   --spring.mail.properties.mail.smtp.auth=false   --spring.mail.properties.mail.smtp.starttls.enable=false
```

Wait for successful migration/startup through **V26**, then press **Ctrl+C** in this
backend terminal. Keep PostgreSQL running. Do not seed while the application is
serving requests. From the repository root, install and verify the fixture:

```bash
bash scripts/demo-seed/seed.sh apply 55445 uniconnect_demo uniconnect_demo
bash scripts/demo-seed/seed.sh verify 55445 uniconnect_demo uniconnect_demo
```

Both commands must exit successfully. The script refuses non-loopback PostgreSQL,
other database names, populated application tables, unsuccessful or unsupported
migration history, or an inconsistent fixture. V1's `application_metadata` row is
expected and preserved. It creates just one demo-only metadata table recording
seed version, seed time, base date and a fingerprint. All fixture inserts and
identity-sequence restarts share a transaction; assertion failures roll it back.
`psql` stops at the first SQL error. No existing rows are deleted or updated.

Reapplying to an **unchanged pristine** fixture is a no-op. After logins or manual
changes it deliberately refuses to reseed instead of overwriting those changes.
Read-only pristine verification must also be run before logins/API smoke, because
session rows are expected to be empty. Identity sequences advance beyond explicit
fixture IDs so subsequent normal API creation can continue safely.

Restart the backend with the same Java command. Open:

- Swagger: <http://127.0.0.1:18084/swagger-ui/index.html>
- OpenAPI: <http://127.0.0.1:18084/v3/api-docs>

All ACTIVE accounts use the demo-only password **`LocalOnly!234`**.

## Accounts

| User ID | Simple name | Email | Platform role | Account status |
| ---: | --- | --- | --- | --- |
| 1 | System Admin | `system.admin@iut-dhaka.edu` | SYSTEM_ADMIN | ACTIVE |
| 2 | Project Creator | `project.creator@iut-dhaka.edu` | STUDENT | ACTIVE |
| 3 | Complete Match | `complete.match@iut-dhaka.edu` | STUDENT | ACTIVE |
| 4 | Connected Match | `connected.match@iut-dhaka.edu` | STUDENT | ACTIVE |
| 5 | Interest Match | `interest.match@iut-dhaka.edu` | STUDENT | ACTIVE |
| 6 | Unavailable Student | `unavailable.student@iut-dhaka.edu` | STUDENT | ACTIVE |
| 7 | Hidden Student | `hidden.student@iut-dhaka.edu` | STUDENT | ACTIVE |
| 8 | Python Student | `python.student@iut-dhaka.edu` | STUDENT | ACTIVE |
| 9 | Student Mentor | `student.mentor@iut-dhaka.edu` | STUDENT | ACTIVE |
| 10 | Alumni Mentor | `alumni.mentor@iut-dhaka.edu` | ALUMNI | ACTIVE |
| 11 | Student Mentee | `student.mentee@iut-dhaka.edu` | STUDENT | ACTIVE |
| 12 | Alumni Mentee | `alumni.mentee@iut-dhaka.edu` | ALUMNI | ACTIVE |
| 13 | Club Admin | `club.admin@iut-dhaka.edu` | STUDENT | ACTIVE |
| 14 | Club Representative | `club.representative@iut-dhaka.edu` | STUDENT | ACTIVE |
| 15 | Club Co Admin | `club.co.admin@iut-dhaka.edu` | STUDENT | ACTIVE |
| 16 | Career Author | `career.author@iut-dhaka.edu` | ALUMNI | ACTIVE |
| 17 | Student Reporter | `student.reporter@iut-dhaka.edu` | STUDENT | ACTIVE |
| 18 | Student Outsider | `student.outsider@iut-dhaka.edu` | STUDENT | ACTIVE |
| 19 | Suspended Student | `suspended.student@iut-dhaka.edu` | STUDENT | SUSPENDED |
| 20 | Pending Student | `pending.student@iut-dhaka.edu` | STUDENT | PENDING_VERIFICATION |
| 21 | New Student | `new.student@iut-dhaka.edu` | STUDENT | ACTIVE |
| 22 | Alumni Member | `alumni.member@iut-dhaka.edu` | ALUMNI | ACTIVE |
| 23 | Engineering Student | `engineering.student@iut-dhaka.edu` | STUDENT | ACTIVE |
| 24 | Business Student | `business.student@iut-dhaka.edu` | STUDENT | ACTIVE |
| 25 | Unavailable Mentor | `unavailable.mentor@iut-dhaka.edu` | ALUMNI | ACTIVE |
| 26 | Project Applicant | `project.applicant@iut-dhaka.edu` | STUDENT | ACTIVE |

System Admin, Pending Student and New Student intentionally have no personal
profile. New Student can sign in and demonstrate profile onboarding. System Admin
uses `SYSTEM_ADMINISTRATION` context for administrator endpoints. Club Admin,
Club Co Admin and Club Representative are STUDENT accounts with separate club
assignments; they are not extra platform roles. Student Outsider is an ordinary
active student with no retained career access, not a special system role.

Profile IDs equal their user IDs for the 23 profiles. Student years are
`1 + (userId % 4)`; expected graduation is base-year plus `4 - yearOfStudy`.
Student numbers are `DEMO-STUDENT-NNN`. Project availability is true for
users **2,3,4,5,7,8,23,24,26**; all other student profiles are false.
Student mentorship availability is true only for Student Mentor (9).
Alumni Mentor graduated in 2018; other alumni graduated in 2022.

- Dept 1 **CSE**: degree/programme 1 **SWE**, degree/programme 2 **CSE**.
- Dept 2 **EEE**: degree/programme 3 **EEE**, used by Engineering Student (23).
- Dept 3 **BTM**: degree/programme 4 **BTM**, used by Business Student (24).
- All degrees: BACHELOR, duration 4, valid years 1-4, active.
- Users 8,11,18 use CSE programme 2. Other CSE profiles use SWE programme 1.
- CONNECTIONS_ONLY profiles: Connected Match (4), Hidden Student (7), Alumni Mentee (12).
  All other seeded profiles use ALL_MEMBERS. There are no anonymized accounts.

## Dates and time

The base date is the **Asia/Dhaka date at initial seed time** and is recorded in
`uniconnect_demo_seed_manifest`. Future deadlines use relative offsets, so there
are no hardcoded November-2026 deadlines. Audit/session-style timestamps use UTC;
mentorship occurrence start/end timestamps use Asia/Dhaka wall-clock time,
matching the current service contract. Reruns do not shift dates. If the demo is
used weeks later, some future examples will naturally become past/expired; create
a new demo cluster to refresh dates.

## Fixture scenarios

### Discovery and recommendations

Project **1**, owned by Project Creator (2), is the untouched control fixture:
required **java/sql**, optional **docker/git**, capacity 5, one creator membership,
no applications, OPEN, deadline base-date +30 days. Do not apply to it before
checking its expected recommendation results.

| Candidate | Skills | Shared interests | Connected to creator | Expected score |
| --- | --- | --- | --- | ---: |
| Complete Match (3) | java, sql, docker, git | ai, distributed systems | Yes | 100.00 |
| Connected Match (4) | sql, git | none | Yes; details visible through connection | 45.00 |
| Interest Match (5) | java | ai | No | 36.25 |

Unavailable Student (6) has matching skills but is opted out. Hidden Student (7)
has matching skills but no connection to creator. Python Student (8) has no
required match. Other java-skilled students are not project-available. The exact
recommendation list is **3,4,5**, in that order. Vocabulary rows are all lowercase,
so there are no title-case/lowercase duplicate skill records.

Standalone candidate search requires all supplied required skills; optional skills
do not become mandatory. Recommendations deliberately allow a partial required
match and score it. Applications remain independent of matching skills.

Other projects:

| ID | Project | Owner | Demonstration |
| ---: | --- | ---: | --- |
| 2 | Python Team Project | 2 | Accepted applicant/member 8; pending applicant 26; rejected applicant 11 |
| 3 | Full Club Website Project | 13 | Capacity 2, creator plus teammate 14; derived FULL |
| 4 | Closed Mobile Project | 15 | CLOSED; pending application by Student Reporter (17) |
| 5 | Expired Java Project | 2 | Stored OPEN, deadline base-date -2 days; derived EXPIRED |
| 6 | Reported Owner Project | 19 | Suspended owner fixture; normal browse eligibility exclusion |
| 7 | Deleted Demo Project | 2 | DELETED; applicant 26 has CANCELLED_PROJECT_DELETED history |

Applications 1/4 are accepted; 2/5 pending; 3 rejected; 6 cancelled by deletion.
All projects have a matching creator membership, and accepted applications have
matching teammate memberships. Historical actions have audit rows.

### Mentorship

Mentor profiles **1,2,3** belong to Student Mentor (9), Alumni Mentor (10),
Unavailable Mentor (25), respectively. Profiles 1/2 are AVAILABLE; 3 UNAVAILABLE.
Only mentor availability is a join gate; existing enrollment in series 6 remains.

| Series ID | Topic | Host user | Schedule from base date | State/capacity |
| ---: | --- | ---: | --- | --- |
| 1 | Alumni Backend Series | 10 | +7,+14,+21 days, 10:00-11:00 | OPEN; 2/5 active |
| 2 | Student Java Workshop | 9 | +8 days, 10:00-11:00 | Stored OPEN, derived FULL; 2/2 |
| 3 | Closed Enrollment Series | 10 | +9,+16 days, 10:00-11:00 | CLOSED enrollment; 1/4 active; meetings retained |
| 4 | Cancelled Backend Series | 10 | +10,+17 days, 10:00-11:00 | CANCELLED; occurrences cancelled; no active mentees |
| 5 | Completed Java Workshop | 9 | -7 days, 10:00-11:00 | Stored OPEN, derived COMPLETED; completed history |
| 6 | Unavailable Mentor Workshop | 25 | +12 days, 10:00-11:00 | Existing mentee 22; new joining blocked by unavailable mentor |
| 7 | Biweekly API Series | 10 | +14,+28,+42 days, 14:00-15:00 | OPEN; no enrollments |
| 8 | Back To Back Workshop | 9 | +8 days, 11:00-12:00 | OPEN; starts exactly when series 2 ends |

Enrollment **1**: Alumni Mentee (12) LEFT series 1. Enrollment **2**: same user
rejoined series 1 and is ACTIVE. Only period 2 gets the meeting link. Enrollment
3 is Student Mentee (11) active in series 1. Enrollments 4/5 are Student Reporter
(17)/Student Outsider (18) active in full series 2. Enrollment 6 is Project
Applicant (26) active in closed series 3. Enrollment 7 is user 12 CANCELLED in
series 4. Enrollment 8 is user 11 COMPLETED in series 5. Enrollment 9 is Alumni
Member (22) active in unavailable-mentor series 6. Active markers exist only for
ACTIVE periods; no synthetic self-enrollment or host conflict exists.

Show meeting-link privacy using Alumni Mentee versus Student Outsider on series 1.
The roster is host-only. `my-enrolled` returns enrollment DTOs;
`my-current-series` returns series summaries; `my-participation` includes history.
A full series can still have `enrollmentOpen=true`: capacity and manual closure
are separate. Ongoing-time boundaries and concurrency are covered by backend
tests; this seed does not claim to simulate concurrent requests.

### Clubs, announcements and events

- Club **1 Coding Club**: ACTIVE; administrators user 13 assignment 1 and user 15
  assignment 2. Representative user 14 assignment 3. User 18's assignment 8 was
  revoked. Multiple administrators intentionally follow current V20 rules.
- Club **2 Robotics Club**: PUBLISHING_SUSPENDED; administrator user 13 assignment
  4, representative user 14 assignment 5. Historical publication remains.
- Club **3 Business Club**: ARCHIVED, last transition from ACTIVE, administrator
  user 15 assignment 6. It is recoverable through the approved lifecycle.
- Club **4 Old Club**: REMOVED (terminal), administrator user 13 assignment 7.
- Club requests **1 pending** Science Club by user 23; **2 approved** Coding Club
  by user 13 and linked to club 1; **3 rejected** duplicate proposal by user 24.
- Announcements **1 current IMPORTANT**, **2 current URGENT**, **3 UNPUBLISHED**,
  **4 expired**, **5 REMOVED**, **6 retained Robotics Club notice**.
- Events **1 UPCOMING** (+7 days), **2 ACTIVE** (one-hour window either side of
  seed time), **3 PAST** (-7 days), **4 REMOVED** (+10 days). The ACTIVE example
  naturally becomes PAST after one hour; that is expected, not a seeding failure.
- Publication authors are club administrators with matching assignment IDs;
  representative publication permissions are not broadened by this seed.

### Connections and chat

Accepted connections 1-5: users **2/3, 2/4, 9/11, 13/17, 10/12**. Connection 6 is
pending (13/18); 7 rejected (8/23); 8 cancelled (14/24); 9 removed (15/22).
There is no accepted connection between creator 2 and hidden student 7.

Conversations **1 (9/11)** and **2 (13/17)** have six messages and complete
participant/state rows. Message **3** is deleted for everyone; message **4** is
deleted only for reporter 17; message **6** is delivered but unread by reporter
17. The reporting fixture references message 6, which reporter 17 can access.

### Career, reporting and moderation

Career Author (16) owns six posts:

| ID | Post | Availability | Application channel |
| ---: | --- | --- | --- |
| 1 | Backend Internship | PUBLISHED, +45 days | URL |
| 2 | Closed Platform Role | CLOSED, future deadline | EMAIL |
| 3 | Expired Data Role | Stored PUBLISHED, expired -3 days | URL |
| 4 | Flutter Contract | PUBLISHED, +60 days | URL and EMAIL |
| 5 | Part Time Data Analyst | PUBLISHED, +35 days | EMAIL |
| 6 | Removed Career Post | REMOVED | URL |

Reporter (17) saved posts 1,2,3 before closure/expiry. Mentee (11) saved post 4;
Applicant (26) saved post 5. Outsider (18) has no saved posts, so they cannot
access the closed/expired targets merely by knowing an ID.

All seven supported report target types are represented:

| Report ID | Target | Status | Evidence |
| ---: | --- | --- | --- |
| 1 | USER 19 | ACTION_TAKEN | Suspension action 1 against user 19; submitted before action |
| 2 | CLUB 1 | SUBMITTED | Retained club snapshot |
| 3 | ANNOUNCEMENT 1 | UNDER_REVIEW | Reviewer System Admin (1) |
| 4 | EVENT 3 | NO_ACTION | Historical event reviewed; no moderation link |
| 5 | CHAT_MESSAGE 6 | SUBMITTED | Reporter is a participant and message is accessible |
| 6 | PROJECT 1 | SUBMITTED | Captured creator 2, title and project skills |
| 7 | CAREER_POST 2 | UNDER_REVIEW | Reporter saved the closed post; captured owner 16 |

These are clearly synthetic fixture histories, inserted by the seed rather than
claims that real moderation requests occurred. Suspension action **1** targets
user **19**, with matching audit log **1**, previous ACTIVE/new SUSPENDED, and a
report action link. Reporter-facing responses should hide snapshots, reviewer,
internal notes and action evidence; administration may inspect them. Report 7
cannot use action 1 as owner evidence. Request evidence uses **`id`**, while the
response action object uses **`evidenceId`**. Resolution never performs moderation.

Notifications include connection events, roles/revocation, chat, mentorship
join/leave/cancel, project acceptance/rejection/deletion, suspension, report
resolution and club publishing suspension. Read and unread examples are present;
only valid existing reference targets are seeded. There are no duplicate event
keys for a recipient.

## Optional API acceptance check

After SQL verification and starting the demo backend, run:

```bash
python3 scripts/demo-seed/verify-api.py --base-url http://127.0.0.1:18084
```

This logs into all ACTIVE fixture accounts, confirms inactive login denial,
checks exact scores/order, candidate privacy, meeting-link/roster privacy,
FULL/CLOSED states, historical periods, topic browsing, retained career access,
reporter privacy, admin queue and owner-matched evidence. Tokens remain in memory
and are not printed. Only login, session-context selection and logout writes are
submitted; no content, project, enrollment, report or moderation mutations are
submitted. Session rows remain after logout, so this makes the database
non-pristine and the seed deliberately refuses to overwrite it afterward.
The API script fails fast and attempts to revoke its sessions even on failure.

## Verification status and limits

Validation completed for this patch:

- Embedded PostgreSQL **18.6**, applying the repository SQL migrations and the
  literal DDL from Java migrations, including equivalent empty-database dynamic
  constraint changes through V26. This is schema-level validation, not execution
  of Spring Boot/Flyway itself; the harness supplies migration-history metadata.
- Fixture insertion and all **66 pristine assertions** passed.
- Read-only verification, BCrypt password match, unchanged rerun, modified-data
  refusal, nonempty-database refusal and assertion-failure rollback passed.
- A subsequent generated user ID is **27**, avoiding fixture ID collisions.
- Bash syntax and Python compilation passed. The patch was checked and applied
  to a clean directory, and its installed files were compared byte-for-byte.
- The embedded harness bypasses TCP/database-name checks because it has no TCP
  listener. Actual `psql`/TCP application and the HTTP acceptance script still
  need to run in the recipient's fresh local environment.
- No Maven/backend test suite or Spring Boot HTTP check was run here. This patch
  changes only fixture tooling/docs and does not claim those checks passed. Your teammate must run the API check on
the actual fresh localhost backend before considering the fixture delivery
verified. No existing development/Neon database needs to be contacted. No new
backend feature, Flyway migration or automatic startup seeding is required.

## Reset and cleanup

There is deliberately no table-wiping/reset command. Reset by disposing of this
specific demo cluster and creating a new one. First press Ctrl+C in the demo
backend terminal. In the original PostgreSQL setup terminal (which still has the
`demo_dir` and `pg_bin` values), stop only that cluster:

```bash
"$pg_bin/pg_ctl" -D "$demo_dir/data" stop -m fast
```

Keep the stopped directory if you want to inspect the demo later. To permanently
remove only the directory printed during setup, verify it matches this demo and
then run:

```bash
case "$demo_dir" in
  /tmp/uniconnect-demo.*) rm -rf -- "$demo_dir" ;;
  *) echo 'Unexpected cleanup path; nothing removed.' ;;
esac
```

Do not remove any of the older `fr29`, `fr30`, reporting or mentorship Swagger
clusters as part of these commands. No external services need to be stopped.

## Pristine row inventory

| Table | Rows |
| --- | ---: |
| `users` | 26 |
| `departments` | 3 |
| `programmes` | 4 |
| `programme_degrees` | 4 |
| `skills` | 16 |
| `interests` | 8 |
| `personal_profiles` | 23 |
| `profile_skills` | 52 |
| `profile_interests` | 28 |
| `connections` | 9 |
| `chat_conversations` | 2 |
| `chat_participants` | 4 |
| `chat_messages` | 6 |
| `chat_message_states` | 12 |
| `clubs` | 4 |
| `club_role_assignments` | 8 |
| `club_audit` | 12 |
| `club_creation_requests` | 3 |
| `club_announcements` | 6 |
| `club_events` | 4 |
| `club_publication_audit` | 16 |
| `mentor_profiles` | 3 |
| `mentor_expertise` | 5 |
| `mentorship_slots` | 8 |
| `mentorship_occurrences` | 14 |
| `mentorship_enrollments` | 9 |
| `teammate_projects` | 7 |
| `teammate_project_skills` | 13 |
| `teammate_project_memberships` | 9 |
| `teammate_project_applications` | 6 |
| `teammate_project_audits` | 19 |
| `career_job_posts` | 6 |
| `career_job_skills` | 12 |
| `career_saved_jobs` | 5 |
| `moderation_actions` | 1 |
| `audit_logs` | 1 |
| `content_reports` | 7 |
| `report_audit_logs` | 13 |
| `report_action_links` | 1 |
| `notifications` | 59 |

Plus the V1 application metadata row, unchanged Flyway history and one demo-only manifest row. No verification, reset or authenticated session rows are seeded.
