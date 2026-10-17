# UniConnect Modular MVC Architecture Guide

## 1. Architecture decision

UniConnect adopts a **modular Model–View–Controller (MVC) architecture**. The application is implemented as a Flutter client and a Spring Boot modular-monolith backend. Functionality is grouped by business feature so that each module can be designed, implemented, tested and reviewed as a coherent vertical slice.

The design is not described as “MVC inside a three-tier architecture.” Its primary architectural description is **modular MVC**.

## 2. MVC responsibilities

### View

The Flutter application is the View. It renders state, collects input, displays validation feedback and sends HTTP or WebSocket requests. It must not directly access the database or make final authorization decisions.

### Controller

Spring REST and WebSocket controllers form the server-side Controller boundary. They authenticate requests, validate request contracts, delegate to services and map results to HTTP/WebSocket responses. Controllers must remain thin.

### Model

The Model contains the domain state and behaviour of UniConnect. It includes application/domain services, canonical entities, value objects, enums, repositories, persistence rules and database migrations.

Services and repositories are internal subdivisions of the Model. Their presence does not change the primary MVC classification.

## 3. Deployment style

- One Flutter client application
- One Spring Boot modular-monolith backend
- One PostgreSQL database
- Optional object/file storage for attachments
- REST for ordinary request/response operations
- WebSocket for real-time chat and relevant live notifications

## 4. Repository structure

```text
SPL-II_UniConnect/
├── README.md
├── AGENTS.md
├── .gitignore
├── docker-compose.yml
├── docs/
│   ├── architecture/
│   ├── api/
│   ├── requirements/
│   └── decisions/
├── backend/
└── frontend/
```

## 5. Backend structure

Base package:

```text
com.uniconnect
```

Exact structure:

```text
backend/
├── pom.xml
└── src/
    ├── main/
    │   ├── java/com/uniconnect/
    │   │   ├── UniConnectApplication.java
    │   │   ├── shared/
    │   │   │   ├── config/
    │   │   │   ├── security/
    │   │   │   ├── exception/
    │   │   │   ├── audit/
    │   │   │   ├── storage/
    │   │   │   └── util/
    │   │   ├── authentication/
    │   │   ├── profile/
    │   │   ├── discovery/
    │   │   ├── connection/
    │   │   ├── club/
    │   │   ├── project/
    │   │   ├── career/
    │   │   ├── mentorship/
    │   │   ├── chat/
    │   │   ├── notification/
    │   │   ├── administration/
    │   │   └── reporting/
    │   └── resources/
    │       ├── application.yml
    │       ├── application-dev.yml
    │       ├── application-test.yml
    │       └── db/migration/
    └── test/java/com/uniconnect/
        ├── unit/
        ├── integration/
        └── acceptance/
```

Each feature package uses this structure where applicable:

```text
feature/
├── controller/
├── dto/
│   ├── request/
│   └── response/
├── mapper/
├── service/
├── model/
└── repository/
```

Do not create empty folders merely to match the template. Create a package when the feature actually requires it.

### Backend dependency rules

1. A controller may call a service, but not a repository directly.
2. A service owns transaction boundaries and authoritative business rules.
3. A repository performs persistence operations and does not make authorization decisions.
4. DTOs must not be used as JPA entities.
5. JPA entities must not be returned directly from public controllers.
6. A feature must not directly access another feature’s repository.
7. Cross-feature work must use the owning feature’s public service contract.
8. The `shared` package must contain only genuinely system-wide infrastructure.
9. Platform roles and account status are canonical shared security concepts.
10. Club authority is derived from `ClubRoleAssignment`, never from a global `CLUB_ADMIN` platform role.

## 6. Flutter structure

```text
frontend/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── config/
│   │   ├── network/
│   │   ├── auth/
│   │   ├── routing/
│   │   ├── theme/
│   │   ├── widgets/
│   │   └── errors/
│   └── features/
│       ├── authentication/
│       ├── profile/
│       ├── discovery/
│       ├── connection/
│       ├── club/
│       ├── project/
│       ├── career/
│       ├── mentorship/
│       ├── chat/
│       ├── notification/
│       ├── administration/
│       └── reporting/
└── test/
    ├── unit/
    ├── widget/
    └── integration/
```

Each Flutter feature follows:

```text
feature_name/
├── view/
├── controller/
├── model/
└── data/
```

- `view/`: screens and feature-specific widgets
- `controller/`: presentation state and user-action coordination
- `model/`: UI/API data models
- `data/`: calls to the backend API or WebSocket gateway

The Flutter controller does not replace the Spring REST controller. The Flutter controller coordinates presentation state; the Spring controller protects the server boundary and invokes backend use cases.

## 7. Canonical feature ownership

| Feature | Owns |
|---|---|
| Authentication | Credentials, verification, login, logout, token/session lifecycle |
| Profile | Student/alumni profile, skills, interests, privacy and availability |
| Discovery | Cross-user search and filter orchestration |
| Connection | Connection requests, introductory text, accepted connections and removal |
| Club | Clubs, role assignments, announcements and events |
| Project | Project posts, applications, teams and closure |
| Career | Career posts, saved posts, expiry and external application links |
| Mentorship | Mentor offerings, slots, enrollment and recurring sessions |
| Chat | Direct conversations, messages, delivery/read state and deletion |
| Notification | Canonical notifications and read state |
| Administration | Account/club moderation operations and administrative access |
| Reporting | Content reports, lifecycle and resolution |

