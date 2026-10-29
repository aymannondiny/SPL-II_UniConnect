# Additive presentation dataset

This opt-in dataset adds a coherent UniConnect presentation environment without
deleting or resetting existing development data. It is not a Flyway migration and
does not run during normal application startup.

The dataset key is `presentation-2026-v1`; the current manifest revision is 5.
Application rows use generated IDs. `uniconnect_presentation_seed_keys` maps stable
logical keys to those IDs, and `uniconnect_presentation_seed_manifest` makes a
completed reapplication a no-op. Live presentation interactions are therefore not
overwritten, passwords are not repeatedly reset, and removed content is not
resurrected.

## Safety model

- Requires the exact successful Flyway V1-V27 history and V27 verification schema.
- Takes a transaction-scoped advisory lock and uses one transaction for each apply or repair.
- Matches accounts by normalized email and rejects anonymized or unexpected identity collisions.
- Reuses IDs for matching accounts. Existing presentation-account sessions are revoked with
  the application's `ACCOUNT_CHANGE` reason before an authorized password, role, or status update.
- Never truncates, recreates, globally deletes, resets sequences, disables constraints, or changes Flyway history.
- Creates no email-verification or password-reset challenge and sends no email.
- A completed revision-5 manifest makes subsequent `apply` invocations read-only no-ops.
- Historical verification rows belonging to a reused account are preserved; no challenge is fabricated for new accounts.

All presentation accounts are ACTIVE and use the BCrypt password `Seed!234`. The
hash is generated privately at apply time through UniConnect's `PasswordConfig`;
it is never stored in this repository or printed by the tooling.

## Academic catalogue

Departments and programmes are reused by case-insensitive code and are checked for
matching names and relationships before missing rows are added. The fixture uses
official IUT undergraduate offerings:

- CSE: Computer Science and Engineering, Software Engineering
- EEE: Electrical and Electronic Engineering
- MPE: Mechanical Engineering, Industrial and Production Engineering
- CEE: Civil Engineering
- BTM: Technology Management

Sources: [IUT faculties and departments](https://www.iutoic-dhaka.edu/academics/faculties_%26_departments)
and [official offered programmes](https://admission.iutoic-dhaka.edu/international-students/offered-programmes).

## Commands

Use three private environment variables. Do not place credentials in command-line
history or commit them:

```bash
export PRESENTATION_DB_URL="$DB_URL"
export PRESENTATION_DB_USERNAME="$DB_USERNAME"
export PRESENTATION_DB_PASSWORD="$DB_PASSWORD"

scripts/presentation-seed/seed.sh dry-run
scripts/presentation-seed/seed.sh apply
scripts/presentation-seed/seed.sh verify
python3 scripts/presentation-seed/verify-api.py --base-url http://127.0.0.1:8080
```

`dry-run` reports planned account inserts, normalized-email collisions, explicit
account updates and blockers without writing persistent rows. `apply` generates a
fresh BCrypt hash privately, executes the atomic dataset, or performs a bounded
manifest-owned repair when upgrading an earlier presentation manifest. `verify`
checks ownership counts, account eligibility, mentor-year rules, project/member
consistency, mentorship capacity, report lifecycle/evidence integrity, and independently calculates
the expected project recommendation ranking.

The API verifier creates and revokes login sessions and selects an administrator
context. Everything else is read-only. It does not submit/accept/reject pending
connections, applications, club requests, reports, messages, or enrollments.

## Date window

Dates are anchored to the Asia/Dhaka date on initial application. This execution
used **2026-10-27** with a documented presentation window through **2026-12-26**.
Upcoming examples are concentrated in the next 5-35 days; the manifest retains the
original dates on rerun.

## Dataset shape

- 36 presentation accounts: 2 administrators, 26 students and 8 alumni
- 34 personal profiles and diversified skill/interest associations
- 9 open connections, including accepted and pending directions
- 4 conversations with natural three-message histories and unread examples
- 3 clubs, 7 current role assignments, announcements, and past/active/upcoming events
- 6 projects with 5 application histories and calculated recommendation examples
- 5 career posts with active, expired, closed and saved examples
- 6 mentors and 6 mentorship offerings with open/full/closed/cancelled/completed states
- 10 moderation reports across all seven supported target types: 3 submitted,
  3 under review, 2 action taken, and 2 no action
- 2 dedicated removed publication targets with committed publication-audit evidence,
  plus reporter resolution notifications

The account catalogue is [accounts.csv](../../scripts/presentation-seed/accounts.csv).

## Recovery

The preferred recovery is a full restore of the verified pre-seed custom archive
into the intended development database during an agreed maintenance window. A full
restore reverts every change since the backup, not only fixture rows, so compare the
target timeline and coordinate users before restoring.

```bash
pg_restore --clean --if-exists --exit-on-error --no-owner --no-privileges \
  --dbname="$RESTORE_TARGET_URL" /private/path/to/pre-presentation.dump
```

Do not improvise a partial delete from the generic key map: application tables have
retained histories and cross-module references. Use a fresh database or the verified
backup unless a separately reviewed fixture-removal plan is prepared.
