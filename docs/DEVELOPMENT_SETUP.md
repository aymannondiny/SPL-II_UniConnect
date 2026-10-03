# UniConnect Development Setup Guide

This document explains how to set up, run, test, and work with the UniConnect project locally.

It is intended primarily for UniConnect team members working on the Spring Boot backend or Flutter frontend.

---

## 1. Repository Layout

The active implementation is located under:

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

The active source code is under:

```text
code/
├── backend/
└── frontend/
```

Do not develop against the legacy/pre-rebuild implementation.

The previous implementation remains preserved through the legacy branch and tag for historical reference.

The backend and frontend are developed independently but communicate through REST APIs and, when implemented, WebSocket communication.

---

# 2. Current Architecture

UniConnect follows a modular Model-View-Controller architecture.

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

The Spring Boot backend is deployed as one modular monolith.

Functionality is grouped by business feature rather than splitting the system into independent microservices.

The main dependency direction is:

```text
Controller
    ↓
Service
    ↓
Repository
```

Controllers handle transport concerns.

Services own business rules, authorization decisions, and transactions.

Repositories handle persistence.

---

# 3. Technology

## Backend

The backend currently uses:

- Java 21
- Spring Boot 4.1.1
- Spring Web MVC
- Spring Security
- Spring Data JPA
- Hibernate
- Jakarta Bean Validation
- Spring Boot Actuator
- Flyway
- PostgreSQL
- Neon PostgreSQL for the current shared hosted development database
- H2 for automated tests
- Springdoc OpenAPI / Swagger UI
- Maven Wrapper
- JUnit 5
- AssertJ

## Frontend

The frontend currently uses:

- Flutter 3.47.1
- Dart 3.13.1
- Material 3
- Android target
- Web target
- `package:http` for REST communication
- Flutter unit and widget tests

---

# 4. Backend Directory

From the repository root:

```bash
cd code/backend
```

The project includes Maven Wrapper.

Use:

```bash
./mvnw
```

instead of depending on a globally installed Maven version.

For example:

```bash
./mvnw clean verify
```

---

# 5. PostgreSQL Development Configuration

The current shared development database is hosted on Neon PostgreSQL.

Neon is used as the managed PostgreSQL provider only.

Application business logic, authentication, authorization, validation, API handling, persistence coordination, and migrations remain owned by the Spring Boot backend.

The application reads database credentials from environment variables.

Required variables:

```text
DB_URL
DB_USERNAME
DB_PASSWORD
SERVER_PORT
```

---

## 5.1 Create the Local Environment File

From the repository root:

```bash
cp .env.example .env
```

The local `.env` file should follow this structure:

```text
DB_URL='jdbc:postgresql://YOUR_NEON_HOST/neondb?sslmode=require&channel_binding=require'
DB_USERNAME='YOUR_NEON_USERNAME'
DB_PASSWORD='YOUR_NEON_PASSWORD'
SERVER_PORT='8080'
```

The quotes are intentional.

The JDBC URL may contain shell-sensitive characters such as:

```text
&
?
```

Using quoted values prevents the shell from interpreting those characters.

Never commit real credentials.

The `.env` file must remain local and ignored by Git.

You can verify that Git ignores it with:

```bash
git check-ignore .env
```

Expected output:

```text
.env
```

---

## 5.2 Load the Environment Variables

Spring Boot does not automatically load the repository-root `.env` file.

From the repository root:

```bash
set -a
source .env
set +a
```

This exports the variables into the current shell session.

Verify that the configuration is loaded without printing the password:

```bash
echo "$DB_URL"
echo "$DB_USERNAME"
[[ -n "$DB_PASSWORD" ]] && echo "DB_PASSWORD loaded"
```

Do not print or paste the actual database password into issues, pull requests, documentation, logs, or chat messages.

---

## 5.3 Optional Database Connection Test

If PostgreSQL client tools are installed, the database connection can be tested before starting Spring Boot.

