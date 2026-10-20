# UniConnect frontend

Flutter/Dart, Material 3, `package:http`, and Flutter unit/widget tests.
Features follow the existing view/controller/model/data structure. Registration
uses an injected repository to separate presentation and network behavior.
Use Flutter 3.47.1 with Dart 3.13.1; the repository pins Flutter in `.fvmrc`.

## Setup and verification

Run from `code/frontend`:

```powershell
fvm flutter pub get
fvm flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8080
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze
fvm flutter test
fvm flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8080
```

The repository pins Flutter 3.47.1 in `.fvmrc`. In IntelliJ IDEA, set the
Flutter SDK path to the repository's `.fvm/flutter_sdk` directory and use
`code/frontend/lib/main.dart` as the Flutter entry point. Select Chrome, set
the working directory to `code/frontend`, and add
`--web-port=3000 --dart-define=API_BASE_URL=http://localhost:8080` as the
additional run arguments.

To run the full project, start the backend first, then run this Flutter web
command in a second IntelliJ terminal. The backend reads database values from
process environment variables and does not load `.env` automatically. See
[the development setup guide](../../docs/DEVELOPMENT_SETUP.md) for the Windows
PowerShell and database setup details.

Android emulators use `http://10.0.2.2:8080`. The API URL is compile-time
configuration; rebuild after changing it. A same-origin reverse proxy is also
supported by setting the base URL to that origin.

## Sign-up

Both `/` and `/sign-up` display sign-up. The reference is the repository-root
`uniconnect-wireframe-v2-updated.html`; its embedded campus photos and logos
are copied to `assets/auth`. Dark mode uses the original wireframe logo; light
mode uses a transparent-background version of the supplied `UniConnect-light.png`.
The original uploaded asset is preserved. Flutter typography replaces the reference's
externally hosted fonts.

The logo widget compensates for the light PNG's transparent margins so its
visible U matches the dark logo, while both retain the same 40px layout slot.

The transparent logo is `assets/auth/logo-light-transparent.png`, created with
the built-in imagegen tool using this edit prompt:

> Use case: background-extraction. Edit target: the supplied UniConnect light logo.
> Remove only the white background, including the white opening inside the U,
> and make it genuinely transparent. Preserve the exact U silhouette, glossy
> highlights, red left stem, magenta right stem, orange lower highlight,
> proportions and colors. Do not redesign or add shadows, text or new elements.
> Crop the output canvas to a square around the existing U with only 5%
> transparent padding, centered, so it can be displayed as a small app logo.

## Messages

After logging in, choose **Messages** from home navigation or its feature card to open the responsive inbox and chat
view. It uses the authenticated session and backend REST contract in
`docs/api/ONE_TO_ONE_CHAT.md` for conversations, history, accepted connections,
sending, and message deletion. Authenticated WebSocket invalidations refresh the
inbox and open thread; an eight-second REST refresh recovers changes after a
disconnect. Opening history marks returned messages read. The UI supports
older-history pagination, unread counts, delivery/read receipts, retry-safe
message IDs, and per-user or everyone deletion.

## Career Board

Career Board uses the authenticated `/api/v1/career` endpoints. Students can
browse active opportunities, combine employment type, location, work mode,
and skill filters, sort by newest or closing deadline, open post details, save
or remove posts, and edit private notes on saved posts. Saved expired, closed,
and redacted posts remain visible with application links disabled. Application
URLs and email channels open through the platform's external app handler after
the latest post details are fetched.

Active Alumni accounts can publish posts, edit their own published and
non-expired posts, and permanently close a post. The form follows backend
limits for dates, HTTPS application URLs, email channels, and required or
preferred skills. Other account roles receive a clear access state.

The visual preview has test-only Career Board listings separate from the
production app. Run:

```powershell
fvm flutter run -d web-server -t tool/preview.dart --web-port=3001
```

Then open `http://127.0.0.1:3001/?screen=career` or add `&role=ALUMNI` to
preview author management.

- Desktop hero/form layout stacks below 900 logical pixels.
- Light/burgundy and dark/green-gold themes can be switched on screen.
- Name, university email, password, Student/Alumni role, password visibility,
  advisory strength meter with live labels/colors, inline validation, loading,
  and API errors are included. The meter also follows autofill and clearing.
