package com.uniconnect.mentorship;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.mentorship.domain.ScheduleType;
import com.uniconnect.mentorship.domain.SlotMode;
import com.uniconnect.mentorship.dto.CreateSlotRequest;
import com.uniconnect.mentorship.dto.ExpertiseRequest;
import com.uniconnect.mentorship.dto.MentorRegistrationRequest;
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
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import org.junit.jupiter.api.condition.EnabledIf;

import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@EnabledIf(value = "isPostgresAvailable", disabledReason = "PostgreSQL smoke test database 'uniconnect_smoke' is not reachable")
class PostgresMentorshipSmokeTests {

    private static final String SMOKE_DB_URL = System.getProperty("postgres.smoke.url",
            System.getenv("POSTGRES_SMOKE_URL") != null ? System.getenv("POSTGRES_SMOKE_URL") : "jdbc:postgresql://localhost:5432/uniconnect_smoke");
    private static final String SMOKE_DB_USER = System.getProperty("postgres.smoke.username",
            System.getenv("POSTGRES_SMOKE_USER") != null ? System.getenv("POSTGRES_SMOKE_USER") : "postgres");
    private static final String SMOKE_DB_PASS = System.getProperty("postgres.smoke.password",
            System.getenv("POSTGRES_SMOKE_PASSWORD") != null ? System.getenv("POSTGRES_SMOKE_PASSWORD") : "");

    static boolean isPostgresAvailable() {
        try {
            java.sql.DriverManager.setLoginTimeout(2);
            try (java.sql.Connection conn = java.sql.DriverManager.getConnection(SMOKE_DB_URL, SMOKE_DB_USER, SMOKE_DB_PASS)) {
                return true;
            }
        } catch (Exception e) {
            return false;
        }
    }

    @DynamicPropertySource
    static void configurePostgres(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", () -> SMOKE_DB_URL);
        registry.add("spring.datasource.username", () -> SMOKE_DB_USER);
        registry.add("spring.datasource.password", () -> SMOKE_DB_PASS);
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
    }

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

    private SessionPrincipal admin, mentorStudent, menteeStudent;
    private String mentorToken, menteeToken;
    private Long degreeId;
    private static final Instant NOW = Instant.parse("2026-10-15T12:00:00Z");

    @BeforeEach
    void setup() {
        clean();
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);

        admin = sessions.authenticate(account("PgAdmin", PlatformRole.SYSTEM_ADMIN));
        mentorToken = account("PgMentor", PlatformRole.STUDENT);
        menteeToken = account("PgMentee", PlatformRole.STUDENT);

        mentorStudent = sessions.authenticate(mentorToken);
        menteeStudent = sessions.authenticate(menteeToken);

        var deptId = catalog.createDepartment(admin, new DepartmentRequest("Postgres Engineering", "PGE")).id();
        var progId = catalog.createProgramme(admin, new ProgrammeRequest("Systems Development", "SYS", deptId)).id();
        degreeId = catalog.createDegree(admin, new DegreeRequest(progId, DegreeLevel.BACHELOR, 4, 1, 4, true)).id();

        profiles.saveStudent(mentorStudent, new StudentProfileRequest(
                "Postgres Mentor", degreeId, "Bio", null,
                List.of("Distributed Systems"), List.of(), "PG-001", 3, 2027, true, true
        ));
        profiles.saveStudent(menteeStudent, new StudentProfileRequest(
                "Postgres Mentee", degreeId, "Bio", null,
                List.of("SQL"), List.of(), "PG-002", 2, 2028, true, true
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
    void postgresSmokeTestPeerMentorshipFlows() throws Exception {
        // 1. Mentor registration on PostgreSQL
        String regBody = """
                {
                    "mentoringBio": "Experienced systems mentor on PostgreSQL database.",
                    "expertise": [
                        {"topic": "Distributed Systems", "description": "Consensus protocols and replication"}
                    ]
                }
                """;

        var regResult = mvc.perform(post("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + mentorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(regBody))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.fullName").value("Postgres Mentor"))
                .andReturn();

        // 2. myProfile on PostgreSQL (tests non-failing transaction strategy with lockActiveAccount)
        mvc.perform(get("/api/v1/mentorship/mentors/me")
                        .header("Authorization", "Bearer " + mentorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fullName").value("Postgres Mentor"))
                .andExpect(jsonPath("$.departmentName").value("Postgres Engineering"))
                .andExpect(jsonPath("$.yearOfStudy").value(3));

        // 3. searchMentors directory on PostgreSQL
        mvc.perform(get("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + menteeToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].fullName").value("Postgres Mentor"));

        // 4. Create and browse a mentorship slot on PostgreSQL
        String slotJson = """
                {
                    "topic": "PostgreSQL Internals",
                    "description": "Deep dive into MVCC and write-ahead logging.",
                    "scheduleType": "ONE_TIME",
                    "startDate": "2026-10-28",
                    "startTime": "10:00:00",
                    "endTime": "11:30:00",
                    "mode": "ONLINE",
                    "meetingLink": "https://meet.uniconnect.local/pg-internals",
                    "capacity": 10
                }
                """;

        mvc.perform(post("/api/v1/mentorship/slots")
                        .header("Authorization", "Bearer " + mentorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(slotJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.topic").value("PostgreSQL Internals"))
                .andExpect(jsonPath("$.capacity").value(10))
                .andExpect(jsonPath("$.status").value("OPEN"));

        // Mentee browses slot on PostgreSQL
        mvc.perform(get("/api/v1/mentorship/slots?topic=internals")
                        .header("Authorization", "Bearer " + menteeToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].topic").value("PostgreSQL Internals"));
    }
}