For Neon:

```bash
PGPASSWORD="$DB_PASSWORD" psql \
  -h YOUR_NEON_HOST \
  -U "$DB_USERNAME" \
  -d neondb \
  -c "select current_database(), current_user;"
```

A successful result should show the connected database and database user.

For example:

```text
 current_database | current_user
------------------+--------------
 neondb           | neondb_owner
```

This step is optional.

If Spring Boot starts successfully and Flyway connects, the database connection is already proven to work.

---

# 6. Start the Backend

After loading the environment variables:

```bash
cd code/backend
./mvnw spring-boot:run
```

The backend normally starts on:

```text
http://localhost:8080
```

The Actuator health endpoint is:

```text
http://localhost:8080/actuator/health
```

A successful startup should eventually contain messages similar to:

```text
Tomcat started on port 8080
Started UniConnectApplication
```

---

# 7. Flyway Database Migrations

Flyway owns database-schema changes.

Migration files are stored under:

```text
code/backend/src/main/resources/db/migration/
```

The current rebuild starts with migrations such as:

```text
V1__initialize_application.sql
V2__create_users.sql
```

When Spring Boot starts, Flyway:

1. connects to PostgreSQL;
2. validates migration history;
3. creates the Flyway schema history table if required;
4. applies unapplied migrations in version order.

Do not manually change the shared database schema to bypass Flyway.

Once a migration has been applied to a shared environment, do not rewrite that migration.

For example, if:

```text
V2__create_users.sql
```

has already been applied, a future schema change should be introduced as a new migration such as:

```text
V3__add_something.sql
```

rather than editing `V2`.

Editing an already-applied migration causes Flyway checksum mismatches and can make environments inconsistent.

Hibernate uses schema validation rather than schema generation.

The project uses:

```text
ddl-auto: validate
```

Hibernate therefore validates entity mappings against the schema but does not create, alter, or delete the production schema.

---

# 8. Backend Configuration Files

Backend configuration is currently divided between:

```text
application.yml
application-dev.yml
application-test.yml
```

The normal application configuration reads values such as:

```text
DB_URL
DB_USERNAME
DB_PASSWORD
SERVER_PORT
```

from the environment.

Secrets must not be hard-coded into these files.

---

# 9. Automated Test Database

Automated backend tests use H2 instead of the shared Neon PostgreSQL database.

H2 is intentionally configured as a test-scoped dependency.

This keeps tests:

- isolated;
- repeatable;
- independent of network availability;
- independent of the shared development database.

The test configuration uses H2 in PostgreSQL compatibility mode.

Running the normal backend test suite does not modify the shared Neon database.

---

# 10. Run Backend Verification

From:

```text
code/backend
```

run:

```bash
./mvnw clean verify
```

This is the standard backend verification command.

Before opening or merging a backend pull request:

```bash
./mvnw clean verify
```

must pass.

A successful result ends with:

```text
BUILD SUCCESS
```

---

# 11. Running the Application with H2 Manually

The normal automated test suite already uses the test configuration.

Developers usually only need:

```bash
./mvnw clean verify
```

However, the backend can also be started manually with the test profile when temporary API testing is needed without access to the shared PostgreSQL database.

Use:

```bash
./mvnw spring-boot:run \
  -Dspring-boot.run.profiles=test \
  -Dspring-boot.run.useTestClasspath=true
```

The `useTestClasspath` option is required because H2 is a test-scoped dependency.

Do not change H2 into a production/runtime dependency merely to run the application locally.

---

# 12. Swagger / OpenAPI

UniConnect exposes generated OpenAPI documentation through Springdoc.

With the backend running, open:

```text
http://localhost:8080/swagger-ui/index.html
```

This opens Swagger UI.

Swagger allows developers to:

- inspect available API endpoints;
- inspect request DTOs;
- inspect response DTOs;
- inspect validation constraints;
- inspect documented HTTP response codes;
- inspect the common API error format;
- send development requests directly from the browser.

