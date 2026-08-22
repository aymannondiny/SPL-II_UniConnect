# UniConnect

UniConnect is a university-focused networking and collaboration platform for students, alumni, clubs, and administrators at the Islamic University of Technology (IUT). It brings academic networking, club communication, project collaboration, career opportunities, mentorship, and direct messaging into one system.

> **Project status:** UniConnect is being prepared for a clean, learning-oriented rebuild. The current `main` branch contains the earlier Spring Boot backend and project reports. The new implementation will be introduced incrementally through reviewed feature branches and pull requests.

## Why UniConnect?

University communication is often divided among messaging apps, social networks, email, and informal personal contacts. This makes it difficult to find people with relevant skills, follow club activities, form project teams, contact alumni, and preserve important university information.

UniConnect aims to provide one verified university space where users can:

- create a student or alumni profile;
- discover and connect with other university members;
- communicate through one-to-one chat after connecting;
- follow club announcements and events;
- find project teammates;
- explore career opportunities;
- participate in peer mentorship; and
- receive relevant notifications.

## One-Month Rebuild Scope

The team will prioritize complete, demonstrable modules instead of claiming that every planned feature is finished.

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

### Deferred for later design or implementation

- Peer mentorship
- Content reporting and warning workflows
- Advanced moderation and reporting
- Real-time presence and other advanced capabilities

The requirements baseline is the authority for detailed business rules and acceptance criteria. A feature is considered complete only after its backend, user interface, validation, authorization, tests, and acceptance criteria have been verified.

## Architecture

The rebuild follows a **modular Model-View-Controller (MVC) architecture**:

- **View:** Flutter screens, widgets, forms, navigation, and UI states.
- **Controller:** Spring REST controllers that receive requests and return HTTP responses.
- **Model:** domain entities, business rules, application services, repositories, and persistence logic.
- **Database:** PostgreSQL with versioned Flyway migrations.

The Spring Boot backend will remain a modular monolith organized by business feature. REST will support normal client-server communication, while WebSocket communication will be used where real-time chat requires it.

```text
Flutter View
    |
    | REST / WebSocket
    v
Spring REST Controllers
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

## Engineering Principles

The team will apply SOLID and Clean Code pragmatically:

- keep controllers thin and services cohesive;
- keep persistence access inside repositories;
- use constructor dependency injection;
- separate API DTOs from persistence entities;
- use meaningful domain names and small focused methods;
- validate input and return explicit errors;
- enforce authentication and authorization on the server;
- test important business rules; and
- review shared-model and security changes through pull requests.

Abstractions and design patterns will be introduced only when they solve a real responsibility, boundary, variation, or testing problem.

## Technology Stack

### Current backend

- Java 21
- Spring Boot 3.3.5
- Spring Web and Spring Security
- Spring Data JPA
- PostgreSQL
- Flyway
- JWT authentication
- Maven
- JUnit 5, Mockito, AssertJ, and H2 for testing
- Springdoc OpenAPI / Swagger UI

### Planned client

- Flutter and Dart
- REST API integration
- WebSocket integration for one-to-one chat

## Current Repository Structure

```text
SPL-II_UniConnect/
|-- code/
|   `-- src/
|       |-- main/
|       |   |-- java/com/spl2/uniconnect/
|       |   `-- resources/
|       `-- test/
|-- Presentation&Report/
|-- docs/
|-- pom.xml
`-- README.md
```

This structure describes the existing repository. It will evolve as the modular MVC rebuild and Flutter client are added.

## Running the Current Backend

These instructions apply to the backend currently stored on `main` and may change during the rebuild.

### Prerequisites

- Git
- Java Development Kit (JDK) 21
- Maven
- PostgreSQL

### 1. Clone the repository

```bash
git clone https://github.com/aymannondiny/SPL-II_UniConnect.git
cd SPL-II_UniConnect
```

### 2. Create a PostgreSQL database

Create an empty database named `uniconnect`, or choose another name and use it in the configuration below.

### 3. Add local configuration

Create `code/src/main/resources/application-local.yml`. This file is ignored by Git and must never contain credentials that are committed to the repository.

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/uniconnect
    username: YOUR_DATABASE_USERNAME
    password: YOUR_DATABASE_PASSWORD
  jpa:
    hibernate:
      ddl-auto: validate
  mail:
    host: YOUR_SMTP_HOST
    port: 587
    username: YOUR_SMTP_USERNAME
    password: YOUR_SMTP_PASSWORD

app:
  jwt:
    secret: REPLACE_WITH_A_PRIVATE_SECRET_OF_AT_LEAST_32_CHARACTERS
    expiration: 86400000
  frontend:
    url: http://localhost:3000
  email:
    verification-url: http://localhost:8080/api/auth/verify-email?token=
    reset-password-url: http://localhost:8080/api/auth/reset-password?token=
    from: YOUR_SENDER_EMAIL
    sender-name: UniConnect
```