## 8. Initial module priority for four developers

### Priority 0 — shared foundation

- project skeleton and conventions;
- PostgreSQL and Flyway;
- authentication and JWT/session invalidation;
- canonical User, PlatformRole and AccountStatus;
- student/alumni profile foundation;
- common validation and exception handling;
- Flutter shell, routing and API client.

### Priority 1 — first complete product slice

- authentication and profiles;
- discovery and connections;
- club governance, announcements and events;
- project teammate finder;
- minimum system-administration operations required by those features.

### Priority 2 — expansion

- career board;
- mentorship;
- notifications;
- one-to-one chat;
- reporting and broader moderation.

### Priority 3 — polish

- advanced search and recommendations;
- live presence;
- advanced moderation dashboards;
- attachment handling;
- nonessential administrative interfaces.

## 9. Four-person starting ownership

| Developer | Initial ownership |
|---|---|
| Developer 1 | Authentication, profile and security foundation |
| Developer 2 | Club governance, announcements and events |
| Developer 3 | Discovery, connections and later direct chat |
| Developer 4 | Project teammate finder and career board |

After the first modules stabilize, Developer 1 can extend administration/reporting, Developer 2 can integrate notifications, Developer 3 can complete chat and Developer 4 can implement mentorship.

Ownership does not permit incompatible local conventions. Shared-model modifications require a reviewed pull request.

## 10. SOLID and Clean Code standard

SOLID and Clean Code are mandatory engineering constraints for every UniConnect module. They are applied during design, implementation and pull-request review rather than postponed until the end of development.

### Single Responsibility Principle

- A controller handles transport concerns and delegates a use case.
- A service coordinates business rules and transactions.
- A repository handles persistence queries.
- A mapper converts between domain objects and DTOs.
- A validator validates one coherent type of rule.

Avoid “manager” or “utility” classes that accumulate unrelated responsibilities.

### Open/Closed Principle

Code should be extendable without repeatedly rewriting a large conditional service. Interfaces or strategies are appropriate for genuine variation, such as notification channels, file storage or report-target handling.

Do not create an interface for every class merely to claim compliance. Introduce an abstraction when there is a real boundary, multiple implementations or a testing benefit.

### Liskov Substitution Principle

Every implementation must preserve the behavioural contract of the interface it implements. Alternate implementations and test doubles must accept the same valid inputs, enforce the same important rules and produce compatible outcomes.

### Interface Segregation Principle

Prefer small, capability-focused interfaces. For example, an `EmailSender` should not also require methods for file storage, chat delivery or user administration.

### Dependency Inversion Principle

- Use constructor injection.
- Do not instantiate repositories, password encoders, clocks or external clients inside services.
- Depend on abstractions at changeable external boundaries.
- Keep high-level business rules independent of infrastructure details where practical.

### Clean Code rules

1. Use names that reveal domain intent: `acceptConnectionRequest()` rather than `processRequest()`.
2. Keep methods focused on one level of abstraction.
3. Use guard clauses to reduce unnecessary nesting.
4. Keep controllers thin and services cohesive.
5. Never expose JPA entities directly through public APIs.
6. Validate request DTOs at the boundary and enforce authoritative rules inside services.
7. Use typed application exceptions and one consistent error-response structure.
8. Do not catch an exception merely to ignore it or return a misleading success response.
9. Never log passwords, verification tokens, JWTs or sensitive personal data.
10. Remove repeated business rules, but avoid premature generic frameworks.
11. Write comments to explain *why* a surprising decision exists, not to narrate obvious code.
12. Keep source files, methods and pull requests small enough for another teammate to understand and review.
13. Add tests for permissions, lifecycle transitions, invalid inputs and important business invariants.
14. Leave touched code slightly clearer without expanding the pull request beyond its issue.

### Pull-request quality checklist

- Does the change satisfy a specific requirement and acceptance criterion?
- Does every changed class have a clear responsibility?
- Is the dependency direction `Controller → Service → Repository` respected?
- Are authorization and account-status checks enforced server-side?
- Do names express UniConnect domain language?
- Are invalid and exceptional paths handled explicitly?
- Are meaningful automated tests included?
- Are secrets and sensitive values absent from source code and logs?
- Has unnecessary abstraction or duplication been avoided?
- Has another teammate reviewed shared-domain, database or security changes?

## 11. Definition of done for one vertical module

A module is complete only when it has:

- confirmed requirements and business rules;
- database migration;
- model and repository implementation;
- service logic and authorization;
- controller and DTO contracts;
- validation and exception handling;
- automated backend tests;
- working Flutter views;
- acceptance-criteria verification;
- reviewed and merged pull request;
- updated API/design documentation.
- SOLID/Clean Code review checklist passed.

## 12. Approved report wording

> UniConnect adopts a modular Model–View–Controller architecture. Flutter screens and widgets constitute the View, Spring REST and WebSocket controllers coordinate client requests, and the Model contains application services, domain entities, business rules, repositories and persistence logic. The backend is deployed as a modular monolith, with functionality grouped into business-feature modules. This structure preserves clear MVC responsibilities while allowing four developers to implement and test prioritized vertical modules independently under shared architectural conventions.

> Development follows SOLID principles and Clean Code practices. Controllers, services and repositories have distinct responsibilities; dependencies are introduced through constructor injection; public interfaces remain focused; and business rules are expressed using clear domain terminology. These standards are enforced through automated tests and teammate pull-request reviews while avoiding unnecessary abstractions that would slow the one-month implementation.