Frontend developers should use Swagger as the current API contract reference instead of guessing request or response structures.

---

## 12.1 Raw OpenAPI Specification

The generated OpenAPI JSON is available at:

```text
http://localhost:8080/v3/api-docs
```

It can be checked from the terminal with:

```bash
curl -i http://localhost:8080/v3/api-docs
```

A working endpoint should return:

```text
HTTP/1.1 200
```

Swagger UI can also be checked with:

```bash
curl -I http://localhost:8080/swagger-ui/index.html
```

---

# 13. Current Authentication API

The completed public authentication workflows are registration, email verification, and requesting a replacement verification link.

Email verification is implemented. See [email verification setup and API](api/EMAIL_VERIFICATION.md) for the required SMTP settings and frontend contract. Login remains planned.

---

## 13.1 Register User

Endpoint:

```http
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

---

## 13.2 Public Registration Roles

Public registration supports:

```text
STUDENT
ALUMNI
```

The following role cannot be self-selected during public registration:

```text
SYSTEM_ADMIN
```

System administrator authority must not be obtainable through the public registration endpoint.

---

## 13.3 IUT Email Rule

Registration requires an IUT email ending with:

```text
@iut-dhaka.edu
```

Email addresses are normalized before duplicate checking and persistence.

For example:

```text
AYMAN123@IUT-DHAKA.EDU
```

is normalized to:

```text
ayman123@iut-dhaka.edu
```

A non-IUT email is rejected.

---

# 14. Registration Account Status

Successful registration creates an account with:

```text
PENDING_VERIFICATION
```

A successful registration does not mean the user is authenticated.

The intended lifecycle is:

```text
Registration
    ↓
PENDING_VERIFICATION
    ↓
Email Verification
    ↓
ACTIVE
    ↓
Login / Authentication
```

Email verification is implemented; login remains a separate planned workflow.

Frontend code should treat successful registration as an account-created / verification-pending state. Verification activates the account but does not create a logged-in session.

---

# 15. Registration Responses

Successful registration returns:

```http
201 Created
```

The response contains safe account information such as:

- user ID
- full name
- normalized email
- platform role
- account status

The API does not return:

- plaintext passwords;
- password hashes;
- internal authentication credentials.

Common registration failures include:

```text
400 VALIDATION_FAILED
400 INVALID_EMAIL_DOMAIN
400 INVALID_REGISTRATION_ROLE
409 EMAIL_ALREADY_EXISTS
```

Swagger should be treated as the current canonical API contract for exact schemas.

---

# 16. API Error Contract

Backend errors use a common `ApiError` structure.

Example:

```json
{
  "timestamp": "2026-09-17T18:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "code": "VALIDATION_FAILED",
  "message": "Request validation failed.",
  "path": "/api/v1/auth/register",
  "fieldErrors": []
}
```

Validation failures may contain field-specific error information.

Unexpected exceptions return a safe generic response rather than internal implementation details.

Controllers and services should use the existing application-exception mechanism instead of inventing feature-specific error structures.

---

# 17. Frontend Setup

Enter the Flutter project:

```bash
cd code/frontend
```

Install packages:

```bash
flutter pub get
```

---

## 17.1 Run Flutter Web

When Spring Boot is running on the same computer:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080
```

For Flutter web, `localhost` refers to the same machine running the browser and backend.

---

## 17.2 Run on Android Emulator

Use:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Android emulators use:

```text
10.0.2.2
```

to reach the host computer's localhost.

Therefore:

```text
http://10.0.2.2:8080
```

allows the Android emulator to communicate with the Spring Boot backend running on the development machine.

---

# 18. Frontend Verification

Before opening a frontend pull request:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

These checks also run in repository CI.

If any of these commands fail, fix the failure before merging.

---

# 19. Frontend Registration Development

Frontend developers can already implement the registration screen using:

