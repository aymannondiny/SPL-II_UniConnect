package com.uniconnect.career;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.career.domain.ApplicationChannel;
import com.uniconnect.career.domain.CareerPostAvailability;
import com.uniconnect.career.domain.CareerSort;
import com.uniconnect.career.domain.EmploymentType;
import com.uniconnect.career.domain.WorkMode;
import com.uniconnect.career.dto.CareerPostRequest;
import com.uniconnect.career.dto.CareerSkillRequest;
import com.uniconnect.career.dto.SaveJobRequest;
import com.uniconnect.career.dto.UpdateSavedNoteRequest;
import com.uniconnect.career.service.CareerAuthorPrivacyService;
import com.uniconnect.career.service.CareerBoardService;
import com.uniconnect.shared.exception.ConflictException;
import com.uniconnect.shared.exception.ForbiddenException;
import com.uniconnect.shared.exception.ResourceNotFoundException;
import com.uniconnect.shared.security.PlatformRole;
import com.uniconnect.shared.security.SessionPrincipal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.support.TransactionTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "spring.datasource.url=${career.integration.url:jdbc:h2:mem:career_board;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE}",
        "spring.datasource.driver-class-name=${career.integration.driver:org.h2.Driver}",
        "spring.datasource.username=${career.integration.username:sa}",
        "spring.datasource.password=${career.integration.password:}"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(CareerBoardIntegrationTests.ClockConfiguration.class)
class CareerBoardIntegrationTests {
    private static final Instant BEFORE_DHAKA_MIDNIGHT = Instant.parse("2026-10-20T17:59:59Z");
    private static final LocalDate DEADLINE = LocalDate.of(2026, 10, 20);

    @Autowired CareerBoardService career;
    @Autowired CareerAuthorPrivacyService privacy;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired MutableClock clock;
    @Autowired org.springframework.transaction.PlatformTransactionManager transactionManager;

    private SessionPrincipal alumni;
    private SessionPrincipal otherAlumni;
    private SessionPrincipal student;
    private SessionPrincipal otherStudent;
    private String alumniToken;
    private String studentToken;

    @BeforeEach
    void setup() {
        clean();
        clock.set(BEFORE_DHAKA_MIDNIGHT);
        alumniToken = account("Career Alumni", PlatformRole.ALUMNI);
        alumni = sessions.authenticate(alumniToken);
        otherAlumni = sessions.authenticate(account("Other Alumni", PlatformRole.ALUMNI));
        studentToken = account("Career Student", PlatformRole.STUDENT);
        student = sessions.authenticate(studentToken);
        otherStudent = sessions.authenticate(account("Other Student", PlatformRole.STUDENT));
    }

    @AfterEach
    void clean() {
        for (String table : List.of("career_saved_jobs", "career_job_skills", "career_job_posts",
                "notifications", "profile_skills", "profile_interests", "personal_profiles", "skills", "interests",
                "programme_degrees", "programmes", "departments", "authenticated_sessions",
                "email_verification_tokens", "password_reset_tokens", "users")) {
            try { jdbc.update("delete from " + table); } catch (RuntimeException ignored) {}
        }
    }

    @Test
    void alumniPublishesAndStudentBrowsesFiltersViewsAndUsesExternalChannel() {
        var post = career.create(alumni, request(DEADLINE, "Dhaka", true));
        assertThat(post.status()).isEqualTo(CareerPostAvailability.PUBLISHED);

        var page = career.browse(student, EmploymentType.FULL_TIME, "DHA", WorkMode.HYBRID,
                "JAVA", CareerSort.DEADLINE_ASC, 0, 20);
        assertThat(page.totalElements()).isOne();
        assertThat(page.items().getFirst().id()).isEqualTo(post.id());
        assertThat(page.items().getFirst().skills()).extracting("name").containsExactly("java");
        assertThat(career.detail(student, post.id()).canApply()).isTrue();
        assertThat(career.application(student, post.id(), ApplicationChannel.URL).toString())
                .isEqualTo("https://jobs.example.test/java");
        assertThat(career.application(student, post.id(), ApplicationChannel.EMAIL).toString())
                .isEqualTo("mailto:careers@example.test");
        assertThatThrownBy(() -> career.create(student, request(DEADLINE, "Dhaka", true)))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> career.browse(alumni, null, null, null, null, null, 0, 20))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void dhakaDeadlineExpiresAtStartOfFollowingLocalDayAndSavedAccessRemains() {
        var post = career.create(alumni, request(DEADLINE, "Dhaka", true));
        var saved = career.save(student, post.id(), new SaveJobRequest("Apply after review"));
        assertThat(saved.post().canApply()).isTrue();

        clock.set(Instant.parse("2026-10-20T18:00:00Z"));
        assertThat(career.browse(student, null, null, null, null, null, 0, 20).items()).isEmpty();
        var retained = career.saved(student, 0, 20).items().getFirst();
        assertThat(retained.post().status()).isEqualTo(CareerPostAvailability.EXPIRED);
        assertThat(retained.post().canApply()).isFalse();
        assertThat(retained.post().title()).isEqualTo("Java Engineer");
        assertThatThrownBy(() -> career.application(student, post.id(), ApplicationChannel.URL))
                .isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> career.update(alumni, post.id(), request(DEADLINE.plusDays(2), "Dhaka", true)))
                .isInstanceOf(ConflictException.class);

