package com.uniconnect.mentorship;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.mentorship.domain.MentorStatus;
import com.uniconnect.mentorship.domain.ScheduleType;
import com.uniconnect.mentorship.domain.SlotMode;
import com.uniconnect.mentorship.dto.CreateSlotRequest;
import com.uniconnect.mentorship.dto.EnrollSlotRequest;
import com.uniconnect.mentorship.dto.ExpertiseRequest;
import com.uniconnect.mentorship.dto.MentorRegistrationRequest;
import com.uniconnect.mentorship.dto.UpdateSlotRequest;
import com.uniconnect.mentorship.service.MentorshipSlotService;
import com.uniconnect.mentorship.service.PeerMentorService;
import com.uniconnect.profile.domain.DegreeLevel;
import com.uniconnect.profile.dto.DegreeRequest;
import com.uniconnect.profile.dto.AlumniProfileRequest;
import com.uniconnect.profile.dto.DepartmentRequest;
import com.uniconnect.profile.dto.ProgrammeRequest;
import com.uniconnect.profile.dto.StudentProfileRequest;
import com.uniconnect.profile.service.AcademicCatalogService;
import com.uniconnect.profile.service.PersonalProfileService;
import com.uniconnect.shared.security.PlatformRole;
import com.uniconnect.shared.security.SessionPrincipal;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MentorshipSlotIntegrationTests {

    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired SessionService sessions;
    @Autowired PersonalProfileService profiles;
    @Autowired AcademicCatalogService catalog;
    @Autowired PeerMentorService mentorService;
    @Autowired MentorshipSlotService slotService;
    @Autowired com.uniconnect.notification.repository.NotificationRepository notifications;
    @Autowired JdbcTemplate jdbc;
    @Autowired jakarta.persistence.EntityManagerFactory entityManagerFactory;
    @Autowired org.springframework.transaction.PlatformTransactionManager transactions;
    @MockitoBean Clock clock;

    private SessionPrincipal admin, mentorStudent, menteeStudent1, menteeStudent2;
    private String mentorToken, mentee1Token, mentee2Token;
    private Long degreeId;
    private static final Instant NOW = Instant.parse("2026-10-15T10:00:00Z");

    @BeforeEach
    void setup() {
        clean();
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);

        admin = sessions.authenticate(account("Admin", PlatformRole.SYSTEM_ADMIN));
        mentorToken = account("Mentor", PlatformRole.STUDENT);
        mentee1Token = account("MenteeOne", PlatformRole.STUDENT);
        mentee2Token = account("MenteeTwo", PlatformRole.STUDENT);

        mentorStudent = sessions.authenticate(mentorToken);
        menteeStudent1 = sessions.authenticate(mentee1Token);
        menteeStudent2 = sessions.authenticate(mentee2Token);

        var deptId = catalog.createDepartment(admin, new DepartmentRequest("Computing", "CSE")).id();
        var progId = catalog.createProgramme(admin, new ProgrammeRequest("Software Engineering", "SWE", deptId)).id();
        degreeId = catalog.createDegree(admin, new DegreeRequest(progId, DegreeLevel.BACHELOR, 4, 1, 4, true)).id();

        profiles.saveStudent(mentorStudent, new StudentProfileRequest(
                "Senior Mentor", degreeId, "Bio", null,
                List.of("Algorithms"), List.of(), "S-001", 3, 2027, true, true
        ));
        profiles.saveStudent(menteeStudent1, new StudentProfileRequest(
                "Mentee One", degreeId, "Bio", null,
                List.of("Java"), List.of(), "S-002", 2, 2028, true, true
        ));
        profiles.saveStudent(menteeStudent2, new StudentProfileRequest(
                "Mentee Two", degreeId, "Bio", null,
                List.of("Python"), List.of(), "S-003", 2, 2028, true, true
        ));

        // Register mentorStudent as a peer mentor
        mentorService.registerMentor(mentorStudent, new MentorRegistrationRequest(
                "I offer peer mentorship in software engineering and algorithms.",
                List.of(new ExpertiseRequest("Algorithms", "Graph Theory & Dynamic Programming"))
        ));
    }

    @AfterEach
    void clean() {
        for (String table : List.of(
                "notifications", "mentorship_enrollments", "mentorship_occurrences", "mentorship_slots",
                "mentor_expertise", "mentor_profiles", "profile_skills", "profile_interests", "personal_profiles",
                "skills", "interests", "programme_degrees", "programmes", "departments",
                "password_reset_tokens", "email_verification_tokens", "authenticated_sessions", "users")) {
            jdbc.update("delete from " + table);
        }
    }

    @Test
    void publishingAndBrowsingUseBoundedQueriesForFiftyTwoMeetings() {
        var stats = entityManagerFactory.unwrap(org.hibernate.SessionFactory.class).getStatistics();
        stats.setStatisticsEnabled(true);
        try {
            stats.clear();
            slotService.createSlot(mentorStudent, new CreateSlotRequest(
                    "One meeting", "A single meeting for the query baseline.", ScheduleType.ONE_TIME,
                    LocalDate.of(2026, 10, 16), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                    SlotMode.ONLINE, null, "https://meet.example.test/one", 5, 1));
            long oneMeetingQueries = stats.getPrepareStatementCount();
            stats.clear();
            var recurring = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                    "Full year", "A full fifty-two meeting weekly series.", ScheduleType.WEEKLY,
                    LocalDate.of(2026, 10, 17), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                    SlotMode.ONLINE, null, "https://meet.example.test/year", 5, 52));
            assertThat(stats.getPrepareStatementCount()).isEqualTo(oneMeetingQueries);
            assertThat(recurring.occurrenceDetails()).hasSize(52);
            assertThat(jdbc.queryForObject("select count(*) from mentorship_occurrences where slot_id=?",
                    Integer.class, recurring.slotId())).isEqualTo(52);

            stats.clear();
            slotService.browseSlots(menteeStudent1, null, null, 0, 20);
            long twoSeriesQueries = stats.getPrepareStatementCount();
            slotService.createSlot(mentorStudent, new CreateSlotRequest(
                    "Another day", "A nonoverlapping day inside the recurring range.", ScheduleType.ONE_TIME,
                    LocalDate.of(2026, 10, 18), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                    SlotMode.ONLINE, null, "https://meet.example.test/another", 5, 1));
            stats.clear();
            var page = slotService.browseSlots(menteeStudent1, null, null, 0, 20);
            assertThat(page.totalElements()).isEqualTo(3);
            assertThat(stats.getPrepareStatementCount()).isEqualTo(twoSeriesQueries);
            assertThat(page.items()).allSatisfy(slot -> assertThat(slot.meetingLink()).isNull());
        } finally {
            stats.setStatisticsEnabled(false);
        }
    }

    @Test
    void batchedMeetingsRollBackWithTheirSeries() {
        var transaction = new org.springframework.transaction.support.TransactionTemplate(transactions);
        Long slotId = transaction.execute(status -> {
            var created = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                    "Rolled back", "No partial series or meetings may survive a failed publish.", ScheduleType.WEEKLY,
                    LocalDate.of(2026, 10, 20), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                    SlotMode.ONLINE, null, "https://meet.example.test/rollback", 5, 12));
            assertThat(created.occurrenceDetails()).hasSize(12);
            status.setRollbackOnly();
            return created.slotId();
        });
        assertThat(jdbc.queryForObject("select count(*) from mentorship_slots where slot_id=?",
                Integer.class, slotId)).isZero();
        assertThat(jdbc.queryForObject("select count(*) from mentorship_occurrences where slot_id=?",
                Integer.class, slotId)).isZero();
    }

    @Test
    void modeAndLifecycleAreFilteredBeforePagingWithoutLoadingMeetingEntities() throws Exception {
        var open = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Open online", "A future online meeting.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 20), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                SlotMode.ONLINE, null, "https://meet.example.test/open", 1, 1));
        var full = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Full online", "A future online meeting at capacity.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 21), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                SlotMode.ONLINE, null, "https://meet.example.test/full", 1, 1));
        slotService.joinSlot(menteeStudent1, full.slotId(), null);
        var inPerson = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Campus session", "A future in-person meeting.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 22), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                SlotMode.IN_PERSON, "Room 302", null, 5, 1));
        var closed = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Closed online", "A future meeting with enrollment closed.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 23), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                SlotMode.ONLINE, null, "https://meet.example.test/closed", 5, 1));
        slotService.closeSlot(mentorStudent, closed.slotId());
        var cancelled = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Cancelled online", "A cancelled future meeting.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 24), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                SlotMode.ONLINE, null, "https://meet.example.test/cancelled", 5, 1));
        slotService.cancelSlot(mentorStudent, cancelled.slotId());
        var completed = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Completed online", "A meeting that will have finished.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 16), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                SlotMode.ONLINE, null, "https://meet.example.test/completed", 5, 1));
        when(clock.instant()).thenReturn(Instant.parse("2026-10-18T00:00:00Z"));
        mentee2Token = sessions.login(new LoginRequest("menteetwo@iut-dhaka.edu", "password123")).accessToken();
        menteeStudent2 = sessions.authenticate(mentee2Token);
        mentorToken = sessions.login(new LoginRequest("mentor@iut-dhaka.edu", "password123")).accessToken();
        mentorStudent = sessions.authenticate(mentorToken);

        var stats = entityManagerFactory.unwrap(org.hibernate.SessionFactory.class).getStatistics();
        stats.setStatisticsEnabled(true);
        try {
            stats.clear();
            var first = slotService.browseSlots(menteeStudent2, null, null, SlotMode.ONLINE, 0, 1);
            assertThat(first.totalElements()).isEqualTo(2);
            assertThat(first.items()).extracting(item -> item.slotId()).containsExactly(open.slotId());
            assertThat(stats.getEntityStatistics("com.uniconnect.mentorship.domain.MentorshipSlot").getLoadCount()).isEqualTo(1);
            assertThat(stats.getEntityStatistics("com.uniconnect.mentorship.domain.MentorshipOccurrence").getLoadCount()).isZero();
            assertThat(first.items().getFirst().meetingLink()).isNull();
            assertThat(slotService.browseSlots(menteeStudent2, null, null, SlotMode.ONLINE, 1, 1).items())
                    .extracting(item -> item.slotId()).containsExactly(full.slotId());
            assertThat(slotService.browseSlots(menteeStudent2, null, null, SlotMode.ONLINE, 2, 1).items()).isEmpty();
            assertThat(slotService.browseSlots(menteeStudent2, null, null, SlotMode.ONLINE, 100000, 20).items()).isEmpty();
            assertThat(slotService.browseSlots(menteeStudent2, null, null, SlotMode.IN_PERSON, 0, 10).items())
                    .extracting(item -> item.slotId()).containsExactly(inPerson.slotId());
            assertThat(slotService.browseSlots(menteeStudent2, null, com.uniconnect.mentorship.domain.SlotStatus.CLOSED, 0, 10).items())
                    .extracting(item -> item.slotId()).containsExactly(closed.slotId());
            assertThat(slotService.browseSlots(menteeStudent2, null, com.uniconnect.mentorship.domain.SlotStatus.COMPLETED, 0, 10).items())
                    .extracting(item -> item.slotId()).containsExactly(completed.slotId());
        } finally {
            stats.setStatisticsEnabled(false);
        }
        mvc.perform(get("/api/v1/mentorship/slots").param("mode", "ONLINE").param("status", "OPEN")
                        .header("Authorization", "Bearer " + mentee2Token))
                .andExpect(status().isOk()).andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].slotId").value(open.slotId()));
        mvc.perform(get("/api/v1/mentorship/slots/my-hosted-series")
                        .header("Authorization", "Bearer " + mentorToken))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(6))
                .andExpect(jsonPath("$[0].occurrenceDetails").doesNotExist());
    }

    private String account(String name, PlatformRole role) {
        User user = User.register(name, name.toLowerCase(Locale.ROOT) + "@iut-dhaka.edu", passwords.encode("password123"), role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
        users.saveAndFlush(user);
        return sessions.login(new LoginRequest(user.getEmail(), "password123")).accessToken();
    }

    @Test
    void discoveryCombinesModeTopicAndPaginationForBothRoles() throws Exception {
        slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Java online", "Online guidance", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 20), LocalTime.of(10, 0), LocalTime.of(11, 0),
                null, SlotMode.ONLINE, null, "https://meet.example.com/java", 4));
        slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Java campus", "Campus guidance", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 21), LocalTime.of(10, 0), LocalTime.of(11, 0),
                null, SlotMode.IN_PERSON, "Library", null, 4));
        String alumniToken = account("AlumniViewer", PlatformRole.ALUMNI);
        for (String token : List.of(mentee1Token, alumniToken)) {
            mvc.perform(get("/api/v1/mentorship/slots")
                            .header("Authorization", "Bearer " + token)
                            .param("mode", "IN_PERSON").param("topic", "JAVA").param("size", "1"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.totalElements").value(1))
                    .andExpect(jsonPath("$.items[0].topic").value("Java campus"));
            mvc.perform(get("/api/v1/mentorship/slots")
                            .header("Authorization", "Bearer " + token)
                            .param("mode", "ONLINE").param("topic", "missing"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.totalElements").value(0));
            mvc.perform(get("/api/v1/mentorship/slots")
                            .header("Authorization", "Bearer " + token).param("mode", "INVALID"))
                    .andExpect(status().isBadRequest());
        }
    }

    @Test
    void mentorCanPublishSlotAndBrowseIt() throws Exception {
        String createSlotJson = """
                {
                    "topic": "Graph Algorithms Deep Dive",
                    "description": "Weekly group mentoring on graph theory and search algorithms.",
                    "scheduleType": "WEEKLY",
                    "startDate": "2026-10-20",
                    "startTime": "14:00:00",
                    "endTime": "15:30:00",
                    "mode": "ONLINE",
                    "meetingLink": "https://meet.uniconnect.local/graphs",
                    "capacity": 5
                }
                """;

        mvc.perform(post("/api/v1/mentorship/slots")
                        .header("Authorization", "Bearer " + mentorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createSlotJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.topic").value("Graph Algorithms Deep Dive"))
                .andExpect(jsonPath("$.capacity").value(5))
                .andExpect(jsonPath("$.currentMenteeCount").value(0))
                .andExpect(jsonPath("$.status").value("OPEN"));

        // Browse slots as mentee
        mvc.perform(get("/api/v1/mentorship/slots?topic=graph")
                        .header("Authorization", "Bearer " + mentee1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].topic").value("Graph Algorithms Deep Dive"));
    }

    @Test
    void nonMentorCannotPublishSlot() throws Exception {
        String createSlotJson = """
                {
                    "topic": "Unauthorized Slot",
                    "description": "Description with sufficient characters.",
                    "scheduleType": "ONE_TIME",
                    "startDate": "2026-10-20",
                    "startTime": "14:00:00",
                    "endTime": "15:00:00",
                    "mode": "ONLINE",
                    "capacity": 2
                }
                """;

        mvc.perform(post("/api/v1/mentorship/slots")
                        .header("Authorization", "Bearer " + mentee1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createSlotJson))
                .andExpect(status().isForbidden());
    }

    @Test
    void slotTimeValidationRejectsInvalidTimeAndConflictingSchedule() throws Exception {
        // Invalid time: endTime before startTime
        String invalidTimeJson = """
                {
                    "topic": "Invalid Times",
                    "description": "Description with sufficient characters.",
                    "scheduleType": "ONE_TIME",
                    "startDate": "2026-10-20",
                    "startTime": "15:00:00",
                    "endTime": "14:00:00",
                    "mode": "ONLINE",
                    "capacity": 3
                }
                """;

        mvc.perform(post("/api/v1/mentorship/slots")
                        .header("Authorization", "Bearer " + mentorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidTimeJson))
                .andExpect(status().isBadRequest());

        // Publish valid slot
        String validSlotJson = """
                {
                    "topic": "Initial Slot",
                    "description": "Description with sufficient characters.",
                    "scheduleType": "ONE_TIME",
                    "startDate": "2026-10-20",
                    "startTime": "14:00:00",
                    "endTime": "16:00:00",
                    "mode": "ONLINE",
                    "capacity": 3
                }
                """;

        mvc.perform(post("/api/v1/mentorship/slots")
                        .header("Authorization", "Bearer " + mentorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validSlotJson))
                .andExpect(status().isCreated());

        // Conflicting slot overlapping 15:00 to 17:00
        String conflictSlotJson = """
                {
                    "topic": "Overlapping Slot",
                    "description": "Description with sufficient characters.",
                    "scheduleType": "ONE_TIME",
                    "startDate": "2026-10-20",
                    "startTime": "15:00:00",
                    "endTime": "17:00:00",
                    "mode": "ONLINE",
                    "capacity": 3
                }
                """;

        mvc.perform(post("/api/v1/mentorship/slots")
                        .header("Authorization", "Bearer " + mentorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(conflictSlotJson))
                .andExpect(status().isConflict());
    }

    @Test
    void menteeCanJoinAndLeaveSlotManagingCapacity() throws Exception {
        // Create slot with capacity 1
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Exclusive 1-on-1",
                "Mentorship on design patterns.",
                ScheduleType.ONE_TIME,
                LocalDate.parse("2026-10-22"),
                LocalTime.parse("10:00:00"),
                LocalTime.parse("11:00:00"),
                null,
                SlotMode.ONLINE,
                null,
                "https://meet.uniconnect.local/patterns",
                1
        ));

        // Mentee1 joins slot
        String joinJson = """
                {
                    "joinMessage": "Looking forward to this session!",
                    "learningGoal": "Master Strategy pattern."
                }
                """;

        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/join")
                        .header("Authorization", "Bearer " + mentee1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(joinJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.slotTopic").value("Exclusive 1-on-1"));

        // Slot is now FULL
        var slotDetails = slotService.getSlot(menteeStudent1, slot.slotId());
        assertThat(slotDetails.currentMenteeCount()).isEqualTo(1);
        assertThat(slotDetails.status().name()).isEqualTo("FULL");

        // Mentee2 attempts to join -> Conflict because FULL
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/join")
                        .header("Authorization", "Bearer " + mentee2Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(joinJson))
                .andExpect(status().isConflict());

        // Mentee1 leaves the slot
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/leave")
                        .header("Authorization", "Bearer " + mentee1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("LEFT"));

        // Slot status is back to OPEN
        slotDetails = slotService.getSlot(menteeStudent1, slot.slotId());
        assertThat(slotDetails.currentMenteeCount()).isEqualTo(0);
        assertThat(slotDetails.status().name()).isEqualTo("OPEN");

        // Now Mentee2 can join
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/join")
                        .header("Authorization", "Bearer " + mentee2Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(joinJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));
    }

    @Test
    void mentorCannotJoinOwnSlot() throws Exception {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "My Own Slot",
                "Mentorship session.",
                ScheduleType.ONE_TIME,
                LocalDate.parse("2026-10-22"),
                LocalTime.parse("10:00:00"),
                LocalTime.parse("11:00:00"),
                null,
                SlotMode.ONLINE,
                null,
                null,
                2
        ));

        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/join")
                        .header("Authorization", "Bearer " + mentorToken))
                .andExpect(status().isForbidden());
    }

    @Test
    void studentAlumniAndMentorMayEnrollButHostMayNot() {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Inclusive series", "Students alumni and mentors may participate.", ScheduleType.WEEKLY,
                LocalDate.of(2026, 10, 10), LocalTime.of(17, 0), LocalTime.of(18, 0), null,
                SlotMode.ONLINE, null, "https://meet.uniconnect.local/inclusive", 5, 4));

        String alumniToken = account("AlumniMentee", PlatformRole.ALUMNI);
        SessionPrincipal alumni = sessions.authenticate(alumniToken);
        profiles.saveAlumni(alumni, new AlumniProfileRequest("Alumni Mentee", degreeId, "Bio", null,
                List.of("Java"), List.of(), 2024, null, null, null, null, null));

        assertThat(slotService.joinSlot(menteeStudent1, slot.slotId(), null).status().name()).isEqualTo("ACTIVE");
        assertThat(slotService.joinSlot(alumni, slot.slotId(), null).status().name()).isEqualTo("ACTIVE");
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> slotService.joinSlot(mentorStudent, slot.slotId(), null))
                .isInstanceOf(com.uniconnect.shared.exception.ForbiddenException.class);
    }

    @Test
    void midSeriesLeaveAndRejoinPreservesPeriodsAndProtectsMeetingLink() throws Exception {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Lifecycle series", "History is retained across participation periods.", ScheduleType.WEEKLY,
                LocalDate.of(2026, 10, 10), LocalTime.of(16, 0), LocalTime.of(17, 0), null,
                SlotMode.ONLINE, null, "https://meet.uniconnect.local/private", 2, 4));

        var first = slotService.joinSlot(menteeStudent1, slot.slotId(), new EnrollSlotRequest("first", "goal one"));
        assertThat(slotService.getSlot(menteeStudent2, slot.slotId()).meetingLink()).isNull();
        assertThat(slotService.getSlot(menteeStudent1, slot.slotId()).meetingLink()).contains("/private");
        slotService.leaveSlot(menteeStudent1, slot.slotId());
        assertThat(slotService.getSlot(menteeStudent1, slot.slotId()).meetingLink()).isNull();
        var second = slotService.joinSlot(menteeStudent1, slot.slotId(), new EnrollSlotRequest("second", "goal two"));

        assertThat(second.enrollmentId()).isNotEqualTo(first.enrollmentId());
        assertThat(slotService.getMyParticipation(menteeStudent1)).extracting(e -> e.joinMessage())
                .containsExactly("second", "first");
        assertThat(slotService.getMyParticipation(menteeStudent1)).extracting(e -> e.leftAt())
                .containsExactly(null, LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));

        mvc.perform(get("/api/v1/mentorship/slots/my-participation")
                        .header("Authorization", "Bearer " + mentee1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].joinMessage").value("second"))
                .andExpect(jsonPath("$[0].meetingLink").value("https://meet.uniconnect.local/private"))
                .andExpect(jsonPath("$[1].joinMessage").value("first"))
                .andExpect(jsonPath("$[1].meetingLink").doesNotExist());
        mvc.perform(get("/api/v1/mentorship/slots/enrollments/" + second.enrollmentId())
                        .header("Authorization", "Bearer " + mentee1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.learningGoal").value("goal two"));
        mvc.perform(get("/api/v1/mentorship/slots/enrollments/" + second.enrollmentId())
                        .header("Authorization", "Bearer " + mentee2Token))
                .andExpect(status().isForbidden());
    }

    @Test
    void laterRecurringConflictIsRejectedAndBackToBackIsAllowed() {
        slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Recurring host", "Three dated meetings.", ScheduleType.WEEKLY,
                LocalDate.of(2026, 10, 20), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                SlotMode.ONLINE, null, null, 3, 3));

        org.assertj.core.api.Assertions.assertThatThrownBy(() -> slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Later overlap", "Overlaps only the second occurrence.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 27), LocalTime.of(10, 30), LocalTime.of(11, 30), null,
                SlotMode.ONLINE, null, null, 3)))
                .isInstanceOf(com.uniconnect.shared.exception.ConflictException.class);

        var adjacent = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Back to back", "Starts exactly when the recurring meeting ends.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 27), LocalTime.of(11, 0), LocalTime.of(12, 0), null,
                SlotMode.ONLINE, null, null, 3));
        assertThat(adjacent.slotId()).isNotNull();
    }

    @Test
    void scheduleEditPreservesPastAndOngoingOccurrencesAndChangesOnlyFutureMeetings() {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Editable series", "Past and ongoing dates must remain authoritative.", ScheduleType.WEEKLY,
                LocalDate.of(2026, 10, 8), LocalTime.of(15, 0), LocalTime.of(17, 0), null,
                SlotMode.ONLINE, null, null, 3, 3));

        var updated = slotService.updateSlot(mentorStudent, slot.slotId(), new UpdateSlotRequest(
                "Editable series", "Only the future date changes.", ScheduleType.WEEKLY,
                LocalDate.of(2026, 10, 8), LocalTime.of(18, 0), LocalTime.of(19, 0), null,
                SlotMode.ONLINE, null, null, 3, 3));

        assertThat(updated.occurrenceDetails()).extracting(o -> o.startsAt())
                .containsExactly(
                        LocalDateTime.of(2026, 10, 8, 15, 0),
                        LocalDateTime.of(2026, 10, 15, 15, 0),
                        LocalDateTime.of(2026, 10, 22, 18, 0));
        assertThat(updated.occurrenceDetails().get(1).ongoing()).isTrue();
        assertThat(updated.nextOccurrenceStartsAt()).isEqualTo(LocalDateTime.of(2026, 10, 22, 18, 0));
    }

    @Test
    void joinChecksApplicantsHostedMeetingsWhileEditIgnoresMenteeHostingCommitments() {
        mentorService.registerMentor(menteeStudent1, new MentorRegistrationRequest(
                "I also host mentorship sessions for concurrency validation.",
                List.of(new ExpertiseRequest("Java", "Application architecture"))));
        slotService.createSlot(menteeStudent1, new CreateSlotRequest(
                "Applicant hosted", "The applicant hosts this meeting.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 22), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                SlotMode.ONLINE, null, null, 3));

        var conflicting = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Conflicting enrollment", "Joining would conflict with an applicant-hosted meeting.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 22), LocalTime.of(10, 30), LocalTime.of(11, 30), null,
                SlotMode.ONLINE, null, null, 3));
        org.assertj.core.api.Assertions.assertThatThrownBy(
                        () -> slotService.joinSlot(menteeStudent1, conflicting.slotId(), null))
                .isInstanceOf(com.uniconnect.shared.exception.ConflictException.class);
        slotService.cancelSlot(mentorStudent, conflicting.slotId());

        var editable = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Mentee commitment ignored", "Initially back to back with the mentee-hosted meeting.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 22), LocalTime.of(11, 0), LocalTime.of(12, 0), null,
                SlotMode.ONLINE, null, null, 3));
        slotService.joinSlot(menteeStudent1, editable.slotId(), null);
        var updated = slotService.updateSlot(mentorStudent, editable.slotId(), new UpdateSlotRequest(
                "Mentee commitment ignored", "The host may edit despite a mentee hosting elsewhere.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 22), LocalTime.of(10, 30), LocalTime.of(11, 30), null,
                SlotMode.ONLINE, null, null, 3));
        assertThat(updated.nextOccurrenceStartsAt()).isEqualTo(LocalDateTime.of(2026, 10, 22, 10, 30));
    }

    @Test
    void closeReopenAvailabilityAndCancelHaveIndependentIdempotentSemantics() {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Lifecycle controls", "Close reopen and cancellation semantics.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 25), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                SlotMode.ONLINE, null, null, 2));
        slotService.joinSlot(menteeStudent1, slot.slotId(), null);
        slotService.closeSlot(mentorStudent, slot.slotId());
        int afterFirstClose = notifications.findAll().size();
        slotService.closeSlot(mentorStudent, slot.slotId());
        assertThat(notifications.findAll()).hasSize(afterFirstClose);
        mentorService.updateStatus(mentorStudent, new com.uniconnect.mentorship.dto.MentorStatusUpdateRequest(MentorStatus.UNAVAILABLE));
        assertThat(slotService.getSlot(mentorStudent, slot.slotId()).status().name()).isEqualTo("CLOSED");
        org.assertj.core.api.Assertions.assertThatThrownBy(() -> slotService.joinSlot(menteeStudent2, slot.slotId(), null)).isInstanceOf(com.uniconnect.shared.exception.ConflictException.class);
        mentorService.updateStatus(mentorStudent, new com.uniconnect.mentorship.dto.MentorStatusUpdateRequest(MentorStatus.AVAILABLE));
        assertThat(slotService.getSlot(mentorStudent, slot.slotId()).status().name()).isEqualTo("CLOSED");
        assertThat(slotService.reopenSlot(mentorStudent, slot.slotId()).status().name()).isEqualTo("OPEN");
        int afterFirstReopen = notifications.findAll().size();
        assertThat(slotService.reopenSlot(mentorStudent, slot.slotId()).status().name()).isEqualTo("OPEN");
        assertThat(notifications.findAll()).hasSize(afterFirstReopen);
        int before = notifications.findAll().size();
        slotService.cancelSlot(mentorStudent, slot.slotId());
        int after = notifications.findAll().size();
        slotService.cancelSlot(mentorStudent, slot.slotId());
        assertThat(notifications.findAll()).hasSize(after);
        assertThat(after).isGreaterThan(before);
    }

    @Test
    void finalPlaceConcurrentJoinsCannotOverbook() throws Exception {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Last place", "Only one participant can enroll.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 25), LocalTime.of(13, 0), LocalTime.of(14, 0), null,
                SlotMode.ONLINE, null, null, 1));
        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch ready = new CountDownLatch(2), start = new CountDownLatch(1);
        AtomicInteger successes = new AtomicInteger();
        try {
            List<Future<Object>> futures = List.of(menteeStudent1, menteeStudent2).stream().map(principal -> pool.submit(() -> {
                ready.countDown(); start.await();
                try { slotService.joinSlot(principal, slot.slotId(), null); successes.incrementAndGet(); }
                catch (com.uniconnect.shared.exception.ConflictException ignored) {}
                return null;
            })).toList();
            assertThat(ready.await(5, TimeUnit.SECONDS)).isTrue(); start.countDown();
            for (Future<?> future : futures) future.get(10, TimeUnit.SECONDS);
        } finally { pool.shutdownNow(); }
        assertThat(successes).hasValue(1);
        assertThat(slotService.getSlot(mentorStudent, slot.slotId()).currentMenteeCount()).isEqualTo(1);
    }

    @Test
    void slotLifecycleCloseCancelUpdateAndSessionTracking() throws Exception {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Lifecycle Test Slot",
                "Testing lifecycle operations.",
                ScheduleType.ONE_TIME,
                LocalDate.parse("2026-10-25"),
                LocalTime.parse("16:00:00"),
                LocalTime.parse("17:00:00"),
                null,
                SlotMode.ONLINE,
                null,
                null,
                4
        ));

        // Mentee1 joins
        slotService.joinSlot(menteeStudent1, slot.slotId(), new EnrollSlotRequest("Hello", "Goal"));

        // Update slot details
        String updateJson = """
                {
                    "topic": "Updated Topic",
                    "description": "Updated description with sufficient length.",
                    "scheduleType": "ONE_TIME",
                    "startDate": "2026-10-26",
                    "startTime": "16:00:00",
                    "endTime": "17:30:00",
                    "mode": "ONLINE",
                    "capacity": 3
                }
                """;

        mvc.perform(put("/api/v1/mentorship/slots/" + slot.slotId())
                        .header("Authorization", "Bearer " + mentorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.topic").value("Updated Topic"))
                .andExpect(jsonPath("$.capacity").value(3));

        // Capacity cannot be reduced below current mentee count
        String invalidCapacityJson = """
                {
                    "topic": "Updated Topic",
                    "description": "Updated description with sufficient length.",
                    "scheduleType": "ONE_TIME",
                    "startDate": "2026-10-26",
                    "startTime": "16:00:00",
                    "endTime": "17:30:00",
                    "mode": "ONLINE",
                    "capacity": 0
                }
                """;
        mvc.perform(put("/api/v1/mentorship/slots/" + slot.slotId())
                        .header("Authorization", "Bearer " + mentorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidCapacityJson))
                .andExpect(status().isBadRequest());

        // Track sessions: my-mentoring
        mvc.perform(get("/api/v1/mentorship/slots/my-mentoring")
                        .header("Authorization", "Bearer " + mentorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].topic").value("Updated Topic"));

        // Track sessions: my-enrolled
        mvc.perform(get("/api/v1/mentorship/slots/my-enrolled")
                        .header("Authorization", "Bearer " + mentee1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].slotTopic").value("Updated Topic"))
                .andExpect(jsonPath("$[0].enrollmentId").isNumber())
                .andExpect(jsonPath("$[0].status").value("ACTIVE"));

        // Additive card-ready current-series endpoint.
        mvc.perform(get("/api/v1/mentorship/slots/my-current-series")
                        .header("Authorization", "Bearer " + mentee1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].topic").value("Updated Topic"))
                .andExpect(jsonPath("$[0].status").value("OPEN"));

        // Close slot
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/close")
                        .header("Authorization", "Bearer " + mentorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CLOSED"));

        // New join rejected on CLOSED slot
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/join")
                        .header("Authorization", "Bearer " + mentee2Token))
                .andExpect(status().isConflict());

        // Cancel slot
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/cancel")
                        .header("Authorization", "Bearer " + mentorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELLED"));
    }

    @Test
    void joiningAndLeavingSlotDispatchesExpectedNotifications() throws Exception {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Notifications Test Session", "Description", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 20), LocalTime.of(14, 0), LocalTime.of(15, 0),
                null, SlotMode.ONLINE, null, "https://meet.uniconnect.local/test", 5
        ));

        // Mentee joins slot
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/join")
                        .header("Authorization", "Bearer " + mentee1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"joinMessage\":\"Excited to attend!\",\"learningGoal\":\"Learn testing\"}"))
                .andExpect(status().isOk());

        // Mentor received notification
        var mentorNotifs = notifications.findAll().stream()
                .filter(n -> n.getRecipientId().equals(mentorStudent.userId()))
                .toList();
        assertThat(mentorNotifs).isNotEmpty();
        assertThat(mentorNotifs.get(0).getType()).isEqualTo(com.uniconnect.notification.domain.NotificationType.MENTORSHIP_SLOT_JOINED);

        // Mentee received notification
        var menteeNotifs = notifications.findAll().stream()
                .filter(n -> n.getRecipientId().equals(menteeStudent1.userId()))
                .toList();
        assertThat(menteeNotifs).isNotEmpty();
        assertThat(menteeNotifs.get(0).getType()).isEqualTo(com.uniconnect.notification.domain.NotificationType.MENTORSHIP_SLOT_JOINED);

        // Mentee leaves slot
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/leave")
                        .header("Authorization", "Bearer " + mentee1Token))
                .andExpect(status().isOk());

        // Mentor received left notification
        var mentorLeaveNotifs = notifications.findAll().stream()
                .filter(n -> n.getRecipientId().equals(mentorStudent.userId())
                        && n.getType() == com.uniconnect.notification.domain.NotificationType.MENTORSHIP_SLOT_LEFT)
                .toList();
        assertThat(mentorLeaveNotifs).isNotEmpty();
    }

    @Test
    void mentorCanRetrieveSlotEnrollments() throws Exception {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Attendee Roster Test", "Description", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 20), LocalTime.of(16, 0), LocalTime.of(17, 0),
                null, SlotMode.ONLINE, null, "https://meet.uniconnect.local/roster", 5
        ));

        // Mentee joins
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/join")
                        .header("Authorization", "Bearer " + mentee1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"joinMessage\":\"Looking forward to it!\",\"learningGoal\":\"Core concepts\"}"))
                .andExpect(status().isOk());

        // Mentor can view attendees
        mvc.perform(get("/api/v1/mentorship/slots/" + slot.slotId() + "/enrollments")
                        .header("Authorization", "Bearer " + mentorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].menteeName").value("Mentee One"))
                .andExpect(jsonPath("$[0].joinMessage").value("Looking forward to it!"))
                .andExpect(jsonPath("$[0].learningGoal").value("Core concepts"));

        // Mentee cannot view attendees list of other mentor's slot
        mvc.perform(get("/api/v1/mentorship/slots/" + slot.slotId() + "/enrollments")
                        .header("Authorization", "Bearer " + mentee1Token))
                .andExpect(status().isForbidden());
    }

    @Test
    void updatingAndCancellingSlotDispatchesNotificationsToMentees() throws Exception {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Update & Cancel Notifications Session", "Description", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 22), LocalTime.of(10, 0), LocalTime.of(11, 0),
                null, SlotMode.ONLINE, null, "https://meet.uniconnect.local/session", 5
        ));

        // Mentee 1 and Mentee 2 join slot
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/join")
                        .header("Authorization", "Bearer " + mentee1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"joinMessage\":\"Hi\",\"learningGoal\":\"Goal\"}"))
                .andExpect(status().isOk());

        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/join")
                        .header("Authorization", "Bearer " + mentee2Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"joinMessage\":\"Hi 2\",\"learningGoal\":\"Goal 2\"}"))
                .andExpect(status().isOk());

        // Update slot details
        mvc.perform(put("/api/v1/mentorship/slots/" + slot.slotId())
                        .header("Authorization", "Bearer " + mentorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "topic": "Rescheduled Notifications Session",
                                    "description": "Updated Description",
                                    "scheduleType": "ONE_TIME",
                                    "startDate": "2026-10-22",
                                    "startTime": "11:00:00",
                                    "endTime": "12:00:00",
                                    "mode": "ONLINE",
                                    "meetingLink": "https://meet.uniconnect.local/rescheduled",
                                    "capacity": 5
                                }
                                """))
                .andExpect(status().isOk());

        // Active mentees received update notification
        var updateNotifsMentee1 = notifications.findAll().stream()
                .filter(n -> n.getRecipientId().equals(menteeStudent1.userId())
                        && n.getType() == com.uniconnect.notification.domain.NotificationType.MENTORSHIP_SLOT_UPDATED)
                .toList();
        assertThat(updateNotifsMentee1).isNotEmpty();

        var updateNotifsMentee2 = notifications.findAll().stream()
                .filter(n -> n.getRecipientId().equals(menteeStudent2.userId())
                        && n.getType() == com.uniconnect.notification.domain.NotificationType.MENTORSHIP_SLOT_UPDATED)
                .toList();
        assertThat(updateNotifsMentee2).isNotEmpty();

        // Cancel slot
        mvc.perform(post("/api/v1/mentorship/slots/" + slot.slotId() + "/cancel")
                        .header("Authorization", "Bearer " + mentorToken))
                .andExpect(status().isOk());

        // Active mentees received cancel notification
        var cancelNotifsMentee1 = notifications.findAll().stream()
                .filter(n -> n.getRecipientId().equals(menteeStudent1.userId())
                        && n.getType() == com.uniconnect.notification.domain.NotificationType.MENTORSHIP_SLOT_CANCELLED)
                .toList();
        assertThat(cancelNotifsMentee1).isNotEmpty();

        var cancelNotifsMentee2 = notifications.findAll().stream()
                .filter(n -> n.getRecipientId().equals(menteeStudent2.userId())
                        && n.getType() == com.uniconnect.notification.domain.NotificationType.MENTORSHIP_SLOT_CANCELLED)
                .toList();
        assertThat(cancelNotifsMentee2).isNotEmpty();
    }

    @Test
    void defaultRecurringRequestReturnsAllTwelvePersistedMeetings() throws Exception {
        mvc.perform(post("/api/v1/mentorship/slots")
                        .header("Authorization", "Bearer " + mentorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "topic":"Compatibility default",
                                  "description":"An omitted recurring bound keeps the established default.",
                                  "scheduleType":"WEEKLY",
                                  "startDate":"2026-10-20",
                                  "startTime":"09:00:00",
                                  "endTime":"10:00:00",
                                  "mode":"ONLINE",
                                  "capacity":4
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.meetingCount").value(12))
                .andExpect(jsonPath("$.occurrences.length()").value(12))
                .andExpect(jsonPath("$.occurrenceDetails.length()").value(12));
        assertThat(jdbc.queryForObject(
                "select count(*) from mentorship_occurrences", Integer.class)).isEqualTo(12);
    }

    @Test
    void metadataAndNoOpUpdatesPreserveOccurrencesAndDistinctEditsNotifyAtSameInstant() {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Stable occurrences", "Future rows keep stable identities.", ScheduleType.WEEKLY,
                LocalDate.of(2026, 10, 20), LocalTime.of(9, 0), LocalTime.of(10, 0), null,
                SlotMode.ONLINE, null, "https://meet.uniconnect.local/stable", 3, 3));
        slotService.joinSlot(menteeStudent1, slot.slotId(), null);
        List<Long> originalIds = slot.occurrenceDetails().stream().map(o -> o.occurrenceId()).toList();

        UpdateSlotRequest firstEdit = new UpdateSlotRequest(
                "Stable occurrences edited", "Future rows keep stable identities.", ScheduleType.WEEKLY,
                LocalDate.of(2026, 10, 20), LocalTime.of(9, 0), LocalTime.of(10, 0), null,
                SlotMode.ONLINE, null, "https://meet.uniconnect.local/stable", 3, 3);
        var first = slotService.updateSlot(mentorStudent, slot.slotId(), firstEdit);
        assertThat(first.occurrenceDetails()).extracting(o -> o.occurrenceId()).containsExactlyElementsOf(originalIds);
        int afterFirst = countNotifications(com.uniconnect.notification.domain.NotificationType.MENTORSHIP_SLOT_UPDATED);

        var retry = slotService.updateSlot(mentorStudent, slot.slotId(), firstEdit);
        assertThat(retry.occurrenceDetails()).extracting(o -> o.occurrenceId()).containsExactlyElementsOf(originalIds);
        assertThat(countNotifications(com.uniconnect.notification.domain.NotificationType.MENTORSHIP_SLOT_UPDATED))
                .isEqualTo(afterFirst);

        var second = slotService.updateSlot(mentorStudent, slot.slotId(), new UpdateSlotRequest(
                "Stable occurrences edited again", "Future rows keep stable identities.", ScheduleType.WEEKLY,
                LocalDate.of(2026, 10, 20), LocalTime.of(9, 0), LocalTime.of(10, 0), null,
                SlotMode.ONLINE, null, "https://meet.uniconnect.local/stable", 3, 3));
        assertThat(second.occurrenceDetails()).extracting(o -> o.occurrenceId()).containsExactlyElementsOf(originalIds);
        assertThat(countNotifications(com.uniconnect.notification.domain.NotificationType.MENTORSHIP_SLOT_UPDATED))
                .isEqualTo(afterFirst + 1);
        assertThat(jdbc.queryForList(
                "select event_key from notifications where type='MENTORSHIP_SLOT_UPDATED'", String.class))
                .doesNotHaveDuplicates();
    }

    @Test
    void cancellationDuringOngoingMeetingPreservesOccurrenceAndHistoryWithoutLink() {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Ongoing cancellation", "The current meeting remains part of history.", ScheduleType.WEEKLY,
                LocalDate.of(2026, 10, 8), LocalTime.of(15, 0), LocalTime.of(17, 0), null,
                SlotMode.ONLINE, null, "https://meet.uniconnect.local/ongoing", 3, 3));
        var enrollment = slotService.joinSlot(menteeStudent1, slot.slotId(), null);

        var cancelled = slotService.cancelSlot(mentorStudent, slot.slotId());
        assertThat(cancelled.occurrenceDetails().get(0).cancelledAt()).isNull();
        assertThat(cancelled.occurrenceDetails().get(1).ongoing()).isTrue();
        assertThat(cancelled.occurrenceDetails().get(1).cancelledAt()).isNull();
        assertThat(cancelled.occurrenceDetails().get(2).cancelledAt()).isNotNull();
        var history = slotService.getEnrollment(menteeStudent1, enrollment.enrollmentId());
        assertThat(history.status()).isEqualTo(com.uniconnect.mentorship.domain.EnrollmentStatus.CANCELLED);
        assertThat(history.meetingLink()).isNull();
        assertThat(history.ongoingOccurrenceStartsAt()).isEqualTo(LocalDateTime.of(2026, 10, 15, 15, 0));
    }

    @Test
    void privacyAndPersonalHttpContractsHoldAcrossResponsePaths() throws Exception {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Private paths", "Links and private notes stay audience-scoped.", ScheduleType.WEEKLY,
                LocalDate.of(2026, 10, 20), LocalTime.of(15, 0), LocalTime.of(16, 0), null,
                SlotMode.ONLINE, null, "https://meet.uniconnect.local/private-paths", 3, 2));
        slotService.joinSlot(menteeStudent1, slot.slotId(), new EnrollSlotRequest("private note", "private goal"));

        mvc.perform(get("/api/v1/mentorship/slots").header("Authorization", "Bearer " + mentee2Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].meetingLink").doesNotExist())
                .andExpect(jsonPath("$.items[0].joinMessage").doesNotExist());
        mvc.perform(get("/api/v1/mentorship/slots/" + slot.slotId())
                        .header("Authorization", "Bearer " + mentee2Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.meetingLink").doesNotExist())
                .andExpect(jsonPath("$.occurrenceDetails[0].meetingLink").doesNotExist());
        mvc.perform(get("/api/v1/mentorship/slots/my-enrolled")
                        .header("Authorization", "Bearer " + mentee1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].enrollmentId").isNumber())
                .andExpect(jsonPath("$[0].joinMessage").value("private note"))
                .andExpect(jsonPath("$[0].status").value("ACTIVE"));
        mvc.perform(get("/api/v1/mentorship/slots/my-current-series")
                        .header("Authorization", "Bearer " + mentee1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].topic").value("Private paths"))
                .andExpect(jsonPath("$[0].meetingLink").value("https://meet.uniconnect.local/private-paths"))
                .andExpect(jsonPath("$[0].enrollmentId").doesNotExist());
        mvc.perform(get("/api/v1/mentorship/slots/" + slot.slotId() + "/enrollments")
                        .header("Authorization", "Bearer " + mentee2Token))
                .andExpect(status().isForbidden());
    }

    @Test
    void derivedReadsDoNotPersistFullCompletedOrRecountState() {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Read only derivation", "Effective state is response-only.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 20), LocalTime.of(15, 0), LocalTime.of(16, 0), null,
                SlotMode.ONLINE, null, null, 1));
        slotService.joinSlot(menteeStudent1, slot.slotId(), null);
        jdbc.update("update mentorship_slots set current_mentee_count=0 where slot_id=?", slot.slotId());

        assertThat(slotService.getSlot(menteeStudent2, slot.slotId()).status()).isEqualTo(com.uniconnect.mentorship.domain.SlotStatus.FULL);
        assertThat(jdbc.queryForObject("select status from mentorship_slots where slot_id=?", String.class, slot.slotId()))
                .isEqualTo("OPEN");
        assertThat(jdbc.queryForObject("select current_mentee_count from mentorship_slots where slot_id=?", Integer.class, slot.slotId()))
                .isZero();

        jdbc.update("update mentorship_occurrences set starts_at=?, ends_at=? where slot_id=?",
                LocalDateTime.of(2026, 10, 14, 15, 0),
                LocalDateTime.of(2026, 10, 14, 16, 0), slot.slotId());
        assertThat(slotService.getSlot(menteeStudent2, slot.slotId()).status()).isEqualTo(com.uniconnect.mentorship.domain.SlotStatus.COMPLETED);
        assertThat(slotService.browseSlots(menteeStudent2, null, null, 0, 20).items()).isEmpty();
        assertThat(jdbc.queryForObject("select status from mentorship_slots where slot_id=?", String.class, slot.slotId()))
                .isEqualTo("OPEN");
        assertThat(jdbc.queryForObject("select status from mentorship_enrollments where slot_id=?", String.class, slot.slotId()))
                .isEqualTo("ACTIVE");
    }

    @Test
    void concurrentDuplicateJoinAndHostedCreatesSerialize() throws Exception {
        var slot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Duplicate join", "Only one active period may be created.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 25), LocalTime.of(9, 0), LocalTime.of(10, 0), null,
                SlotMode.ONLINE, null, null, 3));
        AtomicInteger joins = new AtomicInteger();
        List<Throwable> joinErrors = runConcurrently(
                () -> { slotService.joinSlot(menteeStudent1, slot.slotId(), null); joins.incrementAndGet(); },
                () -> { slotService.joinSlot(menteeStudent1, slot.slotId(), null); joins.incrementAndGet(); });
        assertThat(joins).hasValue(1);
        assertThat(joinErrors).hasSize(1).allMatch(com.uniconnect.shared.exception.ConflictException.class::isInstance);
        assertThat(jdbc.queryForObject(
                "select count(*) from mentorship_enrollments where slot_id=? and status='ACTIVE'",
                Integer.class, slot.slotId())).isEqualTo(1);

        AtomicInteger creates = new AtomicInteger();
        List<Throwable> createErrors = runConcurrently(
                () -> { slotService.createSlot(mentorStudent, new CreateSlotRequest(
                        "Concurrent host A", "Overlapping hosted series.", ScheduleType.ONE_TIME,
                        LocalDate.of(2026, 10, 26), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                        SlotMode.ONLINE, null, null, 2)); creates.incrementAndGet(); },
                () -> { slotService.createSlot(mentorStudent, new CreateSlotRequest(
                        "Concurrent host B", "Overlapping hosted series.", ScheduleType.ONE_TIME,
                        LocalDate.of(2026, 10, 26), LocalTime.of(10, 30), LocalTime.of(11, 30), null,
                        SlotMode.ONLINE, null, null, 2)); creates.incrementAndGet(); });
        assertThat(creates).hasValue(1);
        assertThat(createErrors).hasSize(1).allMatch(com.uniconnect.shared.exception.ConflictException.class::isInstance);
    }

    @Test
    void joinSerializesWithCapacityClosureCancellationAndScheduleEdit() throws Exception {
        var capacitySlot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Capacity race", "Join and capacity reduction serialize.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 27), LocalTime.of(9, 0), LocalTime.of(10, 0), null,
                SlotMode.ONLINE, null, null, 2));
        slotService.joinSlot(menteeStudent1, capacitySlot.slotId(), null);
        List<Throwable> capacityErrors = runConcurrently(
                () -> slotService.joinSlot(menteeStudent2, capacitySlot.slotId(), null),
                () -> slotService.updateSlot(mentorStudent, capacitySlot.slotId(), new UpdateSlotRequest(
                        "Capacity race", "Join and capacity reduction serialize.", ScheduleType.ONE_TIME,
                        LocalDate.of(2026, 10, 27), LocalTime.of(9, 0), LocalTime.of(10, 0), null,
                        SlotMode.ONLINE, null, null, 1)));
        var capacityResult = slotService.getSlot(mentorStudent, capacitySlot.slotId());
        assertThat(capacityResult.currentMenteeCount()).isLessThanOrEqualTo(capacityResult.capacity());
        assertThat(capacityErrors).hasSize(1).allMatch(error ->
                error instanceof com.uniconnect.shared.exception.ConflictException
                        || error instanceof com.uniconnect.shared.exception.BadRequestException);

        var closeSlot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Close race", "Join and closure serialize.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 28), LocalTime.of(9, 0), LocalTime.of(10, 0), null,
                SlotMode.ONLINE, null, null, 2));
        List<Throwable> closeErrors = runConcurrently(
                () -> slotService.joinSlot(menteeStudent2, closeSlot.slotId(), null),
                () -> slotService.closeSlot(mentorStudent, closeSlot.slotId()));
        assertThat(closeErrors).allMatch(com.uniconnect.shared.exception.ConflictException.class::isInstance);
        assertThat(slotService.getSlot(mentorStudent, closeSlot.slotId()).status())
                .isEqualTo(com.uniconnect.mentorship.domain.SlotStatus.CLOSED);

        var cancelSlot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Cancel race", "Join and cancellation serialize.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 29), LocalTime.of(9, 0), LocalTime.of(10, 0), null,
                SlotMode.ONLINE, null, null, 2));
        List<Throwable> cancelErrors = runConcurrently(
                () -> slotService.joinSlot(menteeStudent2, cancelSlot.slotId(), null),
                () -> slotService.cancelSlot(mentorStudent, cancelSlot.slotId()));
        assertThat(cancelErrors).allMatch(com.uniconnect.shared.exception.ConflictException.class::isInstance);
        var cancelResult = slotService.getSlot(mentorStudent, cancelSlot.slotId());
        assertThat(cancelResult.status()).isEqualTo(com.uniconnect.mentorship.domain.SlotStatus.CANCELLED);
        assertThat(cancelResult.currentMenteeCount()).isZero();

        mentorService.registerMentor(menteeStudent2, new MentorRegistrationRequest(
                "Hosts a conflicting meeting for the edit race.",
                List.of(new ExpertiseRequest("Concurrency", "Schedule locking"))));
        slotService.createSlot(menteeStudent2, new CreateSlotRequest(
                "Applicant hosted race", "Conflicts only after target edit.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 30), LocalTime.of(10, 0), LocalTime.of(11, 0), null,
                SlotMode.ONLINE, null, null, 2));
        var editSlot = slotService.createSlot(mentorStudent, new CreateSlotRequest(
                "Edit race", "Starts adjacent before edit.", ScheduleType.ONE_TIME,
                LocalDate.of(2026, 10, 30), LocalTime.of(11, 0), LocalTime.of(12, 0), null,
                SlotMode.ONLINE, null, null, 2));
        List<Throwable> editErrors = runConcurrently(
                () -> slotService.joinSlot(menteeStudent2, editSlot.slotId(), null),
                () -> slotService.updateSlot(mentorStudent, editSlot.slotId(), new UpdateSlotRequest(
                        "Edit race", "Overlaps applicant-hosted meeting after edit.", ScheduleType.ONE_TIME,
                        LocalDate.of(2026, 10, 30), LocalTime.of(10, 30), LocalTime.of(11, 30), null,
                        SlotMode.ONLINE, null, null, 2)));
        assertThat(editErrors).allMatch(com.uniconnect.shared.exception.ConflictException.class::isInstance);
        assertThat(slotService.getSlot(mentorStudent, editSlot.slotId()).nextOccurrenceStartsAt())
                .isEqualTo(LocalDateTime.of(2026, 10, 30, 10, 30));
    }

    private int countNotifications(com.uniconnect.notification.domain.NotificationType type) {
        return (int) notifications.findAll().stream().filter(notification -> notification.getType() == type).count();
    }

    private List<Throwable> runConcurrently(Runnable first, Runnable second) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        List<Throwable> errors = new CopyOnWriteArrayList<>();
        try {
            List<? extends Future<?>> futures = List.of(first, second).stream().map(task -> pool.submit(() -> {
                ready.countDown();
                start.await();
                try {
                    task.run();
                } catch (Throwable error) {
                    errors.add(error);
                }
                return null;
            })).toList();
            assertThat(ready.await(5, TimeUnit.SECONDS)).isTrue();
            start.countDown();
            for (Future<?> future : futures) {
                future.get(10, TimeUnit.SECONDS);
            }
        } finally {
            pool.shutdownNow();
        }
        return errors;
    }
}