```text
POST /api/v1/auth/register
```

The recommended current flow is:

```text
Registration Form
      ↓
POST /api/v1/auth/register
      ↓
201 Created
      ↓
Show account-created /
verification-pending state
```

Do not automatically treat a successful registration response as a logged-in user.

The returned account remains:

```text
PENDING_VERIFICATION
```

The frontend should therefore show a verification-pending state after successful registration.

The email-verification backend workflow is documented in [Email verification](api/EMAIL_VERIFICATION.md).

Before integrating an API, frontend developers should inspect:

```text
http://localhost:8080/swagger-ui/index.html
```

for the current contract.

---

# 20. Git Workflow

Before beginning new work:

```bash
git switch main
git pull --ff-only origin main
```

Create a branch associated with one issue or coherent concern.

For example:

```bash
git switch -c feature/your-feature-name
```

or:

```bash
git switch -c chore/your-task-name
```

Do not develop directly on `main`.

---

## 20.1 Check Work Before Committing

Use:

```bash
git status
git diff
```

Check for whitespace problems:

```bash
git diff --check
```

Stage only the files relevant to the issue.

Then inspect staged changes:

```bash
git status
git diff --cached
```

---

## 20.2 Push the Branch

After committing:

```bash
git push -u origin your-branch-name
```

Open a pull request against:

```text
main
```

Keep one coherent concern per issue and pull request.

Do not mix unrelated changes into the same pull request.

Shared-domain, database-migration, and security changes should receive teammate review before merge.

---

# 21. Continuous Integration

GitHub Actions verifies both backend and frontend pull requests.

---

## 21.1 Backend CI

Backend verification runs:

```bash
./mvnw clean verify
```

---

## 21.2 Frontend CI

Frontend verification runs:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

A pull request should not be merged while required CI checks are failing.

After creating a pull request, checks can be inspected using:

```bash
gh pr checks
```

---

# 22. Backend Architecture Rules

Backend development follows the modular MVC boundaries.

The primary dependency direction is:

```text
Controller
    ↓
Service
    ↓
Repository
```

Important rules:

- Controllers must not directly access repositories.
- Controllers should remain thin.
- Services own authoritative business rules.
- Services own transaction boundaries.
- Services enforce feature authorization.
- Repositories handle persistence only.
- Repositories do not decide authorization.
- Request and response DTOs are separate from JPA entities.
- JPA entities must not be exposed directly through REST controllers.
- Validation annotations should validate request contracts at the boundary.
- Authoritative business rules must still be enforced in services.
- A feature must not directly access another feature's repository.
- Cross-feature operations should use the owning feature's public service boundary.
- Shared packages are reserved for genuinely system-wide concepts.
- Use constructor injection.
- Use typed application exceptions.
- Use the shared `ApiError` response contract.
- Do not log passwords.
- Do not log verification tokens.
- Do not log JWTs or equivalent authentication secrets.
- Do not commit credentials or private secrets.
- Existing Flyway migrations that have reached a shared database must not be edited.

---

# 23. Flutter Architecture Rules

Flutter acts as the View side of UniConnect's MVC architecture.

Flutter code may:

- render data;
- collect user input;
- perform client-side validation;
- send REST/WebSocket requests;
- display server validation errors;
- manage presentation state.

Flutter must not:

- access PostgreSQL directly;
- decide final authorization;
- reproduce authoritative server business rules as security enforcement;
- bypass the Spring Boot API.

The backend remains the authority for security and business decisions.

---

# 24. Security Notes

Spring Security is already included in the backend.

The current security foundation includes:

- JSON `401 Unauthorized` responses;
- JSON `403 Forbidden` responses;
- protected-by-default API behavior;
- canonical platform roles;
- canonical account statuses;
- public access to the registration endpoint;
- public access to Swagger/OpenAPI development endpoints.

Login and the final authentication/session mechanism are not yet implemented.

