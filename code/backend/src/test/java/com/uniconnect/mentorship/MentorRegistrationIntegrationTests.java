package com.uniconnect.mentorship;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.mentorship.domain.MentorStatus;
import com.uniconnect.mentorship.dto.ExpertiseRequest;
import com.uniconnect.mentorship.dto.MentorRegistrationRequest;
import com.uniconnect.mentorship.dto.MentorStatusUpdateRequest;
import com.uniconnect.mentorship.service.PeerMentorService;
import com.uniconnect.profile.domain.DegreeLevel;
import com.uniconnect.profile.dto.AlumniProfileRequest;
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
import java.time.LocalDateTime;
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
class MentorRegistrationIntegrationTests {

    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired SessionService sessions;
    @Autowired PersonalProfileService profiles;
    @Autowired AcademicCatalogService catalog;
    @Autowired PeerMentorService mentorService;
    @Autowired JdbcTemplate jdbc;
    @MockitoBean Clock clock;

    private SessionPrincipal admin, seniorStudent, juniorStudent, alumniUser;
    private String seniorToken, juniorToken, alumniToken;
    private Long degreeId;
    private static final Instant NOW = Instant.parse("2026-10-11T12:00:00Z");

    @BeforeEach
    void setup() {
        clean();
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);

        admin = sessions.authenticate(account("Admin", PlatformRole.SYSTEM_ADMIN));
        seniorToken = account("Senior", PlatformRole.STUDENT);
        juniorToken = account("Junior", PlatformRole.STUDENT);
        alumniToken = account("Alumni", PlatformRole.ALUMNI);

        seniorStudent = sessions.authenticate(seniorToken);
        juniorStudent = sessions.authenticate(juniorToken);
        alumniUser = sessions.authenticate(alumniToken);

        var deptId = catalog.createDepartment(admin, new DepartmentRequest("Computing", "CSE")).id();
        var progId = catalog.createProgramme(admin, new ProgrammeRequest("Software Engineering", "SWE", deptId)).id();
        degreeId = catalog.createDegree(admin, new DegreeRequest(progId, DegreeLevel.BACHELOR, 4, 1, 4, true)).id();

