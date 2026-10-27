# Career Board Decisions

## Scope

The agreed Career Board backend persistence, REST APIs, OpenAPI documentation,
tests, and CAREER_POST reporting scope for FR56–FR61 and FR81–FR82 is complete.
Frontend integration and confirmed integration fixes remain. This phase does not
implement Flutter screens, notifications, administrative removal, reopening,
author deletion, Project Teammate Finder, or internal applications.

## Decisions

1. Publishing and author mutation require an ACTIVE, non-anonymized `ALUMNI` account. Browsing active posts and reading their details allow ACTIVE Students and Alumni. Saving and applying
   require an ACTIVE, non-anonymized `STUDENT` account. Alumni may also read their own historical posts. Selected application context does not grant authority.
2. `applicationDeadline` is a date in `Asia/Dhaka`. The post is active through that local date and derives
   `EXPIRED` at the start of the following local day. The injected `Clock` supplies the instant; stored timestamps
   remain UTC.
3. `EXPIRED` is not a stored status and no scheduled midnight update exists.
4. The post stores `PUBLISHED`, `CLOSED`, or `REMOVED`. Authors can edit a non-expired `PUBLISHED` post and
   permanently close a `PUBLISHED` post. They cannot remove or reopen it.
5. Students can save only an active post. A database uniqueness constraint enforces one bookmark per
   student/post even under concurrency. Bookmarks and optional notes survive closure and expiry.
6. Closed and expired saved posts remain readable, but applying is disabled. Removed posts are redacted
   tombstones and cannot be opened through the ordinary detail endpoint.
7. Applications remain external. `/apply` revalidates activity and redirects to a validated HTTPS or `mailto:`
   destination without fetching it or storing an application/applicant.
8. Suspending an author blocks their access but does not remove or hide existing posts. Removing content is a
   separate moderation decision.
9. Account anonymization must enter through the Career-owned `CareerAuthorPrivacyService` while the owning
   account transaction holds its account lock. Career then suppresses channels and active visibility, retains
   historical post/bookmark rows, and returns `Former User` without a stable author ID.
10. Authentication and Profile own account and skill data. Career calls their public service contracts and
    does not access their repositories.
11. Lock order for Career writes is actor account/session, career post, then saved bookmark. This aligns
    account-state races and serializes edit/close/save operations without reversing existing account locks.
12. `V18__create_career_board.sql` adds Career tables only. It does not alter prior migrations or notification
    constraints.
13. CAREER_POST is a supported content-report target. Career owns ordinary detail
    visibility and creates the safe immutable snapshot; Reporting stores it with
    the author as owner and no parent club. Closed/expired content remains
    reportable only where ordinary detail remains accessible. ACTION_TAKEN accepts
    only an existing unreversed suspension of the captured author.

## Deferred integration

`REMOVED` remains in the domain and schema because the approved model reserves it
for moderation. No endpoint can set it in this phase. Content reporting does not
add removal authority: its only accepted CAREER_POST action evidence is an
already-committed suspension of the captured author.

## Role-dashboard amendment — 27 October 2026

The project owner explicitly extended career browsing to alumni. The shared Career board now defaults to Browse opportunities for both roles. Alumni select My career posts to retrieve their own author history. This supersedes the earlier student-only browse interpretation of FR_57; author mutations, student bookmarks and external applications retain their existing role restrictions.
