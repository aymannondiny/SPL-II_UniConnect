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
- approved requirements and architecture documentation;
- canonical user persistence and public user registration;
- password hashing and pending-verification account lifecycle;
- email verification and replacement links with 24-hour expiry;
- backend security foundation;
- OpenAPI documentation and Swagger UI;
- repository CI for backend and Flutter verification.

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
- Spring Security
- Spring Data JPA
- Hibernate
- Jakarta Bean Validation
- Spring Boot Actuator
- Springdoc OpenAPI / Swagger UI
- PostgreSQL
- Neon PostgreSQL for the current shared hosted development database
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

Public user registration, email verification, login, refresh, logout, and database-backed sessions are implemented. See [Login and sessions](docs/api/LOGIN_SESSIONS.md). WebSocket communication and the remaining domain features are being added incrementally through separate reviewed issues.

## Repository Structure

```text
SPL-II_UniConnect/
├── .env.example
├── .gitignore
├── README.md
├── code/
│   ├── backend/
│   └── frontend/
└── docs/
    ├── DEVELOPMENT_SETUP.md
    ├── architecture/
    ├── diagrams/
    └── requirements/
```

The backend base package is `com.uniconnect`.

Backend features use controller, DTO, mapper, service, model, and repository packages only when they contain real code. Flutter features use view, controller, model, and data packages as needed.

## Prerequisites

Install:

- Git
- JDK 21
- Flutter with Dart
- Google Chrome for Flutter web development
- PostgreSQL client tools such as `psql` if database connectivity needs to be tested manually

A globally installed Maven is not required because the backend includes Maven Wrapper.

Docker is not required for the current local setup.

## Backend Setup

### 1. Configure PostgreSQL

The current shared development database is hosted on Neon PostgreSQL.

Each developer should obtain the current development database credentials from the team and create a local `.env` file at the repository root.

From the repository root:

```bash
cp .env.example .env
```

The `.env` file should follow this structure:

```text
DB_URL='jdbc:postgresql://YOUR_NEON_HOST/neondb?sslmode=require&channel_binding=require'
DB_USERNAME='YOUR_NEON_USERNAME'
DB_PASSWORD='YOUR_NEON_PASSWORD'
SERVER_PORT='8080'
```

The values are quoted because the JDBC URL may contain shell-sensitive characters such as `&`.

Do not commit real credentials to Git.

The `.env` file is ignored by Git and must remain local.

### 2. Load environment variables

Spring Boot does not automatically read the root `.env` file.

From the repository root:

```bash
set -a
source .env
set +a
```

You can verify that the variables are loaded without printing the password:

```bash
echo "$DB_URL"
echo "$DB_USERNAME"
[[ -n "$DB_PASSWORD" ]] && echo "DB_PASSWORD loaded"
```

### 3. Start the backend

```bash
cd code/backend
./mvnw spring-boot:run
```

The default backend URL is:

```text
http://localhost:8080
```

The health endpoint is:

```text
http://localhost:8080/actuator/health
```

Flyway automatically validates and applies pending database migrations during application startup.

### 4. Test and verify the backend

Run the full backend verification suite:

```bash
cd code/backend
./mvnw clean verify
```

`./mvnw clean verify` is the standard backend verification command and should pass before opening a pull request.

Backend tests activate the `test` profile and use an in-memory H2 database in PostgreSQL compatibility mode.

They do not modify the shared Neon database.

## Database Management

Flyway owns database-schema changes.

Migrations are stored under:

```text
code/backend/src/main/resources/db/migration/
```

Migration files use versioned names such as:

```text
V1__initialize_application.sql
V2__create_users.sql
```

Existing applied migrations should not be rewritten after being shared with other environments. New schema changes should be introduced through new Flyway migration versions.

Hibernate uses:

```text
ddl-auto: validate
```

Hibernate validates entity mappings against the database schema but does not create, alter, or delete production schema objects.

Backend configuration is divided into:

```text
application.yml
application-dev.yml
application-test.yml
```

## API Documentation and Swagger

When the backend is running, the current API contract is available through Swagger.

### Swagger UI

```text
http://localhost:8080/swagger-ui/index.html
```

### OpenAPI JSON

```text
http://localhost:8080/v3/api-docs
```

Frontend developers should use Swagger as the current reference for:

