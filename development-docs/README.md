# UniConnect technical documentation

This directory contains technical and development material for the current
UniConnect repository: setup instructions, maintained requirements and design
artifacts, API contracts, architectural decisions, delivery notes, demo and
presentation tooling documentation, and QA evidence.

The separate [university submissions directory](../docs/README.md) contains the
academic files submitted at specific points in the project. Those submissions
are preserved records and may describe earlier plans or contracts. For current
implementation behavior, use the source code, Flyway migrations, generated
OpenAPI document, automated tests, and the technical documents here.

## Start here

- [Development setup](DEVELOPMENT_SETUP.md)
- [Architecture and clean-code guide](architecture/UniConnect_Modular_MVC_Architecture_Guide.md)
- [Maintained requirements baseline](requirements/UniConnect_Requirements_Baseline.xlsx)
- [Frontend workspace README](../code/frontend/README.md)
- [Root project overview](../README.md)

## Architecture and design

- [Modular MVC architecture diagram](architecture/UniConnect_Modular_MVC_Architecture.drawio)
- [Overall class diagram](diagrams/UniConnect_Overall_Class_Diagram.drawio)
- [Shared domain model](diagrams/UniConnect_Shared_Domain_Model.drawio)
- [Interactive frontend wireframe](design/UniConnect_Frontend_Wireframe.html)
- [Interactive frontend wireframe, version 2](design/UniConnect_Frontend_Wireframe_Version2.html)

Feature class diagrams are under [`diagrams/modules/`](diagrams/modules/).
These design artifacts support implementation work; when they differ from
executable behavior, the current source, migrations, and OpenAPI output describe
the running system.

## API contracts

- [Authentication sessions](api/LOGIN_SESSIONS.md)
- [Email verification](api/EMAIL_VERIFICATION.md)
- [Password reset](api/PASSWORD_RESET.md)
- [Profiles and academic catalogue](api/PERSONAL_PROFILES.md)
- [Discovery and connections](api/DISCOVERY_CONNECTIONS.md)
- [One-to-one chat](api/ONE_TO_ONE_CHAT.md)
- [Club identity contexts](api/CLUB_IDENTITY_CONTEXTS.md)
- [Club lifecycle](api/CLUB_LIFECYCLE.md)
- [Club publications](api/CLUB_PUBLICATIONS.md)
- [Project teammate finder](api/PROJECT_TEAMMATE_FINDER.md)
- [Peer mentorship](api/PEER_MENTORSHIP.md)
- [Career board](api/CAREER_BOARD.md)
- [Content reporting](api/CONTENT_REPORTING.md)
- [Account moderation](api/ACCOUNT_MODERATION.md)
- [Administration dashboard](api/ADMINISTRATION_DASHBOARD.md)

The running backend exposes Swagger UI at
`http://localhost:8080/swagger-ui/index.html` and OpenAPI JSON at
`http://localhost:8080/v3/api-docs` when started on the default port.

## Decisions, delivery notes, and verification evidence

- Architectural and module decisions: [`decisions/`](decisions/)
- Frontend and feature delivery/review notes: Markdown files in this directory
- Demo data instructions: [`demo/DEMO_DATA_SEEDING.md`](demo/DEMO_DATA_SEEDING.md)
- Presentation dataset documentation: [`presentation/`](presentation/)
- QA evidence: [`qa/`](qa/) and [`screenshots/`](screenshots/)

Delivery reports record the state and verification performed at the time they
were written. They are useful history, but they do not guarantee that later
changes have passed the same checks.

## Maintaining these documents

- Edit `.drawio` files with diagrams.net or the Draw.io desktop application.
- Edit workbooks with Microsoft Excel or a compatible spreadsheet application.
- Update an existing artifact in place when it remains the same document.
- Keep links relative so the documentation works from a local clone and GitHub.
- Keep requirements, diagrams, migrations, API contracts, and source behavior
  synchronized when an approved rule changes.
- Do not store credentials, private database backups, generated build output, or
  local logs in this directory.