- Email is trimmed/lowercased; passwords are preserved and limited to 8–72
  characters, matching the backend. Strength adds no extra password rules.
- Success shows pending verification, removes the form, and creates no session.
- Resend uses conditional wording: HTTP 202 acknowledges the request, not delivery.
- Email-link confirmation and login are implemented as separate pages; no fake
  activation or authentication is used.

## Login and password recovery

`/login` follows the login section of `uniconnect-wireframe-v2-updated.html`.
It reuses the registration page's hero, logo assets, Material typography, input
decoration, card spacing, and light/burgundy and dark/green-gold themes. The theme
selection now carries across authentication navigation for the app's lifetime.

- Both sign-up and email verification navigate to the real login page.
- Email/password validation, current-password autofill, visibility, keyboard
  submission, disabled/loading states, safe API errors, and retry are included.
- Login calls `/api/v1/auth/login`, then `/api/v1/auth/me`. Only an active account
  returned by `me` enters the authenticated workspace. Missing profiles open
  Student/Alumni setup; existing profiles open home.
- Access and refresh credentials stay in controller memory. Refresh is serialized
  and scheduled before access expiry; both rotated credentials are replaced
  together. Failed refresh clears the local session and asks for login again.
- Logout revokes the current session through the backend. Network failure keeps
  the account visible with retry; an already-ended session returns to login.
- Reloading or closing the app loses the in-memory session. There is no
  localStorage token persistence or "remember me" option.
- `/forgot-password` implements the wireframe's account-help form using the real
  forgot-password endpoint. HTTP 202 uses eligibility wording and does not claim
  that SMTP delivered an email.
- `/reset-password#token=...` captures the emailed token once, removes its fragment
  from browser history, and waits for an explicit new-password submission. Missing
  links offer recovery; API-rejected links show an error and a new-link action.
- Reset checks confirmation and the backend's 8–72 character / 72 UTF-8 byte
  limits. Success requires HTTP 204 and returns the user to login without creating
  a session. Password whitespace is preserved.

All new code follows the existing view/controller/model/data structure with
injected repositories for tests and small widgets with focused responsibilities.
See [delivery notes and suggested commit groups](../../docs/FRONTEND_AUTH_DELIVERY.md).

## APIs and mocks

The running backend's `/v3/api-docs` and `docs/api` describe these available APIs:

| Area | API families |
| --- | --- |
| Auth | `/api/v1/auth/register`, `verify-email`, `resend-verification`, `login`, `refresh`, `logout`, `me`, `forgot-password`, `reset-password` |
| Profiles | `/api/v1/profile/me`, student/alumni updates, privacy, availability, academic options |
| Discovery/connections | `/api/v1/members`, member detail, `/api/v1/connections`, accept/reject/cancel/remove |
| Clubs/context | `/api/v1/clubs`, operators/representatives, `/api/v1/auth/contexts`, active context |
| Career Board | `/api/v1/career/posts`, saved posts and notes, author post management, external application channels |
| Chat | `/api/v1/chat/conversations`, history, messages, read/delivered/deletion, `/ws/chat` |
| Notifications/admin | `/api/v1/notifications`, read; `/api/v1/admin/academics`, clubs and audit |

The screen uses real POST register and resend-verification endpoints. There are
no required unfinished endpoints and **no production mocks**. Tests alone use
documented fixtures:

```json
{
  "userId": 42,
  "fullName": "Ayman",
  "email": "ayman@iut-dhaka.edu",
  "platformRole": "ALUMNI",
  "accountStatus": "PENDING_VERIFICATION"
}
```

The fixture ID is arbitrary. Resend mocks an empty 202. Error fixtures use the
shared ApiError `code`, `message`, and `fieldErrors` list of field/message pairs.
Network failure is shown rather than replaced with fake success.

## Integration requirements

Run Flutter web on the fixed port 3000 shown above. The backend `dev` profile
allows the exact origins `http://localhost:3000` and
`http://127.0.0.1:3000`. Other development ports and deployed frontend origins
must be listed explicitly in the backend's comma-separated
`REST_ALLOWED_ORIGINS`; non-development profiles otherwise allow no
cross-origin REST requests. Wildcards are rejected. A same-origin reverse proxy
remains supported, and WebSocket origins use the separate
`CHAT_ALLOWED_ORIGINS` setting.

