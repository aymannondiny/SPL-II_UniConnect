# Shared web and Android client

## Changes

- `code/frontend` is the maintained client for both platforms; the root mobile
  prototype remains available for reference and is no longer a separate CI target.
- Browser URL strategy is behind a conditional export. Native startup opens
  the application root instead of interpreting the process URI as a web route.
- API configuration distinguishes an Android emulator from an Android browser.
  Explicit `API_BASE_URL` values take precedence on every platform.
- Android Internet permission now applies to release builds as well as debug.
  Only debug permits cleartext HTTP for local backend development.
- Workspace content respects horizontal display cutouts in landscape.
  Existing font sizes, Material typography, burgundy light colors, and green/gold
  dark colors remain shared. No duplicate screens or artificial line padding
  were introduced.
- Web manifest branding now matches the default dark theme and permits landscape.
- CI analyzes and tests the canonical package and builds web and Android debug.

## Verification on 2026-10-25

Local SDK: Flutter 3.47.7 / Dart 3.13.5. The repository pin remains Flutter
3.47.1; CI reads that pin. Local results do not prove the pinned CI run passed.

- Final whole-package formatting check: 246 files, no changes required.
- Final Flutter analysis (lint and static types): passed.
- Full unit/widget suite: 228 tests passed.
- After the safe-area change: 11 focused navigation/cutout tests passed,
  including both added cutout cases and existing responsive navigation tests.
- Final release web build: passed, including the WebAssembly compatibility dry run.
- Native Android ARM64 debug Dart bundle: `flutter build bundle --debug
  --target-platform android-arm64` passed independently of Gradle. This verifies
  native Dart compilation, not APK packaging or native device behavior.
- Android debug APK: not verified. The first build reached automatic provisioning
  of missing NDK 28.2.13676358. SDK Manager stalled reading the archive with a
  zero-byte temporary file; its process was stopped after diagnosis. Gradle then
  exited 1 after 11 minutes. Google's download host answered a separate HTTP HEAD
  check, so general host unreachability is not established. SDK Manager also
  warned that its supported XML version is older than the installed SDK metadata.
  Finish NDK installation using current Android SDK tools, then rerun the build.
- Production web app served on port 3000; login inspected at desktop and
  390 x 844 mobile size. Fixture workspace inspected at 1440 x 900 and 390 x 844,
  with light and dark desktop themes. No visible clipping was found in those views.
- Existing responsive tests also cover 320 x 640 and 1024 x 600. Added landscape
  tests cover 844 x 390 with left/right display insets.

## What is real and what is mocked

Production `lib/main.dart` uses the existing API repositories; this work adds no
mocked production data. Authenticated visual QA runs `tool/preview.dart`, which
uses explicit fake session/profile/chat/career data and member/campus fixtures.
Automated tests also use injected fixtures. Rendering a fixture is not proof of
live backend integration.

The backend health endpoint at localhost:8080 was unavailable. Live login,
email delivery, authenticated CRUD, and WebSocket communication were therefore
not verified in this session. No Android device was connected, so native touch,
keyboard, external-link handling, and lifecycle smoke tests remain outstanding.

Deployment still needs a reachable HTTPS API, web origins configured in the
backend, frontend route fallback, and production Android signing. Native email
App Links require a chosen domain and association files; current email flows
remain on the web client. Sessions remain memory-only, as before. Launcher icons
are the existing assets; this change does not supply a new Android icon set.

## Meaningful commit groups

1. `fix(client): isolate browser startup from native routing`
2. `fix(config): resolve emulator API host with platform regression tests`
3. `fix(android): enable networking and debug-only local HTTP`
4. `fix(layout): respect landscape cutouts with regression tests`
5. `style(web): align manifest branding with the shared theme`
6. `ci: verify the canonical client on web and Android`
7. `docs: document shared-client setup and archive prototype guidance`

Keep each change understandable and testable; keep its regression tests in the
same commit as the fix. Use selective staging when ready. More useful work can
produce more legitimate commits: native lifecycle tests, verified App Links,
release signing setup, accessibility fixes, and backend integration tests are
separate tasks. Avoid blank-line padding, duplicated implementations, empty
commits, or splitting a working fix into deliberately broken intermediate steps.
Implementation and verification were completed before Git publication. The
subsequent user-approved publication groups these changes into seven focused
commits on `codex/shared-web-android-client`; merging remains a separate step.