        // Setup student profiles: senior in year 3, junior in year 1
        profiles.saveStudent(seniorStudent, new StudentProfileRequest(
                "Senior Student", degreeId, "Senior bio", null,
                List.of("Algorithms", "Java"), List.of(), "S-001", 3, 2027, true, true
        ));
        profiles.saveStudent(juniorStudent, new StudentProfileRequest(
                "Junior Student", degreeId, "Junior bio", null,
                List.of("Python"), List.of(), "J-001", 1, 2029, true, true
        ));
        profiles.saveAlumni(alumniUser, new AlumniProfileRequest(
                "Alumni Mentor", degreeId, "Alumni bio", null,
                List.of("Architecture"), List.of(), 2023, "Tech Corp", "Lead Dev", "Software", "History", null
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
    void seniorStudentCanRegisterAsMentorSuccessfully() throws Exception {
        String body = """
                {
                    "mentoringBio": "Experienced senior student willing to help juniors in SWE courses.",
                    "expertise": [
                        {"topic": "Data Structures", "description": "Trees and graphs"},
                        {"topic": "Spring Boot", "description": "Backend design"}
                    ]
                }
                """;

        mvc.perform(post("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + seniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.role").value("STUDENT"))
                .andExpect(jsonPath("$.yearOfStudy").value(3))
                .andExpect(jsonPath("$.status").value("AVAILABLE"))
                .andExpect(jsonPath("$.expertise.length()").value(2))
                .andExpect(jsonPath("$.expertise[0].topic").value("Data Structures"));
    }

    @Test
    void alumniCanRegisterAsMentorSuccessfully() throws Exception {
        String body = """
                {
                    "mentoringBio": "Software engineer with 3 years of industry experience.",
                    "expertise": [
                        {"topic": "System Design", "description": "Microservices and caching"}
                    ]
                }
                """;

        mvc.perform(post("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + alumniToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.role").value("ALUMNI"))
                .andExpect(jsonPath("$.graduationYear").value(2023))
                .andExpect(jsonPath("$.status").value("AVAILABLE"))
                .andExpect(jsonPath("$.expertise[0].topic").value("System Design"));
    }

    @Test
    void juniorStudentYearOneIsRejected() throws Exception {
        String body = """
                {
                    "mentoringBio": "First year student trying to register.",
                    "expertise": [
                        {"topic": "Python", "description": "Basics"}
                    ]
                }
                """;

        mvc.perform(post("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + juniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    @Test
    void duplicateRegistrationIsBlocked() throws Exception {
        var request = new MentorRegistrationRequest(
                "Mentoring bio with sufficient characters.",
                List.of(new ExpertiseRequest("Algorithms", "Graph search"))
        );
        mentorService.registerMentor(seniorStudent, request);

        String duplicateBody = """
                {
                    "mentoringBio": "Duplicate registration attempt.",
                    "expertise": [{"topic": "Algorithms"}]
                }
                """;

        mvc.perform(post("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + seniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(duplicateBody))
                .andExpect(status().isConflict());
    }

    @Test
    void registrationWithoutExpertiseIsRejected() throws Exception {
        String invalidBody = """
                {
                    "mentoringBio": "Bio with no expertise provided.",
                    "expertise": []
                }
                """;

        mvc.perform(post("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + seniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidBody))
                .andExpect(status().isBadRequest());
    }

    @Test
    void registrationWithNullExpertiseEntryIsRejected() throws Exception {
        String invalidBody = """
                {
                    "mentoringBio": "Valid mentoring bio with sufficient length.",
                    "expertise": [null]
                }
                """;

        mvc.perform(post("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + seniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidBody))
                .andExpect(status().isBadRequest());
    }

    @Test
    void directoryExcludesSuspendedAccountsAndComputesTotalAccurately() throws Exception {
        mentorService.registerMentor(seniorStudent, new MentorRegistrationRequest(
                "Senior mentor in Algorithms.",
                List.of(new ExpertiseRequest("Algorithms", "Graphs"))
        ));

        var alumniProfile = mentorService.registerMentor(alumniUser, new MentorRegistrationRequest(
                "Alumni mentor in Web Development.",
                List.of(new ExpertiseRequest("Web Development", "React and Spring"))
        ));

        // Suspend alumni user directly via database
        jdbc.update("UPDATE users SET account_status = 'SUSPENDED' WHERE user_id = ?", alumniUser.userId());

        // Directory should return only 1 mentor and totalElements = 1
        mvc.perform(get("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + juniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items.length()").value(1))
                .andExpect(jsonPath("$.items[0].fullName").value("Senior Student"));
    }

    @Test
    void mentorProfileHidesAcademicDetailsWhenVisibilityIsConnectionsOnlyAndNotConnected() throws Exception {
        var seniorMentor = mentorService.registerMentor(seniorStudent, new MentorRegistrationRequest(
                "Senior mentor in Algorithms.",
                List.of(new ExpertiseRequest("Algorithms", "Graphs"))
        ));

        // Junior is not connected to senior, visibility is default CONNECTIONS_ONLY
        mvc.perform(get("/api/v1/mentorship/mentors/" + seniorMentor.mentorProfileId())
                        .header("Authorization", "Bearer " + juniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fullName").value("Senior Student"))
                .andExpect(jsonPath("$.departmentName").doesNotExist())
                .andExpect(jsonPath("$.yearOfStudy").doesNotExist());

        // Senior viewing own profile sees academic details
        mvc.perform(get("/api/v1/mentorship/mentors/me")
                        .header("Authorization", "Bearer " + seniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fullName").value("Senior Student"))
                .andExpect(jsonPath("$.departmentName").value("Computing"))
                .andExpect(jsonPath("$.yearOfStudy").value(3));
    }

    @Test
    void mentorCanViewOwnProfileAndUpdateStatus() throws Exception {
        var request = new MentorRegistrationRequest(
                "Mentoring bio with sufficient characters.",
                List.of(new ExpertiseRequest("Data Structures", "Trees"))
        );
        mentorService.registerMentor(seniorStudent, request);

        // View own profile
        mvc.perform(get("/api/v1/mentorship/mentors/me")
                        .header("Authorization", "Bearer " + seniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fullName").value("Senior Student"))
                .andExpect(jsonPath("$.status").value("AVAILABLE"));

        // Update status to UNAVAILABLE
        mvc.perform(patch("/api/v1/mentorship/mentors/me/status")
                        .header("Authorization", "Bearer " + seniorToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"UNAVAILABLE\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UNAVAILABLE"));

        // Own profile now reports UNAVAILABLE
        var own = mentorService.myProfile(seniorStudent);
        assertThat(own.status()).isEqualTo(MentorStatus.UNAVAILABLE);
    }

    @Test
    void directoryOnlyListsAvailableMentorsAndSupportsTopicFilter() throws Exception {
        // Register senior student (Algorithms)
        mentorService.registerMentor(seniorStudent, new MentorRegistrationRequest(
                "Senior mentor in Algorithms.",
                List.of(new ExpertiseRequest("Algorithms", "Graphs"))
        ));

        // Register alumni (Web Development)
        var alumniProfile = mentorService.registerMentor(alumniUser, new MentorRegistrationRequest(
                "Alumni mentor in Web Development.",
                List.of(new ExpertiseRequest("Web Development", "React and Spring"))
        ));

        // Both are available -> directory has 2 mentors
        mvc.perform(get("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + juniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2));

        // Filter by topic "algorithms" -> returns 1
        mvc.perform(get("/api/v1/mentorship/mentors?topic=algorithms")
                        .header("Authorization", "Bearer " + juniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].fullName").value("Senior Student"));

        // Alumni sets status to UNAVAILABLE
        mentorService.updateStatus(alumniUser, new MentorStatusUpdateRequest(MentorStatus.UNAVAILABLE));

        // Directory now only lists the 1 available mentor
        mvc.perform(get("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + juniorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].fullName").value("Senior Student"));

        // Public lookup of UNAVAILABLE mentor profile returns 404 for junior student
        mvc.perform(get("/api/v1/mentorship/mentors/" + alumniProfile.mentorProfileId())
                        .header("Authorization", "Bearer " + juniorToken))
                .andExpect(status().isNotFound());
    }
}
