package com.uniconnect.administration;

import com.uniconnect.administration.dto.AccountModerationRequest;
import com.uniconnect.administration.service.AccountModerationService;
import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.*;
import com.uniconnect.club.domain.ClubStatus;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.service.*;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.security.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.*;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.support.TransactionTemplate;
import static org.assertj.core.api.Assertions.*;

@SpringBootTest(properties = {
        "spring.datasource.url=${account.moderation.datasource.url:jdbc:h2:mem:account_moderation_concurrency;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE;LOCK_TIMEOUT=10000}",
        "spring.datasource.driver-class-name=${account.moderation.datasource.driver:org.h2.Driver}",
        "spring.datasource.username=${account.moderation.datasource.username:sa}",
        "spring.datasource.password=${account.moderation.datasource.password:}"
})
@ActiveProfiles("test")
@Import(AccountModerationConcurrencyTests.FixedClockConfiguration.class)
class AccountModerationConcurrencyTests {
    @Autowired AccountModerationService moderation;
    @Autowired ClubService clubs;
    @Autowired ClubLifecycleService lifecycle;
    @Autowired ClubContextService contexts;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired JdbcTemplate jdbc;
    @Autowired ClubAccountModerationService clubModeration;
    @Autowired AccountAdministrationService accounts;
    @Autowired TransactionTemplate transactions;

    private static final Instant NOW = Instant.parse("2026-10-19T00:00:00Z");
    private static final AccountModerationRequest REQUEST = new AccountModerationRequest("Concurrent policy review", true);
    private SessionPrincipal system, target, replacement;
    private long targetId;

    @TestConfiguration
    static class FixedClockConfiguration {
        @Bean @Primary Clock fixedClock() { return Clock.fixed(NOW, ZoneOffset.UTC); }
    }

