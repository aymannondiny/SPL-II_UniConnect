# UniConnect

UniConnect is a university-focused networking and collaboration platform for students, alumni, clubs, and system administrators at the Islamic University of Technology (IUT).

It combines verified university accounts, profiles, user discovery, connections, club communication, project collaboration, career opportunities, mentorship, direct messaging, and notifications in one system.

## Project Status

UniConnect is undergoing a clean modular MVC rebuild.

The current foundation includes:

- a Spring Boot modular-monolith backend;
- a Flutter application for Android and web;
- PostgreSQL configuration and Flyway migrations;
- isolated H2-based backend tests;
- shared validation and API-error handling;
- Flutter routing, theming, configuration, and API-client boundaries;
- approved requirements and architecture documentation.

The earlier implementation remains preserved through:

- branch: `legacy/pre-mvc-rebuild`
- tag: `legacy-v1-final`

The rebuild does not copy the legacy domain model. Features are implemented incrementally from the approved requirements and corrected design artifacts.

## One-Month Rebuild Scope

### Must complete

- Shared application foundation
- Authentication and profile management
- Club identity and active club context
- Club announcements and events
- User discovery and connections
- One-to-one chat

### Should complete

- Project teammate finder
- Career board
- Notifications
- Basic administration
- Cross-module search

### Deferred

- Peer mentorship
- Content reporting and warning workflows
- Advanced moderation and reporting
- Real-time presence and other advanced capabilities

The requirements baseline is authoritative for detailed business rules and acceptance criteria.

## Architecture

UniConnect follows a modular Model-View-Controller architecture.

- **View:** Flutter screens, widgets, forms, navigation, and presentation state
- **Controller:** Spring REST and WebSocket controllers
- **Model:** services, domain entities, business rules, repositories, and persistence
- **Database:** PostgreSQL managed through Flyway migrations

```text
Flutter View
    |
    | REST / WebSocket
    v
Spring Controllers
    |
    v
Services and Domain Model
    |
    v
Spring Data JPA Repositories
    |
    v
PostgreSQL
```

The backend remains one modular monolith, with source code grouped by business feature.

## Technology Stack

### Backend

- Java 21
- Spring Boot 4.1.1
- Spring Web MVC
- Spring Data JPA
- Jakarta Bean Validation
- Spring Boot Actuator
- PostgreSQL
- Flyway
- Maven Wrapper
- JUnit 5 and AssertJ
- H2 for isolated automated tests

### Frontend

- Flutter and Dart
- Material 3
- Android and web targets
- `package:http` for REST communication
- Flutter unit and widget tests

Authentication, authorization, JWT/session handling, WebSocket communication, and domain features will be added through separate reviewed issues. The foundation does not claim those features are already implemented.

## Repository Structure

```text
SPL-II_UniConnect/
├── .env.example
├── .gitignore
├── README.md
├── backend/
│   ├── pom.xml
│   ├── mvnw
│   └── src/
├── frontend/
│   ├── pubspec.yaml
│   ├── android/
│   ├── web/
│   ├── lib/
│   └── test/
└── docs/
    ├── architecture/
    ├── diagrams/
    └── requirements/
```

The backend base package is `com.uniconnect`.

Backend features use controller, DTO, mapper, service, model, and repository packages only when they contain real code. Flutter features use view, controller, model, and data packages as needed.

## Prerequisites

Install Git, JDK 21, Flutter with Dart, Google Chrome for Flutter web development, and PostgreSQL for normal backend execution.

A globally installed Maven is not required because the backend includes Maven Wrapper. Docker is not required for the current local setup.

## Backend Setup

### 1. Create PostgreSQL resources

Create a database named `uniconnect` and a database user named `uniconnect`, or supply different values through environment variables.

### 2. Configure environment variables

From the repository root:

```bash
cp .env.example .env
```

Replace the example password in `.env`:

```text
DB_URL=jdbc:postgresql://localhost:5432/uniconnect
DB_USERNAME=uniconnect
DB_PASSWORD=replace_with_local_password
SERVER_PORT=8080
```

The `.env` file is ignored by Git and must never be committed. Spring Boot does not load it automatically, so export its variables before starting the backend:

```bash
set -a
source .env
set +a
```

The same variables may instead be configured in the developer's IDE. Automated tests do not require Supabase or another hosted database.

### 3. Start the backend

```bash
cd backend
./mvnw spring-boot:run
```

The default backend URL is `http://localhost:8080`. The health endpoint is `http://localhost:8080/actuator/health`.

### 4. Test and build the backend

```bash
cd backend
./mvnw test
./mvnw clean package
```

Backend tests activate the `test` profile and use an in-memory H2 database in PostgreSQL compatibility mode. They do not modify local or hosted PostgreSQL data.

## Database Management

Flyway owns database-schema changes. Migrations are stored under `backend/src/main/resources/db/migration/` and use names such as `V1__initialize_application.sql`.

Hibernate uses `ddl-auto: validate`. It validates mappings but does not create, alter, or delete the schema.

Backend configuration is divided into `application.yml`, `application-dev.yml`, and `application-test.yml`.

## API Error Contract

Backend errors use one consistent structure:

```json
{
  "timestamp": "2026-09-17T18:00:00Z",
  "status": 404,
  "error": "Not Found",
  "code": "RESOURCE_NOT_FOUND",
  "message": "User with identifier '42' was not found.",
  "path": "/api/users/42",
  "fieldErrors": []
}
```

Validation failures include field-specific messages. Unexpected exceptions return a safe generic message rather than internal details.

## Frontend Setup

Install dependencies:

```bash
cd frontend
flutter pub get
```

Run in Chrome:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080
```

Run on an Android emulator:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Analyze and test:

```bash
cd frontend
flutter analyze
flutter test
```

Build for web:

```bash
flutter build web \
  --dart-define=API_BASE_URL=http://localhost:8080
```

## Engineering Rules

1. Controllers call services, not repositories.
2. Services own transactions and authoritative business rules.
3. Repositories handle persistence and do not decide authorization.
4. DTOs are not JPA entities.
5. JPA entities are not returned directly through public controllers.
6. A feature does not directly access another feature's repository.
7. Cross-feature operations use the owning feature's public service contract.
8. Shared packages contain only system-wide infrastructure.
9. Flutter Views do not access the database or make final authorization decisions.
10. Secrets, credentials, tokens, and private personal data are never committed or logged.

## Team Workflow

```text
Issue -> Branch -> Implement -> Test -> Commit -> Push -> Pull request -> Review -> Merge
```

Do not develop directly on `main`. Keep one coherent concern per issue and pull request. Require review for shared-domain, database, and security changes, and merge only after acceptance criteria and automated tests pass.

## Project Documentation

Approved requirements and design sources are listed in the [documentation index](docs/README.md).

- [Requirements Baseline](docs/requirements/UniConnect_Requirements_Baseline.xlsx)
- [Modular MVC Architecture](docs/architecture/UniConnect_Modular_MVC_Architecture.drawio)
- [Architecture and Clean Code Guide](docs/architecture/UniConnect_Modular_MVC_Architecture_Guide.md)
- [Overall Class Diagram](docs/diagrams/UniConnect_Overall_Class_Diagram.drawio)
- [Shared Domain Model](docs/diagrams/UniConnect_Shared_Domain_Model.drawio)

Earlier reports remain preserved in the legacy snapshot. When an earlier document conflicts with the approved baseline under `docs/`, the approved baseline governs the rebuild.

## Team

UniConnect is developed by SPL-II Team 4:

- Maliha Tasnim Khan — 230042127
- Sayma Tasnim — 230042139
- Ayman Binta Altaf Nondiny — 230042141
- Saika Sarara — 230042159

## License

No open-source license has been selected. Until a license is added, this repository should be treated as an academic team project whose reuse requires permission from the authors.
