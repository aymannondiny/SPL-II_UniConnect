package com.uniconnect.profile;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.*;
import com.uniconnect.profile.domain.DegreeLevel;
import com.uniconnect.profile.dto.*;
import com.uniconnect.profile.service.*;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProfileIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired SessionService sessions;
    @Autowired PersonalProfileService profiles;
    @Autowired AcademicCatalogService catalog;
    @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager transactions;
    @MockitoBean Clock clock;
    private SessionPrincipal admin, student, alumni;
    private String adminAccess, studentAccess, alumniAccess;
    private Long departmentId, programmeId, degreeId;
    private static final Instant NOW = Instant.parse("2026-10-07T00:00:00Z");

    @BeforeEach
    void setup() {
        clean();
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        adminAccess = account("admin", PlatformRole.SYSTEM_ADMIN);
        studentAccess = account("student", PlatformRole.STUDENT);
        alumniAccess = account("alumni", PlatformRole.ALUMNI);
        admin = sessions.authenticate(adminAccess);
        student = sessions.authenticate(studentAccess);
        alumni = sessions.authenticate(alumniAccess);
        departmentId = catalog.createDepartment(admin, new DepartmentRequest("Test department", "TEST")).id();
        programmeId = catalog.createProgramme(admin, new ProgrammeRequest("Test programme", "TEST-P", departmentId)).id();
        degreeId = catalog.createDegree(admin, degree(true, 4)).id();
    }

    private String account(String name, PlatformRole role) {
        User user = User.register(name, name + "@iut-dhaka.edu", passwords.encode("password123"), role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
        users.saveAndFlush(user);
        return sessions.login(new LoginRequest(name + "@iut-dhaka.edu", "password123")).accessToken();
    }

    @AfterEach
    void clean() {
        for (String table : List.of("profile_skills", "profile_interests", "personal_profiles", "skills", "interests",
                "programme_degrees", "programmes", "departments", "password_reset_tokens", "email_verification_tokens", "authenticated_sessions", "users")) {
            jdbc.update("delete from " + table);
        }
    }

    private DegreeRequest degree(boolean active, int max) {
        return new DegreeRequest(programmeId, DegreeLevel.BACHELOR, 4, 1, max, active);
    }
    private StudentProfileRequest studentRequest(Long degree, String number, int year) {
        return new StudentProfileRequest("Student Name", degree, "About me", null,
                List.of(" Java ", "JAVA", "Problem   Solving"), List.of("Robotics", "robotics"),
                number, year, 2029, true, false);
    }
    private AlumniProfileRequest alumniRequest(String linkedin, int graduationYear) {
        return new AlumniProfileRequest("Alumni Name", degreeId, null, null, List.of(), List.of(),
                graduationYear, "Example company", "Engineer", "Software", "Career history", linkedin);
    }
    private String studentJson(String number) {
        return """
                {"fullName":"Student Name","programmeDegreeId":%d,"bio":"Hello",
                 "skills":["Java","java"],"interests":["Robotics"],"studentNumber":"%s",
                 "yearOfStudy":2,"expectedGraduationYear":2029,"projectAvailability":true,"mentorshipAvailability":false}
                """.formatted(degreeId, number);
    }

    @Test
    void catalogRequiresCurrentActiveAdministratorEvenWithForgedPrincipalRole() throws Exception {
        mvc.perform(post("/api/v1/admin/academics/departments").contentType("application/json")
                .content("{\"name\":\"Example\",\"code\":\"EX\"}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/admin/academics/departments").header("Authorization", "Bearer " + studentAccess)
                .contentType("application/json").content("{\"name\":\"Example\",\"code\":\"EX\"}"))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ACCESS_DENIED"));
        var forged = new SessionPrincipal(student.sessionId(), student.userId(), PlatformRole.SYSTEM_ADMIN);
        assertThatThrownBy(() -> catalog.createDepartment(forged, new DepartmentRequest("Other", "OTHER"))).isInstanceOf(ForbiddenException.class);
        jdbc.update("update users set account_status = 'SUSPENDED' where user_id = ?", admin.userId());
        assertThatThrownBy(() -> catalog.createDepartment(admin, new DepartmentRequest("Other", "OTHER"))).isInstanceOf(InvalidSessionException.class);
    }

    @Test
    void adminCanCreateRenameAndListCatalogAndDuplicatesUseApiError() throws Exception {
        mvc.perform(post("/api/v1/admin/academics/departments").header("Authorization", "Bearer " + adminAccess)
                .contentType("application/json").content("{\"name\":\"Another department\",\"code\":\"other\"}"))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.code").value("OTHER"));
        mvc.perform(post("/api/v1/admin/academics/departments").header("Authorization", "Bearer " + adminAccess)
                .contentType("application/json").content("{\"name\":\"Duplicate\",\"code\":\"test\"}"))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("PROFILE_DATA_CONFLICT"));
        catalog.updateDepartment(admin, departmentId, new DepartmentRequest("Renamed", "TEST"));
        assertThat(catalog.list(student, false).departments()).anyMatch(d -> d.name().equals("Renamed"));
        mvc.perform(get("/api/v1/profile/academic-options").header("Authorization", "Bearer " + studentAccess))
                .andExpect(status().isOk()).andExpect(jsonPath("$.degrees[0].id").value(degreeId));
        mvc.perform(get("/api/v1/admin/academics").header("Authorization", "Bearer " + adminAccess)).andExpect(status().isOk());
    }

    @Test
    void studentCreateAndReplacementKeepOneProfileAndUpdateCanonicalName() throws Exception {
        var first = profiles.saveStudent(student, studentRequest(degreeId, "230042141", 2));
        assertThat(first.skills()).containsExactly("java", "problem solving");
        assertThat(first.interests()).containsExactly("robotics");
        assertThat(first.department().id()).isEqualTo(departmentId);
        assertThat(first.programme().id()).isEqualTo(programmeId);
        assertThat(first.alumni()).isNull();
        var next = profiles.saveStudent(student, new StudentProfileRequest("Updated Name", degreeId, null, null,
                List.of(), List.of(), "230042141", 3, null, false, true));
        assertThat(next.profileId()).isEqualTo(first.profileId());
        assertThat(next.skills()).isEmpty();
        assertThat(next.bio()).isNull();
        assertThat(next.createdAt()).isEqualTo(first.createdAt());
        assertThat(jdbc.queryForObject("select count(*) from personal_profiles", Integer.class)).isEqualTo(1);
        assertThat(sessions.currentUser(student).fullName()).isEqualTo("Updated Name");
        mvc.perform(get("/api/v1/profile/me").header("Authorization", "Bearer " + studentAccess))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.student.studentNumber").value("230042141"))
                .andExpect(jsonPath("$.passwordHash").doesNotExist()).andExpect(jsonPath("$.email").doesNotExist());
    }

    @Test
    void alumniProfileAcceptsProfessionalDetailsAndValidLinkedin() {
        var result = profiles.saveAlumni(alumni, alumniRequest("https://www.linkedin.com/in/example", 2024));
        assertThat(result.alumni().currentCompany()).isEqualTo("Example company");
        assertThat(result.student()).isNull();
        assertThat(profiles.mine(alumni).profileId()).isEqualTo(result.profileId());
        assertThatThrownBy(() -> profiles.saveAlumni(alumni, alumniRequest("https://linkedin.com.attacker.example/in/x", 2024)))
                .isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> profiles.saveAlumni(alumni, alumniRequest("javascript:alert(1)", 2024)))
                .isInstanceOf(BadRequestException.class);
        assertThat(profiles.mine(alumni).alumni().linkedinUrl()).isEqualTo("https://www.linkedin.com/in/example");
    }

    @Test
    void wrongProfileTypeAndAdministratorProfileAreRejected() {
        assertThatThrownBy(() -> profiles.saveStudent(alumni, studentRequest(degreeId, "1", 2))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> profiles.saveAlumni(student, alumniRequest(null, 2024))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> profiles.saveStudent(admin, studentRequest(degreeId, "1", 2))).isInstanceOf(ForbiddenException.class);
        assertThat(jdbc.queryForObject("select count(*) from personal_profiles", Integer.class)).isZero();
    }

    @Test
    void profileReadsAreOwnerOnlyAndMissingProfileIs404() throws Exception {
        profiles.saveStudent(student, studentRequest(degreeId, "123", 2));
        mvc.perform(get("/api/v1/profile/me").header("Authorization", "Bearer " + alumniAccess))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"));
        mvc.perform(get("/api/v1/profile/" + student.userId()).header("Authorization", "Bearer " + alumniAccess))
                .andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/profile/me")).andExpect(status().isUnauthorized());
    }

    @Test
    void duplicateStudentNumberRollsBackSecondProfileAndName() throws Exception {
        profiles.saveStudent(student, studentRequest(degreeId, "S-123", 2));
        String otherAccess = account("other", PlatformRole.STUDENT);
        mvc.perform(put("/api/v1/profile/me/student").header("Authorization", "Bearer " + otherAccess)
                .contentType("application/json").content(studentJson("s-123")))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("PROFILE_DATA_CONFLICT"));
        assertThat(sessions.currentUser(sessions.authenticate(otherAccess)).fullName()).isEqualTo("other");
        assertThat(jdbc.queryForObject("select count(*) from personal_profiles", Integer.class)).isEqualTo(1);
    }

    @Test
    void invalidAcademicSelectionAndStudyYearDoNotCreateProfile() {
        assertThatThrownBy(() -> profiles.saveStudent(student, studentRequest(Long.MAX_VALUE, "123", 2))).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> profiles.saveStudent(student, studentRequest(degreeId, "123", 5))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> profiles.saveAlumni(alumni, alumniRequest(null, 2027))).isInstanceOf(BadRequestException.class);
        assertThat(jdbc.queryForObject("select count(*) from personal_profiles", Integer.class)).isZero();
    }

    @Test
    void inactiveDegreePreservesExistingProfileButCannotBeNewlySelected() {
        profiles.saveStudent(student, studentRequest(degreeId, "123", 2));
        catalog.updateDegree(admin, degreeId, degree(false, 4));
        assertThat(catalog.list(student, false).degrees()).isEmpty();
        assertThat(catalog.list(admin, true).degrees()).hasSize(1);
        assertThat(profiles.mine(student).degree().active()).isFalse();
        profiles.saveStudent(student, studentRequest(degreeId, "123", 3));
        assertThatThrownBy(() -> profiles.saveAlumni(alumni, alumniRequest(null, 2024))).isInstanceOf(BadRequestException.class);
        catalog.updateDegree(admin, degreeId, degree(true, 4));
        profiles.saveAlumni(alumni, alumniRequest(null, 2024));
    }

    @Test
    void degreeRulesAndParentAreProtectedOnceUsed() {
        catalog.updateDegree(admin, degreeId, degree(true, 5));
        profiles.saveStudent(student, studentRequest(degreeId, "123", 5));
        assertThatThrownBy(() -> catalog.updateDegree(admin, degreeId, degree(true, 4))).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> catalog.updateDegree(admin, degreeId,
                new DegreeRequest(programmeId, DegreeLevel.MASTER, 4, 1, 5, true))).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> catalog.createDegree(admin,
                new DegreeRequest(programmeId, DegreeLevel.MASTER, 2, 4, 1, true))).isInstanceOf(BadRequestException.class);
    }

    @Test
    void availabilityPatchChangesOnlyPreferences() throws Exception {
        var first = profiles.saveStudent(student, studentRequest(degreeId, "123", 2));
        mvc.perform(patch("/api/v1/profile/me/availability").header("Authorization", "Bearer " + studentAccess)
                .contentType("application/json").content("{\"projectAvailability\":false,\"mentorshipAvailability\":true}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.student.projectAvailability").value(false))
                .andExpect(jsonPath("$.student.mentorshipAvailability").value(true));
        assertThat(profiles.mine(student).skills()).isEqualTo(first.skills());
        assertThat(profiles.mine(student).student().yearOfStudy()).isEqualTo(2);
        assertThatThrownBy(() -> profiles.availability(alumni, new AvailabilityRequest(true, true))).isInstanceOf(ForbiddenException.class);
    }

    @Test
    void revokedSessionAndAnonymizedAccountCannotEditThroughService() {
        sessions.logout(student);
        assertThatThrownBy(() -> profiles.saveStudent(student, studentRequest(degreeId, "123", 2))).isInstanceOf(InvalidSessionException.class);
        jdbc.update("update users set anonymized_at = ? where user_id = ?", LocalDateTime.ofInstant(NOW, ZoneOffset.UTC), alumni.userId());
        assertThatThrownBy(() -> profiles.saveAlumni(alumni, alumniRequest(null, 2024))).isInstanceOf(InvalidSessionException.class);
    }

    @Test
    void validationAndMalformedJsonUseApiError() throws Exception {
        mvc.perform(put("/api/v1/profile/me/student").header("Authorization", "Bearer " + studentAccess)
                .contentType("application/json").content("{}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        mvc.perform(put("/api/v1/profile/me/student").header("Authorization", "Bearer " + studentAccess)
                .contentType("application/json").content("{"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("MALFORMED_REQUEST"));
        assertThatThrownBy(() -> profiles.saveStudent(student, null)).isInstanceOf(BadRequestException.class);
    }

    @Test
    void outerRollbackRestoresProfileNameAndVocabulary() {
        new TransactionTemplate(transactions).executeWithoutResult(status -> {
            profiles.saveStudent(student, studentRequest(degreeId, "123", 2));
            status.setRollbackOnly();
        });
        assertThat(jdbc.queryForObject("select count(*) from personal_profiles", Integer.class)).isZero();
        assertThat(jdbc.queryForObject("select count(*) from skills", Integer.class)).isZero();
        assertThat(sessions.currentUser(student).fullName()).isEqualTo("student");
    }

    @Test
    void concurrentOwnerUpdatesCannotCreateTwoProfiles() throws Exception {
        var start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            Callable<Long> update = () -> { start.await(); return profiles.saveStudent(student, studentRequest(degreeId, "123", 2)).profileId(); };
            var first = executor.submit(update);
            var second = executor.submit(update);
            start.countDown();
            assertThat(first.get(15, TimeUnit.SECONDS)).isEqualTo(second.get(15, TimeUnit.SECONDS));
        }
        assertThat(jdbc.queryForObject("select count(*) from personal_profiles", Integer.class)).isEqualTo(1);
    }

    @Test
    void openApiDocumentsProtectedProfileAndCatalogOperations() throws Exception {
        mvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/profile/me'].get.security[0].sessionBearer").exists())
                .andExpect(jsonPath("$.paths['/api/v1/profile/me/student'].put.responses['409']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/admin/academics/degrees'].post.responses['201']").exists());
    }
}