Never commit real database, email, or JWT secrets.

### 4. Run the application

```bash
mvn spring-boot:run
```

When the application starts, useful development endpoints include:

- API base URL: `http://localhost:8080/api`
- Swagger UI: `http://localhost:8080/swagger-ui/index.html`
- Health check: `http://localhost:8080/actuator/health`

### 5. Run the tests

```bash
mvn test
```

## Team Workflow

Every meaningful change should follow this lifecycle:

```text
Issue -> Branch -> Implement and test -> Commit -> Push -> Pull request -> Review -> Merge
```

Basic rules:

1. Do not develop directly on `main`.
2. Create one issue for one coherent piece of work.
3. Create a branch from an updated `main`.
4. Keep commits small and meaningful.
5. Inspect `git status` and `git diff` before committing.
6. Open a pull request and link the relevant issue.
7. Require teammate review for shared-model and security changes.
8. Merge only after the acceptance criteria and tests pass.

Suggested branch names:

```text
feature/issue-12-user-registration
fix/issue-18-connection-authorization
docs/issue-21-update-readme
```

Suggested commit messages:

```text
feat(auth): add student registration (#12)
fix(connection): enforce recipient authorization (#18)
docs(readme): document local setup (#21)
```

## Team

UniConnect is developed by **SPL-II Team 4**:

- Maliha Tasnim Khan — 230042127
- Sayma Tasnim — 230042139
- Ayman Binta Altaf Nondiny — 230042141
- Saika Sarara — 230042159

## Project Documentation

The approved requirements and design sources for the modular MVC rebuild are
available in the [documentation index](docs/README.md).

Key artifacts:

- [Requirements Baseline](docs/requirements/UniConnect_Requirements_Baseline.xlsx)
- [Modular MVC Architecture](docs/architecture/UniConnect_Modular_MVC_Architecture.drawio)
- [Architecture and Clean Code Guide](docs/architecture/UniConnect_Modular_MVC_Architecture_Guide.md)
- [Overall Class Diagram](docs/diagrams/UniConnect_Overall_Class_Diagram.drawio)
- [Shared Domain Model](docs/diagrams/UniConnect_Shared_Domain_Model.drawio)

Earlier academic reports are retained for project history:

- [Software Design and Requirements Report](./Presentation%26Report/SPL-2_Team-4_Design%20Report.pdf)
- [Project Proposal Report](./Presentation%26Report/SPL-2_Team4_ProjectProposalReport.pdf)
- [Original Requirements Collection Workbook](./Presentation%26Report/Group-4_SPL-II%20Requirement%20Collection%20Document%20.xlsx)

When an earlier document conflicts with the approved baseline under `docs/`, the
approved baseline governs the rebuild.

## License

No open-source license has been selected yet. Until a license is added, the repository should be treated as an academic team project whose reuse requires permission from the authors.
