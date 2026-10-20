package com.uniconnect.project;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.project.domain.*;
import com.uniconnect.project.dto.*;
import com.uniconnect.project.service.*;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.*;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.support.TransactionTemplate;

import static org.assertj.core.api.Assertions.*;

@SpringBootTest(properties = {
        "spring.datasource.url=${project.integration.url:jdbc:h2:mem:project_teammate;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE;LOCK_TIMEOUT=10000}",
        "spring.datasource.driver-class-name=${project.integration.driver:org.h2.Driver}",
        "spring.datasource.username=${project.integration.username:sa}",
        "spring.datasource.password=${project.integration.password:}"
})
@ActiveProfiles("test")
@Import(ProjectTeammateIntegrationTests.ClockConfiguration.class)
class ProjectTeammateIntegrationTests {
    private static final Instant NOW = Instant.parse("2026-10-20T17:59:59Z");
    private static final LocalDate TODAY = LocalDate.of(2026, 10, 20);
    @Autowired ProjectTeammateService projects;
    @Autowired ProjectOwnerPrivacyService privacy;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired JdbcTemplate jdbc;
    @Autowired MutableClock clock;
    @Autowired org.springframework.transaction.PlatformTransactionManager transactionManager;
    private SessionPrincipal creator, applicant, secondApplicant, other;

    @BeforeEach void setup() {
        clean(); clock.set(NOW);
        creator = principal(account("Creator", PlatformRole.STUDENT));
        applicant = principal(account("Applicant", PlatformRole.STUDENT));
        secondApplicant = principal(account("Second Applicant", PlatformRole.STUDENT));
        other = principal(account("Other", PlatformRole.STUDENT));
    }

    @AfterEach void clean() {
        for (String table : List.of("teammate_project_audits", "teammate_project_applications",
                "teammate_project_memberships", "teammate_project_skills", "teammate_projects", "notifications",
                "profile_skills", "profile_interests", "personal_profiles", "skills", "interests",
                "programme_degrees", "programmes", "departments", "authenticated_sessions",
                "email_verification_tokens", "password_reset_tokens", "users")) {
            try { jdbc.update("delete from " + table); } catch (RuntimeException ignored) {}
        }
    }

    @Test void lifecycleDerivesCapacityDeadlineAndRetainsReviewAfterCloseAndExpiry() {
        var project = projects.create(creator, request(3, TODAY));
        assertThat(project.membershipCount()).isOne();
        assertThat(project.vacancies()).isEqualTo(2);
        assertThat(project.availability()).isEqualTo(ProjectAvailability.AVAILABLE);
        var application = projects.apply(applicant, project.id(), new ProjectApplicationRequest("I can help"));
        assertThat(projects.detail(applicant, project.id()).currentApplicationStatus())
                .isEqualTo(ProjectApplicationStatus.PENDING);
        projects.close(creator, project.id());
        clock.set(Instant.parse("2026-10-20T18:00:00Z"));
        var accepted = projects.accept(creator, application.id());
        assertThat(accepted.status()).isEqualTo(ProjectApplicationStatus.ACCEPTED);
        assertThat(projects.members(creator, project.id())).hasSize(2);
        assertThat(projects.accept(creator, application.id()).status()).isEqualTo(ProjectApplicationStatus.ACCEPTED);
        assertThat(jdbc.queryForObject("select count(*) from notifications where type='PROJECT_APPLICATION_ACCEPTED'", Integer.class)).isOne();
        assertThat(jdbc.queryForObject("select count(*) from teammate_project_memberships where project_id=?", Integer.class, project.id())).isEqualTo(2);
        assertThatThrownBy(() -> projects.reopen(creator, project.id())).isInstanceOf(ConflictException.class);
        projects.update(creator, project.id(), request(3, TODAY.plusDays(2)));
        assertThat(projects.reopen(creator, project.id()).status()).isEqualTo(ProjectStatus.OPEN);
    }

    @Test void projectRequiresAtLeastOneRequiredSkill() {
        var optionalOnly = new ProjectRequest("Optional only", "Invalid project", 2, null, null,
                TODAY.plusDays(1), List.of(new ProjectSkillRequest("Java", false)));
        assertThatThrownBy(() -> projects.create(creator, optionalOnly)).isInstanceOf(BadRequestException.class)
                .extracting("code").isEqualTo("REQUIRED_PROJECT_SKILL_MISSING");
    }

    @Test void canApplyIsViewerSpecificAndCreatorSelfApplicationCreatesNoRow() {
        var project = projects.create(creator, request(3, TODAY.plusDays(1)));
        assertThat(project.canApply()).isFalse();
        assertThat(projects.detail(creator, project.id()).canApply()).isFalse();
        assertThat(projects.detail(applicant, project.id()).canApply()).isTrue();

        assertThatThrownBy(() -> projects.apply(creator, project.id(), null))
                .isInstanceOf(ConflictException.class);
        assertThat(jdbc.queryForObject("select count(*) from teammate_project_applications", Integer.class)).isZero();

        var application = projects.apply(applicant, project.id(), null);
        assertThat(projects.detail(applicant, project.id()).canApply()).isFalse();
        assertThat(projects.browse(applicant, null, null, null, null, null, 0, 20).items().getFirst().canApply())
                .isFalse();
        projects.accept(creator, application.id());
        assertThat(projects.detail(applicant, project.id()).canApply()).isFalse();
        assertThat(projects.detail(other, project.id()).canApply()).isTrue();
    }

