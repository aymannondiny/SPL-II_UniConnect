package com.uniconnect.project;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.connection.dto.ConnectionRequest;
import com.uniconnect.connection.service.ConnectionService;
import com.uniconnect.discovery.dto.*;
import com.uniconnect.profile.domain.*;
import com.uniconnect.profile.dto.*;
import com.uniconnect.profile.service.*;
import com.uniconnect.project.dto.*;
import com.uniconnect.project.service.*;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.*;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {
        "spring.datasource.url=${candidate.integration.url:jdbc:h2:mem:project_candidates;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE;LOCK_TIMEOUT=10000}",
        "spring.datasource.driver-class-name=${candidate.integration.driver:org.h2.Driver}",
        "spring.datasource.username=${candidate.integration.username:sa}",
        "spring.datasource.password=${candidate.integration.password:}",
        "spring.mail.host=127.0.0.1",
        "spring.mail.port=1",
        "spring.mail.test-connection=false"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(ProjectCandidateSearchIntegrationTests.ClockConfiguration.class)
class ProjectCandidateSearchIntegrationTests {
    private static final Instant NOW = Instant.parse("2026-10-20T17:59:59Z");
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 20);
    @Autowired ProjectCandidateService candidates;
    @Autowired ProjectTeammateService projects;
    @Autowired PersonalProfileService profiles;
    @Autowired ProfilePrivacyService privacy;
    @Autowired AcademicCatalogService catalog;
    @Autowired ConnectionService connections;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired MutableClock clock;

    private SessionPrincipal admin, creator, javaOnly, javaSql, sqlOnly, privateJava, anotherJava, alumni;
    private String creatorToken;
    private long degreeId, departmentId;

    @BeforeEach void setup() {
        clean();
        clock.set(NOW);
        admin = principal(account("Admin", "admin", PlatformRole.SYSTEM_ADMIN));
        creatorToken = account("Creator", "creator", PlatformRole.STUDENT);
        creator = principal(creatorToken);
        javaOnly = principal(account("Alpha", "alpha", PlatformRole.STUDENT));
        javaSql = principal(account("Bravo", "bravo", PlatformRole.STUDENT));
        sqlOnly = principal(account("Charlie", "charlie", PlatformRole.STUDENT));
        privateJava = principal(account("Private", "private", PlatformRole.STUDENT));
        anotherJava = principal(account("Delta", "delta", PlatformRole.STUDENT));
        alumni = principal(account("Alumni", "alumni", PlatformRole.ALUMNI));

        departmentId = catalog.createDepartment(admin, new DepartmentRequest("Computing", "CSE")).id();
        long programmeId = catalog.createProgramme(admin,
                new ProgrammeRequest("Software Engineering", "SWE", departmentId)).id();
        degreeId = catalog.createDegree(admin,
                new DegreeRequest(programmeId, DegreeLevel.BACHELOR, 4, 1, 4, true)).id();

        saveStudent(creator, "C-1", List.of("java"), 2, true, true);
        saveStudent(javaOnly, "A-1", List.of("java"), 2, false, true);
        saveStudent(javaSql, "B-1", List.of("java", "sql"), 3, true, true);
        saveStudent(sqlOnly, "S-1", List.of("sql"), 3, false, true);
        saveStudent(privateJava, "P-1", List.of("java"), 3, true, false);
        saveStudent(anotherJava, "D-1", List.of("java"), 3, true, true);
        profiles.saveAlumni(alumni, new AlumniProfileRequest("Alumni", degreeId, null, null,
                List.of("java"), List.of(), 2025, null, null, null, null, null));
        privacy.update(alumni, new PrivacyRequest(ProfileVisibility.ALL_MEMBERS));
    }

    @AfterEach void clean() {
        for (String table : List.of("teammate_project_audits", "teammate_project_applications",
                "teammate_project_memberships", "teammate_project_skills", "teammate_projects", "notifications",
                "connections", "profile_skills", "profile_interests", "personal_profiles", "skills", "interests",
                "programme_degrees", "programmes", "departments", "authenticated_sessions",
                "email_verification_tokens", "password_reset_tokens", "users")) {
            try { jdbc.update("delete from " + table); } catch (RuntimeException ignored) {}
        }
    }

    @Test void requiredSkillsAreAllOfAndOptionalSkillsNeverChangeEligibilityCountOrOrder() {
        var withoutOptional = candidates.standalone(creator, search(List.of(" JAVA "), List.of(), null, null, null, 0, 20));
        var withOptional = candidates.standalone(creator, search(List.of("java", "java"), List.of(" SQL ", "sql"), null, null, null, 0, 20));
        assertThat(ids(withOptional)).isEqualTo(ids(withoutOptional));
        assertThat(withOptional.totalElements()).isEqualTo(withoutOptional.totalElements());
        assertThat(withOptional.items()).extracting(ProjectCandidateResponse::fullName)
                .containsExactly("Alpha", "Bravo", "Delta");
        assertThat(withOptional.items().getFirst().relevantSkills())
                .containsExactly(new CandidateSkillResponse("java", CandidateSkillKind.REQUIRED));
        assertThat(withOptional.items().get(1).relevantSkills()).containsExactly(
                new CandidateSkillResponse("java", CandidateSkillKind.REQUIRED),
                new CandidateSkillResponse("sql", CandidateSkillKind.OPTIONAL));

        var allRequired = candidates.standalone(creator,
                search(List.of("java", "sql"), List.of(), null, null, null, 0, 20));
        assertThat(ids(allRequired)).containsExactly(javaSql.userId());
        int vocabulary = jdbc.queryForObject("select count(*) from skills", Integer.class);
        var unknown = candidates.standalone(creator,
                search(List.of("unknown skill"), List.of(), null, null, null, 0, 20));
        assertThat(unknown.items()).isEmpty();
        assertThat(unknown.totalElements()).isZero();
        assertThat(jdbc.queryForObject("select count(*) from skills", Integer.class)).isEqualTo(vocabulary);
    }

    @Test void filtersCombineAndOmittedAvailabilityIncludesBothValues() {
        var omitted = candidates.standalone(creator,
                search(List.of("java"), List.of(), departmentId, null, null, 0, 20));
        assertThat(ids(omitted)).contains(javaOnly.userId(), javaSql.userId(), anotherJava.userId());
        var filtered = candidates.standalone(creator,
                search(List.of("java"), List.of(), departmentId, 3, true, 0, 20));
        assertThat(ids(filtered)).containsExactly(javaSql.userId(), anotherJava.userId());
    }

    @Test void privacyAppliesBeforeCountsAndAcceptedConnectionUnlocksThenRemovalHidesImmediately() {
        var request = search(List.of("java"), List.of(), null, 3, true, 0, 20);
        var hidden = candidates.standalone(creator, request);
        assertThat(ids(hidden)).doesNotContain(privateJava.userId());
        long hiddenCount = hidden.totalElements();
        var connection = connections.send(creator, new ConnectionRequest(privateJava.userId(), null));
        connections.accept(privateJava, connection.id());
        var visible = candidates.standalone(creator, request);
        assertThat(ids(visible)).contains(privateJava.userId());
        assertThat(visible.totalElements()).isEqualTo(hiddenCount + 1);
        connections.remove(creator, connection.id());
        var hiddenAgain = candidates.standalone(creator, request);
        assertThat(ids(hiddenAgain)).doesNotContain(privateJava.userId());
        assertThat(hiddenAgain.totalElements()).isEqualTo(hiddenCount);
    }

    @Test void ownedSearchUsesProjectSkillsAndExcludesMembersAndEveryLifetimeApplicant() {
        var project = projects.create(creator, projectRequest(4, TODAY.plusDays(1)));
        var memberApplication = projects.apply(javaOnly, project.id(), null);
        projects.accept(creator, memberApplication.id());
        projects.apply(javaSql, project.id(), null);

        var result = candidates.forProject(creator, project.id(), null, 3, true, "NAME_ASC", 0, 20);
        assertThat(ids(result)).containsExactly(anotherJava.userId());
        assertThatThrownBy(() -> candidates.forProject(javaSql, project.id(), null, null, null,
                "NAME_ASC", 0, 20)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> candidates.forProject(creator, 999999, null, null, null,
                "NAME_ASC", 0, 20)).isInstanceOf(ResourceNotFoundException.class);

        projects.close(creator, project.id());
        assertThatThrownBy(() -> candidates.forProject(creator, project.id(), null, null, null,
                "NAME_ASC", 0, 20)).isInstanceOf(ConflictException.class)
                .extracting("code").isEqualTo("INVALID_PROJECT_STATE");

        var full = projects.create(creator, projectRequest(2, TODAY.plusDays(1)));
        var lastSlot = projects.apply(javaOnly, full.id(), null);
        projects.accept(creator, lastSlot.id());
        assertThatThrownBy(() -> candidates.forProject(creator, full.id(), null, null, null,
                "NAME_ASC", 0, 20)).isInstanceOf(ConflictException.class);

        var deleted = projects.create(creator, projectRequest(3, TODAY.plusDays(1)));
        projects.delete(creator, deleted.id());
        assertThatThrownBy(() -> candidates.forProject(creator, deleted.id(), null, null, null,
                "NAME_ASC", 0, 20)).isInstanceOf(ResourceNotFoundException.class);

        var expired = projects.create(creator, projectRequest(3, TODAY));
        clock.set(Instant.parse("2026-10-20T18:00:00Z"));
        assertThatThrownBy(() -> candidates.forProject(creator, expired.id(), null, null, null,
                "NAME_ASC", 0, 20)).isInstanceOf(ConflictException.class);
    }

    @Test void matchingAndAvailabilityNeverBecomeApplicationPermissions() {
        var project = projects.create(creator, projectRequest(3, TODAY.plusDays(1)));
        assertThat(ids(candidates.forProject(creator, project.id(), null, null, true,
                "NAME_ASC", 0, 20))).doesNotContain(sqlOnly.userId());
        assertThat(projects.detail(sqlOnly, project.id()).canApply()).isTrue();
        assertThat(projects.apply(sqlOnly, project.id(), null).status().name()).isEqualTo("PENDING");
    }

    @Test void paginationUsesNameThenUserIdAndEligibilityIsStudentOnly() {
        var sameOne = principal(account("Echo", "echo1", PlatformRole.STUDENT));
        var sameTwo = principal(account("Echo", "echo2", PlatformRole.STUDENT));
        saveStudent(sameOne, "E-1", List.of("java"), 2, true, true);
        saveStudent(sameTwo, "E-2", List.of("java"), 2, true, true);
        var all = candidates.standalone(creator,
                search(List.of("java"), List.of("sql"), null, null, null, 0, 20));
        List<Long> echoes = all.items().stream().filter(c -> c.fullName().equals("Echo"))
                .map(ProjectCandidateResponse::userId).toList();
        assertThat(echoes).containsExactly(Math.min(sameOne.userId(), sameTwo.userId()),
                Math.max(sameOne.userId(), sameTwo.userId()));
        assertThat(candidates.standalone(creator,
                search(List.of("java"), List.of(), null, null, null, 1, 1)).items()).hasSize(1);
        assertThatThrownBy(() -> candidates.standalone(alumni,
                search(List.of("java"), List.of(), null, null, null, 0, 20)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test void inactiveAndAnonymizedStudentsAreNotCandidatesOrSearchers() {
        jdbc.update("update users set account_status='SUSPENDED' where user_id=?", javaOnly.userId());
        jdbc.update("update users set anonymized_at=? where user_id=?", LocalDateTime.ofInstant(NOW, ZoneOffset.UTC),
                anotherJava.userId());
        var result = candidates.standalone(creator,
                search(List.of("java"), List.of(), null, null, null, 0, 20));
        assertThat(ids(result)).doesNotContain(javaOnly.userId(), anotherJava.userId());

        jdbc.update("update users set account_status='SUSPENDED' where user_id=?", creator.userId());
        assertThatThrownBy(() -> candidates.standalone(creator,
                search(List.of("java"), List.of(), null, null, null, 0, 20)))
                .isInstanceOf(com.uniconnect.authentication.service.InvalidSessionException.class);
    }

    @Test void httpContractAndOpenApiExposeMinimalUnscoredCandidates() throws Exception {
        mvc.perform(get("/api/v1/projects/candidates").header("Authorization", "Bearer " + creatorToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_CANDIDATE_FILTER"));
        mvc.perform(get("/api/v1/projects/candidates")
                        .param("requiredSkills", "java").param("optionalSkills", "sql")
                        .header("Authorization", "Bearer " + creatorToken))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.items[0].userId").exists())
                .andExpect(jsonPath("$.items[0].relevantSkills[0].kind").value("REQUIRED"))
                .andExpect(jsonPath("$.items[0].email").doesNotExist())
                .andExpect(jsonPath("$.items[0].studentNumber").doesNotExist())
                .andExpect(jsonPath("$.items[0].score").doesNotExist())
                .andExpect(jsonPath("$.items[0].explanation").doesNotExist());
        mvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/projects/candidates'].get.responses['200']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/projects/{projectId}/candidates'].get.responses['200']").exists());
    }

    @Test void recommendationsUseApprovedFormulaAndExposeOnlyVisibleMatchingEvidence() throws Exception {
        saveStudent(creator, "C-1", List.of("java"), List.of("AI", "Distributed   Systems"), 2, true, true);
        saveStudent(javaSql, "B-1", List.of("java", "sql"), List.of(" ai "), 3, true, true);
        saveStudent(anotherJava, "D-1", List.of("java", "docker"), List.of(), 3, true, true);
        var accepted = connections.send(creator, new ConnectionRequest(javaSql.userId(), null));
        connections.accept(javaSql, accepted.id());
        connections.send(creator, new ConnectionRequest(anotherJava.userId(), null));

        var project = projects.create(creator, new ProjectRequest("Scored project", "Approved formula", 5,
                null, null, TODAY.plusDays(1), List.of(
                        new ProjectSkillRequest(" JAVA ", true),
                        new ProjectSkillRequest("SQL", true),
                        new ProjectSkillRequest("Docker", false),
                        new ProjectSkillRequest("Git", false))));
        int projectCount = count("teammate_projects");
        int applicationCount = count("teammate_project_applications");
        int auditCount = count("teammate_project_audits");
        int notificationCount = count("notifications");
        int skillCount = count("skills");

        var recommendations = projects.recommendations(creator, project.id());
        var exact = recommendations.stream().filter(item -> item.userId() == javaSql.userId()).findFirst().orElseThrow();
        var partial = recommendations.stream().filter(item -> item.userId() == anotherJava.userId()).findFirst().orElseThrow();
        assertThat(exact.score()).isEqualByComparingTo("72.50");
        assertThat(exact.skillPoints()).isEqualByComparingTo("52.50");
        assertThat(exact.interestPoints()).isEqualByComparingTo("10.00");
        assertThat(exact.connectionPoints()).isEqualByComparingTo("10.00");
        assertThat(exact.matchedRequiredSkills()).containsExactly("java", "sql");
        assertThat(exact.matchedOptionalSkills()).isEmpty();
        assertThat(exact.matchedInterests()).containsExactly("ai");
        assertThat(exact.directlyConnected()).isTrue();
        assertThat(partial.score()).isEqualByComparingTo("35.00");
        assertThat(partial.matchedRequiredSkills()).containsExactly("java");
        assertThat(partial.matchedOptionalSkills()).containsExactly("docker");
        assertThat(partial.directlyConnected()).isFalse();
        assertThat(recommendations).extracting(ProjectRecommendationResponse::userId)
                .containsSubsequence(javaSql.userId(), anotherJava.userId());

        assertThat(count("teammate_projects")).isEqualTo(projectCount);
        assertThat(count("teammate_project_applications")).isEqualTo(applicationCount);
        assertThat(count("teammate_project_audits")).isEqualTo(auditCount);
        assertThat(count("notifications")).isEqualTo(notificationCount);
        assertThat(count("skills")).isEqualTo(skillCount);

        mvc.perform(get("/api/v1/projects/" + project.id() + "/recommendations")
                        .header("Authorization", "Bearer " + creatorToken))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$[0].score").value(72.50))
                .andExpect(jsonPath("$[0].skillPoints").value(52.50))
                .andExpect(jsonPath("$[0].interestPoints").value(10.00))
                .andExpect(jsonPath("$[0].connectionPoints").value(10.00))
                .andExpect(jsonPath("$[0].matchedInterests[0]").value("ai"))
                .andExpect(jsonPath("$[0].directlyConnected").value(true))
                .andExpect(jsonPath("$[0].email").doesNotExist())
                .andExpect(jsonPath("$[0].studentNumber").doesNotExist())
                .andExpect(jsonPath("$[0].explanation").doesNotExist());
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.components.schemas.ProjectRecommendationResponse.properties.score").exists())
                .andExpect(jsonPath("$.components.schemas.ProjectRecommendationResponse.properties.matchedInterests").exists());
    }

    @Test void recommendationPrivacyEligibilityExclusionsAndApplicationPermissionStayIndependent() {
        var project = projects.create(creator, projectRequest(5, TODAY.plusDays(1)));
        assertThat(projects.recommendations(creator, project.id())).extracting(ProjectRecommendationResponse::userId)
                .contains(javaSql.userId(), anotherJava.userId())
                .doesNotContain(javaOnly.userId(), privateJava.userId(), sqlOnly.userId(), alumni.userId());

        saveStudent(javaOnly, "A-1", List.of("java"), 2, true, true);
        assertThat(projects.recommendations(creator, project.id())).extracting(ProjectRecommendationResponse::userId)
                .contains(javaOnly.userId());
        jdbc.update("update users set account_status='SUSPENDED' where user_id=?", javaOnly.userId());
        assertThat(projects.recommendations(creator, project.id())).extracting(ProjectRecommendationResponse::userId)
                .doesNotContain(javaOnly.userId());

        var anonymized = principal(account("Anonymized", "anonymized-recommendation", PlatformRole.STUDENT));
        saveStudent(anonymized, "AN-1", List.of("java"), 2, true, true);
        jdbc.update("update users set anonymized_at=? where user_id=?",
                LocalDateTime.ofInstant(NOW, ZoneOffset.UTC), anonymized.userId());
        assertThat(projects.recommendations(creator, project.id())).extracting(ProjectRecommendationResponse::userId)
                .doesNotContain(anonymized.userId());

        var pending = connections.send(creator, new ConnectionRequest(privateJava.userId(), null));
        assertThat(projects.recommendations(creator, project.id())).extracting(ProjectRecommendationResponse::userId)
                .doesNotContain(privateJava.userId());
        connections.accept(privateJava, pending.id());
        assertThat(projects.recommendations(creator, project.id())).extracting(ProjectRecommendationResponse::userId)
                .contains(privateJava.userId());
        connections.remove(creator, pending.id());
        assertThat(projects.recommendations(creator, project.id())).extracting(ProjectRecommendationResponse::userId)
                .doesNotContain(privateJava.userId());

        projects.apply(javaSql, project.id(), null);
        var memberApplication = projects.apply(anotherJava, project.id(), null);
        projects.accept(creator, memberApplication.id());
        assertThat(projects.recommendations(creator, project.id())).extracting(ProjectRecommendationResponse::userId)
                .doesNotContain(javaSql.userId(), anotherJava.userId());

        assertThat(projects.detail(sqlOnly, project.id()).canApply()).isTrue();
        assertThat(projects.apply(sqlOnly, project.id(), null).status().name()).isEqualTo("PENDING");
    }

    @Test void recommendationsEnforceCreatorAndReturnEmptyForInvalidRecruitmentStateOrLegacyNoRequiredSkills() {
        var project = projects.create(creator, projectRequest(4, TODAY.plusDays(1)));
        assertThatThrownBy(() -> projects.recommendations(javaSql, project.id()))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> projects.recommendations(creator, 999999))
                .isInstanceOf(ResourceNotFoundException.class);

        projects.close(creator, project.id());
        assertThat(projects.recommendations(creator, project.id())).isEmpty();

        var full = projects.create(creator, projectRequest(2, TODAY.plusDays(1)));
        var application = projects.apply(javaSql, full.id(), null);
        projects.accept(creator, application.id());
        assertThat(projects.recommendations(creator, full.id())).isEmpty();

        var legacy = projects.create(creator, projectRequest(4, TODAY.plusDays(1)));
        jdbc.update("update teammate_project_skills set required=false where project_id=?", legacy.id());
        assertThat(projects.recommendations(creator, legacy.id())).isEmpty();

        var expired = projects.create(creator, projectRequest(4, TODAY));
        clock.set(Instant.parse("2026-10-20T18:00:00Z"));
        assertThat(projects.recommendations(creator, expired.id())).isEmpty();
    }

    @Test void recommendationRankingUsesRawTotalsThenStableNameAndIdBeforeTopTwentyLimit() {
        var project = projects.create(creator, new ProjectRequest("Kotlin", "Stable ranking", 30,
                null, null, TODAY.plusDays(1), List.of(new ProjectSkillRequest("kotlin", true))));
        List<Long> allIds = new ArrayList<>();
        for (int index = 0; index < 21; index++) {
            var candidate = principal(account("Same Name", "rank" + index, PlatformRole.STUDENT));
            saveStudent(candidate, "R-" + index, List.of(" kotlin ", "KOTLIN"), List.of(), 2, true, true);
            allIds.add(candidate.userId());
        }
        allIds.sort(Long::compareTo);

        var result = projects.recommendations(creator, project.id());
        assertThat(result).hasSize(20);
        assertThat(result).extracting(ProjectRecommendationResponse::userId)
                .containsExactlyElementsOf(allIds.subList(0, 20));
        assertThat(result).allSatisfy(item -> {
            assertThat(item.score()).isEqualByComparingTo("70.00");
            assertThat(item.matchedRequiredSkills()).containsExactly("kotlin");
        });
    }

    private CandidateSearch search(List<String> required, List<String> optional, Long department,
            Integer year, Boolean available, int page, int size) {
        return new CandidateSearch(required, optional, department, year, available, "NAME_ASC", page, size);
    }

    private List<Long> ids(com.uniconnect.shared.dto.PageResponse<ProjectCandidateResponse> page) {
        return page.items().stream().map(ProjectCandidateResponse::userId).toList();
    }

    private ProjectRequest projectRequest(int capacity, LocalDate deadline) {
        return new ProjectRequest("Candidate search", "Find teammates", capacity, null, null, deadline,
                List.of(new ProjectSkillRequest("java", true), new ProjectSkillRequest("sql", false)));
    }

    private void saveStudent(SessionPrincipal actor, String number, List<String> skills, int year,
            boolean available, boolean allMembers) {
        saveStudent(actor, number, skills, List.of(), year, available, allMembers);
    }

    private void saveStudent(SessionPrincipal actor, String number, List<String> skills, List<String> interests,
            int year, boolean available, boolean allMembers) {
        profiles.saveStudent(actor, new StudentProfileRequest(users.findById(actor.userId()).orElseThrow().getFullName(),
                degreeId, null, null, skills, interests, number, year, 2029, available, false));
        if (allMembers) privacy.update(actor, new PrivacyRequest(ProfileVisibility.ALL_MEMBERS));
    }

    private int count(String table) {
        return jdbc.queryForObject("select count(*) from " + table, Integer.class);
    }

    private String account(String name, String key, PlatformRole role) {
        String email = key + "@iut-dhaka.edu";
        User user = User.register(name, email, passwords.encode("password123"), role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
        users.saveAndFlush(user);
        return sessions.login(new LoginRequest(email, "password123")).accessToken();
    }

    private SessionPrincipal principal(String token) { return sessions.authenticate(token); }

    @TestConfiguration static class ClockConfiguration {
        @Bean @Primary MutableClock candidateClock() { return new MutableClock(NOW, ZoneOffset.UTC); }
    }

    static final class MutableClock extends Clock {
        private final AtomicReference<Instant> instant;
        private final ZoneId zone;
        MutableClock(Instant instant, ZoneId zone) { this(new AtomicReference<>(instant), zone); }
        private MutableClock(AtomicReference<Instant> instant, ZoneId zone) { this.instant = instant; this.zone = zone; }
        void set(Instant value) { instant.set(value); }
        @Override public ZoneId getZone() { return zone; }
        @Override public Clock withZone(ZoneId zone) { return new MutableClock(instant, zone); }
        @Override public Instant instant() { return instant.get(); }
    }
}
