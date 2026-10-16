# UniConnect frontend

Flutter/Dart, Material 3, `package:http`, and Flutter unit/widget tests.
Features follow the existing view/controller/model/data structure. Registration
uses an injected repository to separate presentation and network behavior.

## Setup and verification

Run from `code/frontend`:

```powershell
flutter pub get
flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8080
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8080
```

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

- Desktop hero/form layout stacks below 900 logical pixels.
- Light/burgundy and dark/green-gold themes can be switched on screen.
- Name, university email, password, Student/Alumni role, password visibility,
  advisory strength meter with live labels/colors, inline validation, loading,
  and API errors are included. The meter also follows autofill and clearing.
- Email is trimmed/lowercased; passwords are preserved and limited to 8–72
  characters, matching the backend. Strength adds no extra password rules.
- Success shows pending verification, removes the form, and creates no session.
- Resend uses conditional wording: HTTP 202 acknowledges the request, not delivery.
- Login explicitly explains its screen is pending. Email-link confirmation and
  login remain separate frontend work; no fake activation or authentication.

## APIs and mocks

The running backend's `/v3/api-docs` and `docs/api` describe these available APIs:

| Area | API families |
| --- | --- |
| Auth | `/api/v1/auth/register`, `verify-email`, `resend-verification`, `login`, `refresh`, `logout`, `me`, `forgot-password`, `reset-password` |
| Profiles | `/api/v1/profile/me`, student/alumni updates, privacy, availability, academic options |
| Discovery/connections | `/api/v1/members`, member detail, `/api/v1/connections`, accept/reject/cancel/remove |
| Clubs/context | `/api/v1/clubs`, operators/representatives, `/api/v1/auth/contexts`, active context |
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
back the account. See `docs/api/EMAIL_VERIFICATION.md`. `VERIFICATION_URL` must
eventually point to a real frontend confirmation screen; that screen must remove
the token fragment from history and POST only after user confirmation. Successful
activation and login are outside this first screen.

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
review. Future cohesive contributions include
email confirmation, login, reset password, profile setup, discovery, connections,
and their tests. Commit each meaningful change after checking it.
Push feature branches for review; merge only after explicit team approval and
passing required checks.

## Verification record

On 2026-10-15: dependency resolution, Dart formatting, `flutter analyze`, all
12 unit/widget tests, and the release web build passed. Widget flows cover
1440×900, 390×844, and 320×640 including validation, Alumni submission, pending
verification, and resend. Desktop and mobile layouts were also inspected in the
browser. No real account was created and SMTP delivery was not exercised;
successful registration/resend behavior was verified with documented test mocks.
