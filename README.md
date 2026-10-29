# UniConnect

UniConnect is a university-focused networking and collaboration platform for
students, alumni, university clubs, and system administrators at the Islamic
University of Technology (IUT). It brings verified community membership,
academic and professional profiles, collaboration opportunities, campus
publishing, and direct communication into one application.

University communication is often split across messaging groups, social media,
email, and personal networks. That fragmentation makes it difficult to find
people with relevant skills, discover mentorship and career opportunities,
follow official club activity, and provide accountable moderation. UniConnect
addresses that problem with a role-aware platform built around university
identities and explicit privacy and authorization rules.

> **University submissions:** [open the submitted reports and requirements workbook](doc/README.md)
>
> **Technical documentation:** [open the implementation, API, architecture, and development documentation](development-doc/README.md)

The academic submissions record the project at their respective submission
dates. For the current executable contract, use the source code, generated
OpenAPI description, migrations, tests, and technical documentation.

## Users and access contexts

- **Students** maintain academic profiles, discover people, build connections,
  find project teammates, participate in mentorship, and follow campus activity.
- **Alumni** maintain professional profiles, share career opportunities, connect
  with the community, and provide mentorship.
- **Club operators** work through assignment-scoped club contexts to manage the
  clubs and publications they are authorized to represent.
- **System administrators** manage academic reference data, accounts, clubs,
  reports, and supported moderation workflows.

Club access is an assigned operating context, not a replacement for a member's
platform role. Public registration is limited to supported member roles;
administrator access is not self-selected.

## Implemented capabilities

The current repository includes:

- university-domain registration, six-digit email verification, login, rotating
  sessions, logout, password recovery, and session revocation;
- student and alumni profiles, academic catalogue data, availability, skills,
  interests, and profile privacy controls;
- member discovery, connection requests, accepted connections, and related
  notifications;
- one-to-one chat for eligible users, message history and state, authenticated
  WebSocket updates, and conversation deletion controls;
- club identity and assignment-scoped contexts, announcements, events, and club
  administration workflows;
- project publishing, applications, membership history, candidate discovery,
  and skill-based recommendations;
- alumni-authored career posts, browsing, saving, expiry/closure handling, and
  external application links;
- peer mentorship offerings, occurrences, enrolment, capacity, participant and
  host views, and lifecycle operations;
- in-app notifications, content reports, account moderation, and administration
  dashboard data;
- a shared Flutter web/Android client with Light, Dark, and Engineering
  appearance modes.

Detailed endpoint behavior and module-specific limitations are documented in
the [technical documentation index](development-doc/README.md). The running
backend's OpenAPI description remains the canonical machine-readable API
contract.

## Architecture and technology

UniConnect is a modular monolith with feature-oriented packages and MVC
boundaries:

```text
Flutter views and presentation state
              |
              | REST / WebSocket
              v
Spring controllers and DTOs
              |
              v
Services and domain rules
              |
              v
Spring Data JPA repositories
              |
              v
PostgreSQL (Flyway-managed schema)
```

The backend uses Java 21, Spring Boot 4.1.1, Spring MVC, Spring Security,
Spring Data JPA/Hibernate, PostgreSQL, Flyway, Springdoc OpenAPI, Maven, and
JUnit. The client uses Flutter/Dart, Material 3, REST and WebSocket integration,
and Flutter unit and widget tests. See the
[architecture guide](development-docs/architecture/UniConnect_Modular_MVC_Architecture_Guide.md)
for package and dependency rules.

## Repository structure

```text
SPL-II_UniConnect/
├── README.md
├── .env.example
├── code/
│   ├── backend/             # Spring Boot application and tests
│   └── frontend/            # Shared Flutter web and Android client
├── doc/                    # University-submitted academic documents
├── development-docs/        # Technical, API, architecture, delivery, and QA docs
├── scripts/                 # Maintained development/demo utilities
└── mobile/                  # Archived client prototype; not the active client
```

## Local setup

### Prerequisites

- Git
- JDK 21
- Flutter 3.47.1 / Dart 3.13.1 (see `.fvmrc`)
- PostgreSQL access for a non-test backend run
- Chrome for Flutter web development

The backend includes the Maven Wrapper; a global Maven installation is not
required. Copy the environment template and use only development credentials:

```bash
cp .env.example .env
```

Review the variables before use. Do not commit `.env` or credentials. The full
configuration procedure, including local database options, mail behavior,
CORS, and troubleshooting, is in the
[Development Setup Guide](development-docs/DEVELOPMENT_SETUP.md).

### Run the backend

From the repository root:

```bash
set -a
source .env
set +a

cd code/backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

By default, the API is available at `http://localhost:8080`. Once startup
succeeds:

- Health: <http://localhost:8080/actuator/health>
- Swagger UI: <http://localhost:8080/swagger-ui/index.html>
- OpenAPI JSON: <http://localhost:8080/v3/api-docs>

Flyway validates and applies pending migrations during startup. Never point a
local run at a shared database unless that use is intentional and authorized.

### Run the Flutter web client

In a second terminal:

```bash
cd code/frontend
flutter pub get
flutter run -d chrome \
  --web-port=3000 \
  --dart-define=API_BASE_URL=http://localhost:8080
```

For an Android emulator, use
`--dart-define=API_BASE_URL=http://10.0.2.2:8080`. Additional client setup and
integration notes are in [the Flutter README](code/frontend/README.md).

## Verification

Backend verification:

```bash
cd code/backend
./mvnw clean verify
```

Flutter verification:

```bash
cd code/frontend
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

These are the repository's standard checks; this README does not claim that a
particular checkout or external environment has passed them. Backend tests use
isolated test configuration, while a signed-in integration run against a real
PostgreSQL instance remains a separate check.

## Current limitations

UniConnect is an academic software project, not a production-readiness claim.
Deployment operations, secrets management, external mail delivery, monitoring,
backup policy, and multi-instance real-time coordination require environment-
specific work beyond the repository defaults. The requirements baseline also
contains capabilities that are not fully implemented, including cross-module
search, complete account anonymization, dedicated notification-target
resolution, broader moderation workflows, and real-time presence. Consult the
module API documents and current OpenAPI output before planning an integration.

## Documentation

- [University submissions](doc/README.md) — submitted proposal, design/SRS
  report, and requirements workbook.
- [Technical documentation](development-doc/README.md) — setup, architecture,
  API contracts, design decisions, delivery notes, demo/presentation tooling,
  and QA evidence.
- [Requirements baseline](development-docs/requirements/UniConnect_Requirements_Baseline.xlsx)
  — maintained technical baseline used during implementation; it is distinct
  from the submitted academic workbook in `doc/`.

## Team

UniConnect is developed by SPL-II Team 4:

- Maliha Tasnim Khan — 230042127
- Sayma Tasnim — 230042139
- Ayman Binta Altaf Nondiny — 230042141
- Saika Sarara — 230042159

## License

No open-source license has been selected. Until a license is added, this
repository should be treated as an academic team project whose reuse requires
permission from the authors.