Database and SMTP must work. Registration delivery failure returns 503 and rolls
back the account. See `docs/api/EMAIL_VERIFICATION.md`. Set `VERIFICATION_URL` to
the frontend's `/verify-email` and `PASSWORD_RESET_URL` to `/reset-password`.
Both token fragments are captured and removed from the current history entry.
Verification follows the existing page's automatic confirmation behavior;
password reset waits for the user's form submission. Production hosting must
rewrite frontend routes to `index.html` so emailed links and reloads work.

## Meaningful contribution and commit plan

Small focused files, useful features, accessibility, tests, and documentation
provide contribution evidence. Avoid padding lines, unnecessary abstractions,
duplicate code, empty commits, and cosmetic churn.

The sign-up implementation is organized into these reviewable commit groups:

1. Registration models and validation.
2. Registration/resend API repository and contract tests.
3. Registration and verification request state.
4. Wireframe and supplied logo assets with Flutter asset registration.
5. Light and dark theme styling.
6. Theme-aware logo and campus hero.
7. Password visibility and live strength feedback with tests.
8. Validated Student/Alumni registration form.
9. Pending verification and resend view.
10. Responsive sign-up page composition.
11. Application routing and shell verification.
12. Desktop and mobile registration-flow tests.
13. Frontend setup, API inventory, and integration documentation.

Keep related changes on a feature branch and verify the complete branch before
review. Future cohesive contributions include discovery, member profiles, connections,
messaging, and their tests. Commit each meaningful change
after checking it.
Push feature branches for review; merge only after explicit team approval and
passing required checks.

## Verification record

On 2026-10-17: the login/recovery implementation passed formatting, Flutter
analysis, all 58 tests, the release web build, and desktop/mobile browser checks.
Live invalid-login handling was verified against the running development backend.
Successful authentication/reset and SMTP delivery still require a team-owned
verified test account; automated success flows use test-only fixtures. See the
delivery notes for exact coverage and the suggested commit groups.

On 2026-10-15: dependency resolution, Dart formatting, `flutter analyze`, all
12 unit/widget tests, and the release web build passed. Widget flows cover
1440×900, 390×844, and 320×640 including validation, Alumni submission, pending
verification, and resend. Desktop and mobile layouts were also inspected in the
browser. No real account was created and SMTP delivery was not exercised;
successful registration/resend behavior was verified with documented test mocks.

## Profile setup and home

App-owned sessions, Student/Alumni setup and editing, privacy preferences, and the
responsive authenticated home are implemented. See [delivery notes, integration
limits, preview commands and suggested commits](../../docs/FRONTEND_PROFILE_HOME_DELIVERY.md).

On 2026-10-17, profile/home delivery passed formatting, Flutter analysis, all 94
tests and the release web build. Desktop/mobile browser QA used explicit fixtures;
the production login correctly handles the unavailable local backend. See the
profile/home delivery notes for the live-integration blocker.

On 2026-10-18, the updated HTML wireframe's complete desktop sidebar, mobile More
navigation, search header, feature-card layout and home sections were restored.
All 103 frontend tests and static analysis passed. Administration remains role
restricted, and unavailable activity counts use explicit placeholders.

## Discover, connections, and member profiles

Discover supports name, role, department, skills, company, and graduation-year
filters, followed by load-more search results. View profile opens the backend's
public member representation and respects its privacy flag. Connections and
chat recipient lists follow all backend pages. Message from a connection opens
that person, including when the inbox is already mounted.

For implementation details, reproducible checks, fixture preview instructions,
remaining integration work, and proposed commit boundaries, see
[Networking readiness delivery](../../docs/FRONTEND_NETWORKING_DELIVERY.md).

## Clubs and events

The campus workspace includes searchable clubs, club profiles, announcements,
current/upcoming/live events, club event history and registration-link details.
It reuses the shared themes and typography and connects to the existing APIs.
See [clubs/events delivery notes](../../docs/FRONTEND_CLUBS_EVENTS_DELIVERY.md)
for verification, fixture preview, integration limitations and suggested commits.
