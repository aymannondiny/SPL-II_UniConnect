package com.uniconnect.mentorship;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.mentorship.dto.ExpertiseRequest;
import com.uniconnect.mentorship.dto.MentorRegistrationRequest;
import com.uniconnect.mentorship.service.PeerMentorService;
import com.uniconnect.profile.domain.DegreeLevel;
import com.uniconnect.profile.dto.*;
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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import jakarta.persistence.EntityManagerFactory;
import org.hibernate.SessionFactory;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Locale;

import static org.mockito.Mockito.when;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MentorMultiCriteriaSearchIntegrationTests {

    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired SessionService sessions;
    @Autowired PersonalProfileService profiles;
    @Autowired AcademicCatalogService catalog;
    @Autowired PeerMentorService mentorService;
    @Autowired JdbcTemplate jdbc;
    @Autowired EntityManagerFactory entityManagerFactory;
    @MockitoBean Clock clock;

    private Long cseDegreeId;
    private Long cseDeptId;
    private Long eeeDeptId;
    private String viewerToken;
    private static final Instant NOW = Instant.parse("2026-10-15T12:00:00Z");

    @BeforeEach
    void setUp() {
        clean();
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);

        String adminToken = account("AdminUser", PlatformRole.SYSTEM_ADMIN);
        SessionPrincipal admin = sessions.authenticate(adminToken);

        cseDeptId = catalog.createDepartment(admin, new DepartmentRequest("Computing", "CSE")).id();
        eeeDeptId = catalog.createDepartment(admin, new DepartmentRequest("Electrical", "EEE")).id();

        var cseProg = catalog.createProgramme(admin, new ProgrammeRequest("Software Engineering", "SWE", cseDeptId)).id();
        var eeeProg = catalog.createProgramme(admin, new ProgrammeRequest("Electrical Engineering", "EEE_P", eeeDeptId)).id();

        var cseDegree = catalog.createDegree(admin, new DegreeRequest(cseProg, DegreeLevel.BACHELOR, 4, 1, 4, true)).id();
        cseDegreeId = cseDegree;
        var eeeDegree = catalog.createDegree(admin, new DegreeRequest(eeeProg, DegreeLevel.BACHELOR, 4, 1, 4, true)).id();

        // Student 1: CSE, Year 3, Algorithms
        String s1Token = account("AliceCSE", PlatformRole.STUDENT);
        SessionPrincipal s1Principal = sessions.authenticate(s1Token);
        profiles.saveStudent(s1Principal, new StudentProfileRequest(
                "Alice CSE", cseDegree, "Alice bio", null,
                List.of("Algorithms"), List.of(), "S-001", 3, 2027, true, true
        ));
        mentorService.registerMentor(s1Principal, new MentorRegistrationRequest(
                "Tutoring DSA", List.of(new ExpertiseRequest("Algorithms", "Graph Theory"))
        ));

        // Student 2: EEE, Year 2, Circuits
        String s2Token = account("BobEEE", PlatformRole.STUDENT);
        SessionPrincipal s2Principal = sessions.authenticate(s2Token);
        profiles.saveStudent(s2Principal, new StudentProfileRequest(
                "Bob EEE", eeeDegree, "Bob bio", null,
                List.of("Circuits"), List.of(), "S-002", 2, 2028, true, true
        ));
        mentorService.registerMentor(s2Principal, new MentorRegistrationRequest(
                "Tutoring Circuits", List.of(new ExpertiseRequest("Circuits", "Digital Logic"))
        ));

        // Viewer
        viewerToken = account("ViewerStudent", PlatformRole.STUDENT);
    }

    @AfterEach
    void tearDown() {
        clean();
    }

    private void clean() {
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
    void alumniFilterExcludesStudentsAndCombinesWithTopic() throws Exception {
        String alumniToken = account("AlumniMentor", PlatformRole.ALUMNI);
        var alumni = sessions.authenticate(alumniToken);
        profiles.saveAlumni(alumni, new AlumniProfileRequest("Alumni Mentor", cseDegreeId, "Bio", null,
                List.of("Algorithms"), List.of(), 2024, null, null, null, null, null));
        mentorService.registerMentor(alumni, new MentorRegistrationRequest(
                "Career guidance", List.of(new ExpertiseRequest("Algorithms", "Interviews"))));
        for (String token : List.of(viewerToken, alumniToken)) {
            mvc.perform(get("/api/v1/mentorship/mentors")
                            .header("Authorization", "Bearer " + token)
                            .param("role", "ALUMNI").param("topic", "Algorithms").param("size", "1"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.totalElements").value(1))
                    .andExpect(jsonPath("$.items[0].role").value("ALUMNI"));
            mvc.perform(get("/api/v1/mentorship/mentors")
                            .header("Authorization", "Bearer " + token)
                            .param("role", "ALUMNI").param("yearOfStudy", "3"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.totalElements").value(0));
        }
    }

    @Test
    void directoryQueryCountDoesNotGrowWithThePageSize() throws Exception {
        var statistics = entityManagerFactory.unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        try {
            statistics.clear();
            mvc.perform(get("/api/v1/mentorship/mentors")
                            .header("Authorization", "Bearer " + viewerToken).param("size", "1"))
                    .andExpect(status().isOk()).andExpect(jsonPath("$.items.length()").value(1));
            long oneMentor = statistics.getPrepareStatementCount();
            statistics.clear();
            mvc.perform(get("/api/v1/mentorship/mentors")
                            .header("Authorization", "Bearer " + viewerToken).param("size", "20"))
                    .andExpect(status().isOk()).andExpect(jsonPath("$.items.length()").value(2))
                    .andExpect(jsonPath("$.items[0].departmentName").doesNotExist())
                    .andExpect(jsonPath("$.items[1].yearOfStudy").doesNotExist());
            long fullPage = statistics.getPrepareStatementCount();
            assertThat(fullPage).isLessThanOrEqualTo(oneMentor);
            assertThat(fullPage).isLessThanOrEqualTo(10);
        } finally {
            statistics.setStatisticsEnabled(false);
        }
    }

    @Test
    void searchByDepartmentFiltersCorrectly() throws Exception {
        mvc.perform(get("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + viewerToken)
                        .param("departmentId", cseDeptId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].fullName").value("Alice CSE"));

        mvc.perform(get("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + viewerToken)
                        .param("departmentId", eeeDeptId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].fullName").value("Bob EEE"));
    }

    @Test
    void searchByYearOfStudyFiltersCorrectly() throws Exception {
        mvc.perform(get("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + viewerToken)
                        .param("yearOfStudy", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].fullName").value("Alice CSE"));

        mvc.perform(get("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + viewerToken)
                        .param("yearOfStudy", "4"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(0));
    }

    @Test
    void searchByCombinedTopicAndDepartment() throws Exception {
        mvc.perform(get("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + viewerToken)
                        .param("topic", "Algorithms")
                        .param("departmentId", cseDeptId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.items[0].fullName").value("Alice CSE"));

        mvc.perform(get("/api/v1/mentorship/mentors")
                        .header("Authorization", "Bearer " + viewerToken)
                        .param("topic", "Circuits")
                        .param("departmentId", cseDeptId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(0));
    }
}
