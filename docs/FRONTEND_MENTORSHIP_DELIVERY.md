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
| `POST /api/v1/mentorship/slots/{id}/reopen` | Reopen enrollment when vacancy and a future meeting remain | Backend available; UI action not yet exposed |
| `POST /api/v1/mentorship/slots/{id}/cancel` | Cancel session with mentee notification broadcast | Integrated |
| `GET /api/v1/mentorship/slots/my-mentoring` | List slots created by mentor | Integrated |
| `GET /api/v1/mentorship/slots/my-enrolled` | Original enrollment-record contract for current participation | Backend contract restored; current Flutter parser expects a different shape |
| `GET /api/v1/mentorship/slots/my-current-series` | Card-ready current-series summaries | Backend available; Flutter endpoint migration not included |
| `GET /api/v1/mentorship/slots/my-participation` | Current and historical participation periods | Backend available; history UI not yet exposed |
| `GET /api/v1/mentorship/slots/enrollments/{enrollmentId}` | Retrieve the participant's own private enrollment period | Backend available; detail UI not yet exposed |
| `GET /api/v1/mentorship/slots/{id}/enrollments` | Retrieve attendee roster with learning objectives | Integrated |

## Backend Compatibility Notes

- `my-enrolled` preserves its original enrollment response (`enrollmentId`, `slotId`, `slotTopic`,
  private notes, enrollment `status`, and participation timestamps). The current Flutter repository
  incorrectly parses that path as `MentorshipSlotSummary`; because enrollment `status` and slot
  `status` have different meanings, a `slotTopic` alias alone cannot make those contracts compatible.
  Flutter must move its card list to the additive `my-current-series` endpoint in a separate frontend
  change. No Flutter source is changed by this backend correction.
- The current recurring-series form sends neither `meetingCount` nor `recurrenceEndDate`; the
  backend therefore retains the established 12-meeting default. A future UI can expose either
  bound, but must not send both.
- Reopen, current-series, and participation-history endpoints are additive. Exposing them requires
  corresponding UI actions/state; the current enrolled-card call specifically requires the endpoint
  migration described above.

## Frontend Test Coverage

- **Frontend**:
  - `mentorship_model_test.dart`: Serialization, deserialization, and validation logic.
  - `mentorship_controller_test.dart`: State transitions, filter updates, pagination, and error isolation.
  - `mentorship_widgets_test.dart`: Presentation badges, status cards, and action callbacks.
  - `mentorship_page_test.dart`: Full tab routing and workspace integration.