- available endpoints
- request DTOs
- response DTOs
- validation constraints
- documented status codes
- API error structures

## Current Registration API

### Endpoint

```text
POST /api/v1/auth/register
```

Example request:

```json
{
  "fullName": "Ayman Nondiny",
  "email": "ayman123@iut-dhaka.edu",
  "password": "StrongPass123",
  "platformRole": "STUDENT"
}
```

Public registration supports:

```text
STUDENT
ALUMNI
```

`SYSTEM_ADMIN` cannot be selected during public registration.

Registration requires an email ending with:

```text
@iut-dhaka.edu
```

Email addresses are normalized before duplicate checking and persistence.

Successful registration returns:

```text
201 Created
```

Newly registered accounts start with:

```text
PENDING_VERIFICATION
```

Registration now sends a verification email. See [email verification setup and API](docs/api/EMAIL_VERIFICATION.md). Login remains a separate workflow.

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

Validation failures include field-specific messages.

Unexpected exceptions return a safe generic message rather than internal implementation details.

Common registration errors currently include:

```text
400 VALIDATION_FAILED
400 INVALID_EMAIL_DOMAIN
400 INVALID_REGISTRATION_ROLE
409 EMAIL_ALREADY_EXISTS
```

Refer to Swagger for the current canonical API schema.

## Frontend Setup

Install dependencies:

```bash
cd code/frontend
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
cd code/frontend
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Build for web:

```bash
flutter build web \
  --dart-define=API_BASE_URL=http://localhost:8080
```

## Frontend Registration Integration

The frontend can already implement the registration flow against:

```text
POST /api/v1/auth/register
```

Recommended flow:

```text
Registration Form
      |
      v
POST /api/v1/auth/register
      |
      v
201 Created
      |
      v
Show registration-success / verification-pending state
```

A successful registration does not mean the user is authenticated.

The account remains:

```text
PENDING_VERIFICATION
```

until the email-verification workflow activates it.

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
10. Use constructor injection.
11. Use typed application exceptions and the shared `ApiError` contract.
12. Secrets, credentials, tokens, and private personal data are never committed or logged.

## Team Workflow

```text
Issue
  ->
Branch
  ->
Implement
  ->
Test
  ->
Commit
  ->
Push
  ->
Pull Request
  ->
Review
  ->
Merge
```

Do not develop directly on `main`.

Before beginning work:

```bash
git switch main
git pull --ff-only origin main
```

Create a feature or task branch:

```bash
git switch -c feature/your-feature-name
```

Before committing:

```bash
git status
git diff
git diff --check
```

Backend verification:

```bash
cd code/backend
./mvnw clean verify
```

Frontend verification:

```bash
cd code/frontend
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

Do not merge while CI is failing.

## Continuous Integration

GitHub Actions verifies both backend and frontend changes.

Backend CI runs:

```bash
./mvnw clean verify
```

Frontend CI runs:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

Pull requests should be merged only after required checks pass.

## Project Documentation

For complete local setup, development commands, Swagger usage, API integration guidance, CI checks, and Git workflow, see:

[Development Setup Guide](docs/DEVELOPMENT_SETUP.md)

Approved requirements and design sources are listed in the [documentation index](docs/README.md).

- [Requirements Baseline](docs/requirements/UniConnect_Requirements_Baseline.xlsx)
- [Modular MVC Architecture](docs/architecture/UniConnect_Modular_MVC_Architecture.drawio)
- [Architecture and Clean Code Guide](docs/architecture/UniConnect_Modular_MVC_Architecture_Guide.md)
- [Overall Class Diagram](docs/diagrams/UniConnect_Overall_Class_Diagram.drawio)
- [Shared Domain Model](docs/diagrams/UniConnect_Shared_Domain_Model.drawio)

Earlier reports remain preserved in the legacy snapshot.

When an earlier document conflicts with the approved baseline under `docs/`, the approved baseline governs the rebuild.

## Team

UniConnect is developed by SPL-II Team 4:

- Maliha Tasnim Khan — 230042127
- Sayma Tasnim — 230042139
- Ayman Binta Altaf Nondiny — 230042141
- Saika Sarara — 230042159

## License

No open-source license has been selected.

Until a license is added, this repository should be treated as an academic team project whose reuse requires permission from the authors.
