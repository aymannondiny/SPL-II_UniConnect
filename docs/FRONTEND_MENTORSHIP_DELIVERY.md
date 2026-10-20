# Peer Mentorship Frontend & Vertical Delivery

Implemented in `code/frontend/lib/features/mentorship`, following the UniConnect modular MVC architecture. Each component has a focused single responsibility with comprehensive test coverage and clean Material 3 presentation.

## Delivered Capabilities

### 1. Peer Mentor Directory (`MentorDirectoryTab`)
- **Multi-Criteria Search**: Real-time filtering by mentor topic/expertise, study year (Years 2, 3, 4), and department.
- **Mentor Cards**: Displays profile avatar, academic department, graduation/study year badge, availability status, and top expertise chips.
- **Mentor Profile Modal**: Deep-dive profile dialog presenting the mentor's biography, linked skills and descriptions, availability toggle, and quick shortcut to browse their hosted sessions.

### 2. Mentorship Sessions Discovery (`SlotDirectoryTab`)
- **Session Browsing**: Paginated view of upcoming open slots.
- **Filter by Delivery Mode**: Switch easily between Online, In-Person, or All sessions.
- **Visual Capacity Indicator**: Real-time progress bar showing occupied vs available seats (`X/Y enrolled`).
- **Session Details Dialog**: Full breakdown of session agenda, start/end times, upcoming recurrence dates, and venue/meeting links.
- **Enrollment Flow**: Interactive `JoinSlotDialog` capturing introductory notes and personal learning objectives.

### 3. Personal Mentorship Dashboard (`MyMentorshipTab`)
- **Joined Sessions (Mentee View)**: Lists active reservations with session time, mentor name, meeting location / links, and one-click spot release ("Leave Session") with confirmation.
- **Hosted Sessions (Mentor View)**: Comprehensive control panel for mentors:
  - **Attendee Roster**: View enrolled mentees along with their stated learning goals and intro notes (`SlotAttendeesDialog`).
  - **Edit Session**: Update schedule, location, or capacity (`MentorshipSlotFormDialog`).
  - **Close Enrollment**: Prevent new mentees from enrolling while preserving active participants.
  - **Cancel Session**: Cancel the slot with automatic notification dispatch to all active attendees.
- **Mentor Status & Availability**: Instant toggle between `AVAILABLE` and `UNAVAILABLE`.
- **Mentor Registration**: Senior students (`year >= 2`) and Alumni can register directly via `MentorRegistrationDialog`.

## API Integration Summary

| Endpoint | Purpose | Status |
| --- | --- | --- |
| `GET /api/v1/mentorship/mentors` | Directory search with topic, department, and study year filters | Integrated |
| `GET /api/v1/mentorship/mentors/{id}` | Detailed mentor profile with expertise topics | Integrated |
| `GET /api/v1/mentorship/mentors/me` | Fetch authenticated user's mentor profile | Integrated |
| `POST /api/v1/mentorship/mentors` | Senior student & alumni mentor registration | Integrated |
| `PATCH /api/v1/mentorship/mentors/me/status` | Update availability status | Integrated |
| `GET /api/v1/mentorship/slots` | Browse open mentorship slots with mode and status filters | Integrated |
| `GET /api/v1/mentorship/slots/{id}` | Retrieve session details and recurring occurrences | Integrated |
| `POST /api/v1/mentorship/slots` | Publish a new mentorship slot | Integrated |
| `PUT /api/v1/mentorship/slots/{id}` | Update slot schedule, capacity, and mode | Integrated |
| `POST /api/v1/mentorship/slots/{id}/join` | Reserve a spot with learning goals | Integrated |
| `POST /api/v1/mentorship/slots/{id}/leave` | Release enrolled spot | Integrated |
| `POST /api/v1/mentorship/slots/{id}/close` | Close enrollment for new participants | Integrated |
| `POST /api/v1/mentorship/slots/{id}/cancel` | Cancel session with mentee notification broadcast | Integrated |
| `GET /api/v1/mentorship/slots/my-mentoring` | List slots created by mentor | Integrated |
| `GET /api/v1/mentorship/slots/my-enrolled` | List slots joined by mentee | Integrated |
| `GET /api/v1/mentorship/slots/{id}/enrollments` | Retrieve attendee roster with learning objectives | Integrated |

## Test Verification

- **Backend**: 32 unit and integration tests passing:
  - `MentorRegistrationIntegrationTests` (7 tests)
  - `MentorMultiCriteriaSearchIntegrationTests` (3 tests)
  - `MentorshipSlotIntegrationTests` (9 tests)
  - `MentorshipNotificationServiceTests` (4 tests)
  - `MentorshipRecurrenceCalculatorTests` (5 tests)
  - `PostgresMentorshipSmokeTests` (1 test)
- **Frontend**:
  - `mentorship_model_test.dart`: Serialization, deserialization, and validation logic.
  - `mentorship_controller_test.dart`: State transitions, filter updates, pagination, and error isolation.
  - `mentorship_widgets_test.dart`: Presentation badges, status cards, and action callbacks.
  - `mentorship_page_test.dart`: Full tab routing and workspace integration.