During development, Spring Boot may print a generated development security password.

That generated password is not the final UniConnect authentication mechanism.

Do not build frontend login behavior around that generated password.

---

# 25. Current Account Roles

The canonical platform roles are:

```text
STUDENT
ALUMNI
SYSTEM_ADMIN
```

Club administration is not a global `PlatformRole`.

Club authority is handled separately by club-specific role assignments.

Do not introduce a global:

```text
CLUB_ADMIN
```

platform role.

---

# 26. Current Account Statuses

The canonical account statuses are:

```text
PENDING_VERIFICATION
ACTIVE
SUSPENDED
```

Newly registered accounts start as:

```text
PENDING_VERIFICATION
```

Future protected authentication behavior must permit only eligible `ACTIVE` accounts.

---

# 27. Useful Backend Commands

From the repository root:

```bash
cd code/backend
```

Compile:

```bash
./mvnw -DskipTests compile
```

Run all backend verification:

```bash
./mvnw clean verify
```

Start normally:

```bash
./mvnw spring-boot:run
```

Run temporarily with H2:

```bash
./mvnw spring-boot:run \
  -Dspring-boot.run.profiles=test \
  -Dspring-boot.run.useTestClasspath=true
```

---

# 28. Useful Environment Commands

From the repository root:

```bash
set -a
source .env
set +a
```

Verify variables safely:

```bash
echo "$DB_URL"
echo "$DB_USERNAME"
[[ -n "$DB_PASSWORD" ]] && echo "DB_PASSWORD loaded"
```

Check that `.env` is ignored:

```bash
git check-ignore .env
```

Never run:

```bash
cat .env
```

when the output could be copied into a public issue, pull request, screenshot, or chat.

---

# 29. Useful Frontend Commands

Enter the frontend:

```bash
cd code/frontend
```

Install packages:

```bash
flutter pub get
```

Run web:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080
```

Run Android emulator:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Format check:

```bash
dart format --output=none --set-exit-if-changed .
```

Analyze:

```bash
flutter analyze
```

Test:

```bash
flutter test
```

Build web:

```bash
flutter build web --release
```

---

# 30. Useful API URLs

Backend:

```text
http://localhost:8080
```

Actuator health:

```text
http://localhost:8080/actuator/health
```

Swagger UI:

```text
http://localhost:8080/swagger-ui/index.html
```

OpenAPI JSON:

```text
http://localhost:8080/v3/api-docs
```

Current registration endpoint:

```text
POST /api/v1/auth/register
```

---

# 31. Before Opening a Pull Request

For backend work:

```bash
cd code/backend
./mvnw clean verify
```

For frontend work:

```bash
cd code/frontend
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

From the repository root:

```bash
git status
git diff --check
```

Confirm:

- only intended files are changed;
- no `.env` file is staged;
- no database password is present;
- no credentials or tokens appear in the diff;
- tests pass;
- the issue scope is satisfied.

---

# 32. Development Reference Order

When a developer is unsure about implementation behavior, use the following references in this order:

1. approved requirements baseline;
2. corrected domain/class diagrams;
3. modular MVC architecture guide;
4. current Swagger/OpenAPI contract for implemented APIs;
5. current source code and automated tests.

The legacy implementation may be consulted for historical context but does not override the approved rebuild requirements or current design.

---

# 33. Current Development State

The following backend foundation is already available:

- modular MVC project structure;
- repository CI;
- Spring Security foundation;
- consistent `ApiError` handling;
- canonical `PlatformRole`;
- canonical `AccountStatus`;
- user persistence;
- Flyway user migration;
- BCrypt password hashing;
- public registration;
- IUT email-domain validation;
- duplicate-email protection;
- pending-verification registration state;
- single-use email verification and replacement links;
- Swagger/OpenAPI documentation.

The next authentication work will build on this foundation rather than replacing it.

Email verification is implemented. Login remains a separate implementation task.