    @BeforeEach void setup() {
        clean();
        system = principal(account("System", PlatformRole.SYSTEM_ADMIN));
        target = principal(account("Target", PlatformRole.STUDENT)); targetId = target.userId();
        replacement = principal(account("Replacement", PlatformRole.STUDENT));
        contexts.select(system, new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION, null));
    }

    @AfterEach void clean() {
        for (String table : List.of("audit_logs", "moderation_actions", "club_publication_audit",
                "club_announcements", "club_events", "authenticated_sessions", "club_audit",
                "club_role_assignments", "clubs", "notifications", "users")) {
            try { jdbc.update("delete from " + table); } catch (RuntimeException ignored) { }
        }
    }

    private String account(String name, PlatformRole role) {
        var user = User.register(name, name.toLowerCase(Locale.ROOT) + "@iut-dhaka.edu",
                passwords.encode("password123"), role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC)); users.saveAndFlush(user);
        return sessions.login(new LoginRequest(user.getEmail(), "password123")).accessToken();
    }
    private SessionPrincipal principal(String token) { return sessions.authenticate(token); }

    @Test void committedNewAdministratorAssignmentIsDetectedAndRetried() throws Exception {
        var discovered = new CountDownLatch(1); var assigned = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var staleAttempt = pool.submit(() -> transactions.executeWithoutResult(status -> {
                var candidates = clubModeration.discover(targetId);
                discovered.countDown();
                await(assigned);
                clubModeration.lockCandidates(candidates);
                accounts.lockTarget(system, targetId);
                clubModeration.requireNoAdditionalClub(targetId, candidates);
            }));
            assertThat(discovered.await(10, TimeUnit.SECONDS)).isTrue();
            long club = clubs.create(system, new CreateClubRequest("New Club", "Tech", "Description", null, null, targetId)).id();
            assigned.countDown();
            assertThatThrownBy(() -> staleAttempt.get(15, TimeUnit.SECONDS))
                    .isInstanceOf(ExecutionException.class)
                    .hasCauseInstanceOf(ClubAssignmentSetChangedException.class);
            moderation.suspend(system, targetId, REQUEST);
            assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.PUBLISHING_SUSPENDED);
        }
    }

    @Test void suspensionHoldingAccountLockMakesNewAssignmentFailEligibility() throws Exception {
        var locked = new CountDownLatch(1); var proceed = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var suspension = pool.submit(() -> transactions.executeWithoutResult(status -> {
                accounts.lockTarget(system, targetId);
                locked.countDown();
                await(proceed);
                accounts.suspendLocked(targetId, LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
            }));
            assertThat(locked.await(10, TimeUnit.SECONDS)).isTrue();
            var assignment = pool.submit(() -> clubs.create(system,
                    new CreateClubRequest("Blocked Club", "Tech", "Description", null, null, targetId)));
            assertThatThrownBy(() -> assignment.get(300, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
            proceed.countDown(); suspension.get(15, TimeUnit.SECONDS);
            assertThatThrownBy(() -> assignment.get(15, TimeUnit.SECONDS))
                    .isInstanceOf(ExecutionException.class).hasCauseInstanceOf(BadRequestException.class);
            assertThat(jdbc.queryForObject("select count(*) from club_role_assignments where administrator_user_id=?", Integer.class, targetId)).isZero();
        }
    }

    @Test void committedReplacementToTargetIsDetectedAndClubIsSuspended() throws Exception {
        long club = clubs.create(system, new CreateClubRequest("Replace To", "Tech", "Description", null, null, replacement.userId())).id();
        var discovered = new CountDownLatch(1); var replaced = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var staleAttempt = pool.submit(() -> transactions.executeWithoutResult(status -> {
                var candidates = clubModeration.discover(targetId);
                discovered.countDown();
                await(replaced);
                clubModeration.lockCandidates(candidates);
                accounts.lockTarget(system, targetId);
                clubModeration.requireNoAdditionalClub(targetId, candidates);
            }));
            assertThat(discovered.await(10, TimeUnit.SECONDS)).isTrue();
            clubs.replaceAdministrator(system, club, new ReplaceAdministratorRequest(targetId, "Approved replacement", true));
            replaced.countDown();
            assertThatThrownBy(() -> staleAttempt.get(15, TimeUnit.SECONDS))
                    .isInstanceOf(ExecutionException.class)
                    .hasCauseInstanceOf(ClubAssignmentSetChangedException.class);
            moderation.suspend(system, targetId, REQUEST);
            assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.PUBLISHING_SUSPENDED);
        }
    }

    @Test void replacementAwayThatCommitsFirstLeavesClubActive() throws Exception {
        long club = clubs.create(system, new CreateClubRequest("Replace Away First", "Tech", "Description", null, null, targetId)).id();
        var discovered = new CountDownLatch(1); var replaced = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var staleAttempt = pool.submit(() -> transactions.executeWithoutResult(status -> {
                var candidates = clubModeration.discover(targetId);
                assertThat(candidates).containsExactly(club);
                discovered.countDown();
                await(replaced);
                clubModeration.lockCandidates(candidates);
                accounts.lockTarget(system, targetId);
                clubModeration.requireNoAdditionalClub(targetId, candidates);
                clubModeration.suspendAdministeredClubs(system.userId(), targetId, candidates,
                        REQUEST.reason(), LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
            }));
            assertThat(discovered.await(10, TimeUnit.SECONDS)).isTrue();
            clubs.replaceAdministrator(system, club,
                    new ReplaceAdministratorRequest(replacement.userId(), "Replacement committed first", true));
            replaced.countDown();
            staleAttempt.get(15, TimeUnit.SECONDS);
        }
        moderation.suspend(system, targetId, REQUEST);
        assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.ACTIVE);
    }

    @Test void suspensionThatCommitsFirstKeepsClubSuspendedAfterReplacementAway() throws Exception {
        long club = clubs.create(system, new CreateClubRequest("Suspend First", "Tech", "Description", null, null, targetId)).id();
        moderation.suspend(system, targetId, REQUEST);
        clubs.replaceAdministrator(system, club,
                new ReplaceAdministratorRequest(replacement.userId(), "Suspension committed first", true));
        assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.PUBLISHING_SUSPENDED);
    }

    @Test void concurrentDuplicateSuspensionsProduceOneTransition() throws Exception {
        long club = clubs.create(system, new CreateClubRequest("Duplicate", "Tech", "Description", null, null, targetId)).id();
        var start = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var a = pool.submit(() -> { start.await(); return moderation.suspend(system, targetId, REQUEST); });
            var b = pool.submit(() -> { start.await(); return moderation.suspend(system, targetId, REQUEST); });
            start.countDown(); a.get(15, TimeUnit.SECONDS); b.get(15, TimeUnit.SECONDS);
        }
        assertThat(jdbc.queryForObject("select count(*) from moderation_actions where target_user_id=?", Integer.class, targetId)).isEqualTo(1);
        assertThat(jdbc.queryForObject("select count(*) from club_audit where club_id=? and action='CLUB_PUBLISHING_SUSPENDED'", Integer.class, club)).isEqualTo(1);
    }

    @Test void suspensionRevokesARefreshRotationThatCommitsFirst() throws Exception {
        var existing = sessions.login(new LoginRequest("target@iut-dhaka.edu", "password123"));
        var rotated = new CountDownLatch(1); var release = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var refresh = pool.submit(() -> transactions.execute(status -> {
                var response = sessions.refresh(existing.refreshToken());
                rotated.countDown();
                await(release);
                return response;
            }));
            assertThat(rotated.await(10, TimeUnit.SECONDS)).isTrue();
            var suspension = pool.submit(() -> moderation.suspend(system, targetId, REQUEST));
            assertThatThrownBy(() -> suspension.get(300, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
            release.countDown();
            var refreshed = refresh.get(15, TimeUnit.SECONDS);
            suspension.get(15, TimeUnit.SECONDS);
            assertThatThrownBy(() -> sessions.authenticate(refreshed.accessToken()))
                    .isInstanceOf(InvalidSessionException.class);
            assertThatThrownBy(() -> sessions.refresh(refreshed.refreshToken()))
                    .isInstanceOf(InvalidSessionException.class);
        }
    }

    @Test void loginAndRefreshWaitingBehindSuspensionObserveCommittedState() throws Exception {
        var existing = sessions.login(new LoginRequest("target@iut-dhaka.edu", "password123"));
        var locked = new CountDownLatch(1); var release = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(3)) {
            var suspension = pool.submit(() -> transactions.executeWithoutResult(status -> {
                accounts.lockTarget(system, targetId);
                accounts.suspendLocked(targetId, LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
                sessions.revokeAllForAccount(targetId);
                locked.countDown();
                await(release);
            }));
            assertThat(locked.await(10, TimeUnit.SECONDS)).isTrue();
            var login = pool.submit(() -> sessions.login(new LoginRequest("target@iut-dhaka.edu", "password123")));
            var refresh = pool.submit(() -> sessions.refresh(existing.refreshToken()));
            assertThatThrownBy(() -> login.get(300, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
            assertThatThrownBy(() -> refresh.get(300, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
            release.countDown();
            suspension.get(15, TimeUnit.SECONDS);
            assertThatThrownBy(() -> login.get(15, TimeUnit.SECONDS))
                    .isInstanceOf(ExecutionException.class).hasCauseInstanceOf(InvalidCredentialsException.class);
            assertThatThrownBy(() -> refresh.get(15, TimeUnit.SECONDS))
                    .isInstanceOf(ExecutionException.class).hasCauseInstanceOf(InvalidSessionException.class);
        }
    }

    private static void await(CountDownLatch latch) {
        try {
            if (!latch.await(10, TimeUnit.SECONDS)) throw new AssertionError("Timed out waiting for test ordering latch");
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new AssertionError(exception);
        }
    }
}