    @Test void fullOpenVisibleButCannotAcceptApplicationsAndDeadlineExtensionRestoresAvailability() {
        var project = projects.create(creator, request(2, TODAY));
        var first = projects.apply(applicant, project.id(), null);
        projects.accept(creator, first.id());
        assertThat(projects.detail(other, project.id()).availability()).isEqualTo(ProjectAvailability.FULL);
        assertThat(projects.detail(other, project.id()).canApply()).isFalse();
        assertThat(projects.browse(other, null, null, null, null, null, 0, 20).items()).hasSize(1);
        assertThat(projects.browse(other, null, ProjectAvailability.FULL, null, null, null, 0, 20).items()).hasSize(1);
        assertThat(projects.browse(other, null, ProjectAvailability.AVAILABLE, null, null, null, 0, 20).items()).isEmpty();
        assertThatThrownBy(() -> projects.apply(secondApplicant, project.id(), null))
                .isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> projects.update(creator, project.id(), request(1, TODAY.plusDays(1))))
                .isInstanceOf(BadRequestException.class);
        clock.set(Instant.parse("2026-10-20T18:00:00Z"));
        assertThat(projects.browse(other, null, null, null, null, null, 0, 20).items()).isEmpty();
        projects.update(creator, project.id(), request(3, TODAY.plusDays(2)));
        assertThat(projects.detail(other, project.id()).availability()).isEqualTo(ProjectAvailability.AVAILABLE);
    }

    @Test void departmentFilterUsesCreatorsCurrentProfileDepartment() {
        jdbc.update("insert into departments(department_id,department_name,department_code) values (1,'Computer Science','CSE'),(2,'Electrical Engineering','EEE')");
        jdbc.update("insert into programmes(programme_id,department_id,programme_name,programme_code) values (1,1,'Software Engineering','SWE'),(2,2,'Electrical Engineering','EE')");
        jdbc.update("insert into programme_degrees(programme_degree_id,programme_id,degree_level,duration_years,minimum_year,maximum_year,active) values (1,1,'BACHELOR',4,1,4,true),(2,2,'BACHELOR',4,1,4,true)");
        jdbc.update("insert into personal_profiles(user_id,profile_type,programme_degree_id,created_at,updated_at,student_number,year_of_study,project_availability,mentorship_availability,details_visibility) values (?,?,?,?,?,?,?,?,?,?)",
                creator.userId(), "STUDENT", 1, LocalDateTime.ofInstant(NOW, ZoneOffset.UTC),
                LocalDateTime.ofInstant(NOW, ZoneOffset.UTC), "S-001", 3, true, false, "CONNECTIONS_ONLY");
        var project = projects.create(creator, request(3, TODAY.plusDays(1)));
        var response = projects.detail(other, project.id());
        assertThat(response.creatorDepartmentId()).isEqualTo(1);
        assertThat(response.creatorDepartmentCode()).isEqualTo("CSE");
        assertThat(projects.browse(other, null, null, 1L, null, null, 0, 20).items()).hasSize(1);
        assertThat(projects.browse(other, null, null, 2L, null, null, 0, 20).items()).isEmpty();
        jdbc.update("update personal_profiles set programme_degree_id=2 where user_id=?", creator.userId());
        assertThat(projects.browse(other, null, null, 1L, null, null, 0, 20).items()).isEmpty();
        assertThat(projects.browse(other, null, null, 2L, null, ProjectSort.DEADLINE_ASC, 0, 20).items()).hasSize(1);
    }

    @Test void lifetimeApplicationOwnershipDeletionAndAnonymizationAreTerminalAndIdempotent() {
        var project = projects.create(creator, request(4, TODAY.plusDays(1)));
        var one = projects.apply(applicant, project.id(), null);
        projects.apply(secondApplicant, project.id(), null);
        assertThatThrownBy(() -> projects.apply(applicant, project.id(), null))
                .isInstanceOf(ConflictException.class).extracting("code").isEqualTo("DUPLICATE_PROJECT_APPLICATION");
        assertThatThrownBy(() -> projects.close(other, project.id())).isInstanceOf(ResourceNotFoundException.class);
        projects.delete(creator, project.id());
        assertThatThrownBy(() -> projects.detail(other, project.id())).isInstanceOf(ResourceNotFoundException.class);
        assertThat(jdbc.queryForObject("select count(*) from teammate_project_applications where status='CANCELLED_PROJECT_DELETED'", Integer.class)).isEqualTo(2);
        assertThat(jdbc.queryForObject("select count(*) from notifications where type='PROJECT_DELETED'", Integer.class)).isEqualTo(2);
        assertThatThrownBy(() -> projects.delete(creator, project.id())).isInstanceOf(ResourceNotFoundException.class);
        assertThat(jdbc.queryForObject("select count(*) from notifications where type='PROJECT_DELETED'", Integer.class)).isEqualTo(2);

        var owned = projects.create(creator, request(3, TODAY.plusDays(1)));
        projects.apply(applicant, owned.id(), null);
        var transaction = new TransactionTemplate(transactionManager);
        transaction.executeWithoutResult(ignored -> privacy.redactOwner(creator.userId()));
        transaction.executeWithoutResult(ignored -> privacy.redactOwner(creator.userId()));
        assertThat(jdbc.queryForObject("select count(*) from notifications where type='PROJECT_DELETED'", Integer.class)).isEqualTo(3);
        assertThat(jdbc.queryForObject("select creator_redacted_at is not null from teammate_projects where project_id=?", Boolean.class, owned.id())).isTrue();
    }

    @Test void concurrentLastSlotAcceptanceCreatesExactlyOneMembershipAndNotification() throws Exception {
        var project = projects.create(creator, request(2, TODAY.plusDays(1)));
        var first = projects.apply(applicant, project.id(), null);
        var second = projects.apply(secondApplicant, project.id(), null);
        var start = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var a = pool.submit(() -> outcome(start, first.id()));
            var b = pool.submit(() -> outcome(start, second.id()));
            start.countDown();
            assertThat(List.of(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS)))
                    .containsExactlyInAnyOrder("ACCEPTED", "INVALID_PROJECT_STATE");
        }
        assertThat(jdbc.queryForObject("select count(*) from teammate_project_memberships where project_id=?", Integer.class, project.id())).isEqualTo(2);
        assertThat(jdbc.queryForObject("select count(*) from notifications where type='PROJECT_APPLICATION_ACCEPTED'", Integer.class)).isOne();
    }

    @Test void applicationWaitingBehindCreatorSuspensionObservesSuspendedState() throws Exception {
        var project = projects.create(creator, request(3, TODAY.plusDays(1)));
        var locked = new CountDownLatch(1); var release = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var suspension = pool.submit(() -> new TransactionTemplate(transactionManager).executeWithoutResult(ignored -> {
                var user = users.findForUpdateById(creator.userId()).orElseThrow();
                user.suspend(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
                locked.countDown(); await(release);
            }));
            assertThat(locked.await(10, TimeUnit.SECONDS)).isTrue();
            var applying = pool.submit(() -> projects.apply(applicant, project.id(), null));
            assertThatThrownBy(() -> applying.get(300, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
            release.countDown(); suspension.get(15, TimeUnit.SECONDS);
            assertThatThrownBy(() -> applying.get(15, TimeUnit.SECONDS)).isInstanceOf(ExecutionException.class)
                    .hasCauseInstanceOf(ConflictException.class);
        }
        assertThat(jdbc.queryForObject("select count(*) from teammate_project_applications", Integer.class)).isZero();
        assertThat(projects.detail(applicant, project.id()).canApply()).isFalse();
    }

    private String outcome(CountDownLatch start, long application) throws Exception {
        start.await();
        try { return projects.accept(creator, application).status().name(); }
        catch (ConflictException conflict) { return conflict.code(); }
    }
    private ProjectRequest request(int capacity, LocalDate deadline) {
        return new ProjectRequest("Distributed Systems Project", "Build a reliable service", capacity,
                "12 weeks", "SWE 4201", deadline, List.of(new ProjectSkillRequest("Java", true)));
    }
    private String account(String name, PlatformRole role) {
        String email = name.toLowerCase(Locale.ROOT).replace(' ', '.') + "@iut-dhaka.edu";
        User user = User.register(name, email, passwords.encode("password123"), role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC)); users.saveAndFlush(user);
        return sessions.login(new LoginRequest(email, "password123")).accessToken();
    }
    private SessionPrincipal principal(String token) { return sessions.authenticate(token); }
    private static void await(CountDownLatch latch) {
        try { if (!latch.await(10, TimeUnit.SECONDS)) throw new AssertionError("timeout"); }
        catch (InterruptedException interrupted) { Thread.currentThread().interrupt(); throw new AssertionError(interrupted); }
    }
    @TestConfiguration static class ClockConfiguration {
        @Bean @Primary MutableClock projectClock() { return new MutableClock(NOW, ZoneOffset.UTC); }
    }
    static final class MutableClock extends Clock {
        private final AtomicReference<Instant> instant; private final ZoneId zone;
        MutableClock(Instant instant, ZoneId zone) { this(new AtomicReference<>(instant), zone); }
        private MutableClock(AtomicReference<Instant> instant, ZoneId zone) { this.instant = instant; this.zone = zone; }
        void set(Instant value) { instant.set(value); }
        @Override public ZoneId getZone() { return zone; }
        @Override public Clock withZone(ZoneId zone) { return new MutableClock(instant, zone); }
        @Override public Instant instant() { return instant.get(); }
    }
}
