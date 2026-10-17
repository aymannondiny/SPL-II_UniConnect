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
    @Autowired JdbcTemplate jdbc;
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
                "mentorship_enrollments", "mentorship_occurrences", "mentorship_slots",
                "mentor_expertise", "mentor_profiles", "profile_skills", "profile_interests", "personal_profiles",
                "skills", "interests", "programme_degrees", "programmes", "departments",
                "password_reset_tokens", "email_verification_tokens", "authenticated_sessions", "users")) {
            jdbc.update("delete from " + table);
        }
    }

    private String account(String name, PlatformRole role) {
        User user = User.register(name, name.toLowerCase(Locale.ROOT) + "@iut-dhaka.edu", passwords.encode("password123"), role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
        users.saveAndFlush(user);
        return sessions.login(new LoginRequest(user.getEmail(), "password123")).accessToken();
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
                .andExpect(jsonPath("$[0].slotTopic").value("Updated Topic"));

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
}
