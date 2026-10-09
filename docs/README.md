# UniConnect Documentation

This directory contains the approved requirements and design baseline for the
clean UniConnect modular MVC rebuild.

## Authoritative Documents

The following artifacts govern the new implementation:

- [Requirements Baseline](requirements/UniConnect_Requirements_Baseline.xlsx)
- [Modular MVC Architecture](architecture/UniConnect_Modular_MVC_Architecture.drawio)
- [Architecture and Clean Code Guide](architecture/UniConnect_Modular_MVC_Architecture_Guide.md)
- [Overall Class Diagram](diagrams/UniConnect_Overall_Class_Diagram.drawio)
- [Shared Domain Model](diagrams/UniConnect_Shared_Domain_Model.drawio)
- [Frontend Wireframe](design/UniConnect_Frontend_Wireframe.html) — clickable HTML reference for screens, themes (dark/light) and navigation

If an older repository document conflicts with these artifacts, the approved
baseline in this directory takes precedence for the rebuild.

## Module Class Diagrams

- [Administration and Notification](diagrams/modules/Administration_Notification.drawio)
- [Authentication and Profile](diagrams/modules/Authentication_Profile.drawio)
- [Career Board](diagrams/modules/Career_Board.drawio)
- [Club and Announcement](diagrams/modules/Club_Announcement.drawio)
- [Connection and Networking](diagrams/modules/Connection_Networking.drawio)
- [One-to-One Chat](diagrams/modules/One_to_One_Chat.drawio)
- [Peer Mentorship](diagrams/modules/Peer_Mentorship.drawio)
- [Project Teammate Finder](diagrams/modules/Project_Teammate_Finder.drawio)

## Implementation Scope

The one-month rebuild prioritizes complete vertical modules.

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
- Content-reporting and warning workflows
- Advanced moderation and reporting
- Real-time presence and other advanced capabilities

A deferred feature remains part of the long-term product baseline; it is simply
outside the committed one-month implementation scope.

## Editing the Documentation

- Edit `.drawio` files using [diagrams.net](https://www.diagrams.net/) or the
  Draw.io desktop application.
- Edit the requirements workbook using Microsoft Excel or another compatible
  spreadsheet application.
- Do not create numbered filenames such as `(1)` or `(2)`.
- Update an existing file in place so Git records its history.
- Changes to requirements or shared models require team review through a pull
  request.
- Keep implementation, diagrams, and requirements synchronized when an approved
  business rule changes.

## Historical Documents

Earlier reports remain under `Presentation&Report/` for academic and project
history. They may describe the legacy implementation and should not override the
approved rebuild baseline in this directory.