        var closed = career.close(alumni, post.id());
        assertThat(closed.status()).isEqualTo(CareerPostAvailability.CLOSED);
        assertThat(career.close(alumni, post.id()).closedAt()).isEqualTo(closed.closedAt());
        assertThat(career.detail(student, post.id()).status()).isEqualTo(CareerPostAvailability.CLOSED);
    }

    @Test
    void savedNotesOwnershipDuplicateAndUnsaveRulesAreEnforced() {
        var post = career.create(alumni, request(DEADLINE, "Remote", false));
        var saved = career.save(student, post.id(), new SaveJobRequest("First note"));
        assertThatThrownBy(() -> career.save(student, post.id(), null))
                .isInstanceOf(ConflictException.class).extracting("code").isEqualTo("DUPLICATE_SAVED_JOB");
        var updated = career.updateSavedNote(student, saved.id(), new UpdateSavedNoteRequest("Updated note"));
        assertThat(updated.note()).isEqualTo("Updated note");
        assertThatThrownBy(() -> career.updateSavedNote(otherStudent, saved.id(), new UpdateSavedNoteRequest("No")))
                .isInstanceOf(ResourceNotFoundException.class);
        career.unsave(student, post.id());
        assertThat(career.saved(student, 0, 20).items()).isEmpty();
        assertThatThrownBy(() -> career.unsave(student, post.id())).isInstanceOf(ResourceNotFoundException.class);
        assertThat(career.save(student, post.id(), null).post().saved()).isTrue();
    }

    @Test
    void ownershipCloseAndConcurrentDuplicateSaveAreSerialized() throws Exception {
        var post = career.create(alumni, request(DEADLINE, "Dhaka", false));
        assertThatThrownBy(() -> career.update(otherAlumni, post.id(), request(DEADLINE, "Dhaka", false)))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> career.close(otherAlumni, post.id())).isInstanceOf(ResourceNotFoundException.class);

        var gate = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var first = pool.submit(() -> saveOutcome(gate, post.id()));
            var second = pool.submit(() -> saveOutcome(gate, post.id()));
            gate.countDown();
            assertThat(List.of(first.get(10, TimeUnit.SECONDS), second.get(10, TimeUnit.SECONDS)))
                    .containsExactlyInAnyOrder("SAVED", "DUPLICATE_SAVED_JOB");
        }
        assertThat(jdbc.queryForObject("select count(*) from career_saved_jobs", Integer.class)).isOne();
    }

    @Test
    void suspendedAuthorDoesNotHidePostAndAnonymizationRedactsWithoutDroppingBookmark() {
        var post = career.create(alumni, request(DEADLINE, "Dhaka", true));
        career.save(student, post.id(), null);
        jdbc.update("update users set account_status='SUSPENDED' where user_id=?", alumni.userId());
        assertThat(career.browse(student, null, null, null, null, null, 0, 20).totalElements()).isOne();

        new TransactionTemplate(transactionManager).executeWithoutResult(ignored -> privacy.redactAuthor(alumni.userId()));
        assertThat(career.browse(student, null, null, null, null, null, 0, 20).items()).isEmpty();
        var retained = career.saved(student, 0, 20).items().getFirst().post();
        assertThat(retained.status()).isEqualTo(CareerPostAvailability.UNAVAILABLE);
        assertThat(retained.authorUserId()).isNull();
        assertThat(retained.authorDisplayName()).isEqualTo("Former User");
        assertThat(retained.title()).isEqualTo("Java Engineer");
        assertThat(retained.applicationUrl()).isNull();
        assertThat(retained.applicationEmail()).isNull();
        assertThat(retained.applicationChannels()).isEmpty();
        assertThat(retained.canApply()).isFalse();
    }

    @Test
    void removedSavedPostIsATombstoneAndRestAndOpenApiContractsAreExplicit() throws Exception {
        var post = career.create(alumni, request(DEADLINE, "Dhaka", false));
        career.save(student, post.id(), null);
        jdbc.update("update career_job_posts set status='REMOVED',removed_at=current_timestamp where job_post_id=?", post.id());
        var tombstone = career.saved(student, 0, 20).items().getFirst().post();
        assertThat(tombstone.status()).isEqualTo(CareerPostAvailability.REMOVED);
        assertThat(tombstone.authorUserId()).isNull();
        assertThat(tombstone.authorDisplayName()).isNull();
        assertThat(tombstone.title()).isNull();
        assertThat(tombstone.description()).isNull();
        assertThat(tombstone.applicationDeadline()).isNull();
        assertThat(tombstone.postedAt()).isNull();
        assertThat(tombstone.applicationUrl()).isNull();
        assertThatThrownBy(() -> career.detail(student, post.id())).isInstanceOf(ResourceNotFoundException.class);

        mvc.perform(post("/api/v1/career/posts").header("Authorization", "Bearer " + alumniToken)
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        mvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/career/posts'].post.responses['201']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/career/posts'].post.responses['409']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/career/posts/{postId}/apply'].get.responses['302']").exists());
    }

    @Test
    void applyEndpointRedirectsWithoutCreatingApplicationRecords() throws Exception {
        var post = career.create(alumni, request(DEADLINE, "Dhaka", false));
        mvc.perform(get("/api/v1/career/posts/{id}/apply", post.id())
                        .param("channel", "URL").header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isFound())
                .andExpect(header().string("Location", "https://jobs.example.test/java"));
        assertThat(jdbc.queryForList("select table_name from information_schema.tables "
                + "where lower(table_schema)='public' and lower(table_name) in "
                + "('applications','job_applications','career_applications')"))
                .isEmpty();
    }

    private String saveOutcome(CountDownLatch gate, long postId) throws Exception {
        gate.await();
        try {
            career.save(student, postId, null);
            return "SAVED";
        } catch (ConflictException conflict) {
            return conflict.code();
        }
    }

    private CareerPostRequest request(LocalDate deadline, String location, boolean bothChannels) {
        return new CareerPostRequest("Java Engineer", "Example Ltd", "Build reliable services",
                "Java and SQL experience", location, EmploymentType.FULL_TIME, WorkMode.HYBRID,
                "BDT 80k–120k", "https://jobs.example.test/java",
                bothChannels ? "careers@example.test" : null, deadline,
                List.of(new CareerSkillRequest("Java", true)));
    }

    private String account(String name, PlatformRole role) {
        String email = name.toLowerCase(Locale.ROOT).replace(' ', '.') + "@iut-dhaka.edu";
        User user = User.register(name, email, passwords.encode("password123"), role);
        user.verifyEmail(LocalDateTime.ofInstant(BEFORE_DHAKA_MIDNIGHT, ZoneOffset.UTC));
        users.saveAndFlush(user);
        return sessions.login(new LoginRequest(email, "password123")).accessToken();
    }

    @TestConfiguration
    static class ClockConfiguration {
        @Bean @Primary MutableClock careerClock() { return new MutableClock(BEFORE_DHAKA_MIDNIGHT, ZoneOffset.UTC); }
    }

    static final class MutableClock extends Clock {
        private final AtomicReference<Instant> instant;
        private final ZoneId zone;
        MutableClock(Instant instant, ZoneId zone) { this(new AtomicReference<>(instant), zone); }
        private MutableClock(AtomicReference<Instant> instant, ZoneId zone) { this.instant = instant; this.zone = zone; }
        void set(Instant value) { instant.set(value); }
        @Override public ZoneId getZone() { return zone; }
        @Override public Clock withZone(ZoneId newZone) { return new MutableClock(instant, newZone); }
        @Override public Instant instant() { return instant.get(); }
    }
}
