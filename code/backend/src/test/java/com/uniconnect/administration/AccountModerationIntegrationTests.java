package com.uniconnect.administration;

import com.uniconnect.administration.dto.*;
import com.uniconnect.administration.service.AccountModerationService;
import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.*;
import com.uniconnect.club.domain.ClubStatus;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.service.*;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.*;
import org.springframework.http.MediaType;
import org.springframework.transaction.event.*;
import org.springframework.test.web.servlet.MockMvc;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:account_moderation;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE")
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(AccountModerationIntegrationTests.FixedClockConfiguration.class)
class AccountModerationIntegrationTests {
    @Autowired AccountModerationService moderation;
    @Autowired ClubService clubs;
    @Autowired ClubLifecycleService lifecycle;
    @Autowired ClubContextService contexts;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired RevocationProbe revocations;

    private static final Instant NOW = Instant.parse("2026-10-19T00:00:00Z");
    private static final AccountModerationRequest REQUEST = new AccountModerationRequest("Policy review completed", true);
    private SessionPrincipal system, target, other;
    private String systemToken, targetToken;
    private long targetId;

    @TestConfiguration
    static class FixedClockConfiguration {
        @Bean @Primary Clock fixedClock() { return Clock.fixed(NOW, ZoneOffset.UTC); }
        @Bean RevocationProbe revocationProbe() { return new RevocationProbe(); }
    }

    static class RevocationProbe {
        private final List<Long> committed = Collections.synchronizedList(new ArrayList<>());
        @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
        void revoked(AccountSessionsRevoked event) { committed.add(event.userId()); }
        void clear() { committed.clear(); }
        List<Long> committed() { return List.copyOf(committed); }
    }

    @BeforeEach void setup() {
        clean(); revocations.clear();
        systemToken = account("System", PlatformRole.SYSTEM_ADMIN, true);
        system = sessions.authenticate(systemToken);
        targetToken = account("Target Student", PlatformRole.STUDENT, true);
        target = sessions.authenticate(targetToken); targetId = target.userId();
        other = sessions.authenticate(account("Other Student", PlatformRole.STUDENT, true));
        contexts.select(system, new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION, null));
    }

    @AfterEach void clean() {
        for (String table : List.of("audit_logs", "moderation_actions", "club_publication_audit",
                "club_announcements", "club_events", "authenticated_sessions", "club_creation_requests", "club_audit",
                "club_role_assignments", "clubs", "notifications", "connections", "profiles",
                "email_verification_tokens", "password_reset_tokens", "users")) {
            try { jdbc.update("delete from " + table); } catch (RuntimeException ignored) { }
        }
        try { jdbc.execute("alter table moderation_actions alter column action_id restart with 1"); }
        catch (RuntimeException ignored) { }
    }

    private String account(String name, PlatformRole role, boolean active) {
        var user = User.register(name, name.toLowerCase(Locale.ROOT).replace(' ', '.') + "@iut-dhaka.edu",
                passwords.encode("password123"), role);
        if (active) user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
        users.saveAndFlush(user);
        return active ? sessions.login(new LoginRequest(user.getEmail(), "password123")).accessToken() : null;
    }

    private int count(String sql) { return jdbc.queryForObject(sql, Integer.class); }

    @Test void suspensionRevokesEverySessionAndRestorationNeverRevivesCredentials() {
        var second = sessions.login(new LoginRequest("target.student@iut-dhaka.edu", "password123"));
        moderation.suspend(system, targetId, REQUEST);
        assertThat(revocations.committed()).containsExactly(targetId);
        assertThatThrownBy(() -> sessions.authenticate(targetToken)).isInstanceOf(InvalidSessionException.class);
        assertThatThrownBy(() -> sessions.authenticate(second.accessToken())).isInstanceOf(InvalidSessionException.class);
        assertThatThrownBy(() -> sessions.refresh(second.refreshToken())).isInstanceOf(InvalidSessionException.class);
        assertThat(count("select count(*) from authenticated_sessions where user_id=" + targetId + " and revoked_at is null")).isZero();

        moderation.restore(system, targetId, REQUEST);
        assertThatThrownBy(() -> sessions.authenticate(targetToken)).isInstanceOf(InvalidSessionException.class);
        assertThatThrownBy(() -> sessions.refresh(second.refreshToken())).isInstanceOf(InvalidSessionException.class);
        assertThat(sessions.authenticate(sessions.login(new LoginRequest("target.student@iut-dhaka.edu", "password123")).accessToken()).userId())
                .isEqualTo(targetId);
    }

    @Test void suspensionAndRestorationAreAuditedNotifiedAndIdempotent() {
        moderation.suspend(system, targetId, REQUEST);
        moderation.suspend(system, targetId, REQUEST);
        moderation.restore(system, targetId, REQUEST);
        moderation.restore(system, targetId, REQUEST);
        assertThat(count("select count(*) from moderation_actions where target_user_id=" + targetId)).isEqualTo(2);
        assertThat(count("select count(*) from audit_logs where subject_id=" + targetId)).isEqualTo(2);
        assertThat(count("select count(*) from notifications where recipient_id=" + targetId
                + " and type in ('ACCOUNT_SUSPENDED','ACCOUNT_REACTIVATED')")).isEqualTo(2);
        var rows = moderation.audit(system, targetId, 0, 20).items();
        assertThat(rows).extracting(AccountAuditResponse::reason).containsOnly(REQUEST.reason());
        assertThat(rows.getFirst().reversedAt()).isNull();
        assertThat(rows.getFirst().reversalOfActionId()).isEqualTo(rows.getLast().actionId());
        assertThat(rows.getLast().reversedAt()).isNotNull();
        var messages = jdbc.queryForList("select message from notifications where recipient_id=?", String.class, targetId);
        assertThat(messages).noneMatch(message -> message.contains(REQUEST.reason()));
    }

    @Test void administeredClubSuspendsAtomicallyAndOriginalAdministratorCanLaterQualifyForExplicitRestore() {
        long club = clubs.create(system, new CreateClubRequest("Moderated Club", "Technology", "Description", null, null, targetId)).id();
        moderation.suspend(system, targetId, REQUEST);
        assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.PUBLISHING_SUSPENDED);
        assertThat(count("select count(*) from club_role_assignments where club_id=" + club + " and revoked_at is null")).isEqualTo(1);
        assertThat(count("select count(*) from club_audit where club_id=" + club + " and action='CLUB_PUBLISHING_SUSPENDED'")).isEqualTo(1);
        moderation.suspend(system, targetId, REQUEST);
        assertThat(count("select count(*) from club_audit where club_id=" + club + " and action='CLUB_PUBLISHING_SUSPENDED'")).isEqualTo(1);
        moderation.restore(system, targetId, REQUEST);
        assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.PUBLISHING_SUSPENDED);
        assertThat(lifecycle.restore(system, club, new ClubLifecycleRequest("Account access restored", true)).status())
                .isEqualTo(ClubStatus.ACTIVE);
    }

    @Test void suspendingOneOfMultipleAdministratorsKeepsPublishingAvailableToTheOthers() {
        long club = clubs.create(system, new CreateClubRequest("Shared Club", "Technology", "Description", null, null, targetId)).id();
        clubs.assignAdministrator(system, club, new AssignAdministratorRequest(other.userId()));
        moderation.suspend(system, targetId, REQUEST);
        assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.ACTIVE);
        assertThat(count("select count(*) from club_role_assignments where club_id=" + club + " and revoked_at is null")).isEqualTo(2);
    }

    @Test void representativesAndMembersWithoutAnAdminAssignmentDoNotChangeClubState() {
        long club = clubs.create(system, new CreateClubRequest("Other Club", "Technology", "Description", null, null, other.userId())).id();
        contexts.select(other, new SelectContextRequest(ContextType.CLUB,
                contexts.get(other).availableContexts().stream().filter(c -> Objects.equals(c.clubId(), club)).findFirst().orElseThrow().assignmentId()));
        clubs.assignRepresentative(other, club, new AssignRepresentativeRequest(targetId));
        moderation.suspend(system, targetId, REQUEST);
        assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.ACTIVE);
    }

    @Test void systemAdministratorsPendingAccountsAndWrongContextAreRejected() {
        assertThatThrownBy(() -> moderation.suspend(system, system.userId(), REQUEST)).isInstanceOf(ForbiddenException.class);
        account("Pending Student", PlatformRole.STUDENT, false);
        long pending = jdbc.queryForObject("select user_id from users where full_name='Pending Student'", Long.class);
        assertThatThrownBy(() -> moderation.suspend(system, pending, REQUEST)).isInstanceOf(ConflictException.class);
        contexts.select(system, new SelectContextRequest(ContextType.PERSONAL, null));
        assertThatThrownBy(() -> moderation.suspend(system, targetId, REQUEST)).isInstanceOf(ForbiddenException.class);
    }

    @Test void activeAlumniAccountsAreEligibleForSuspensionAndRestoration() {
        long alumniId = sessions.authenticate(account("Target Alumni", PlatformRole.ALUMNI, true)).userId();
        assertThat(moderation.suspend(system, alumniId, REQUEST).accountStatus()).isEqualTo(AccountStatus.SUSPENDED);
        assertThat(moderation.restore(system, alumniId, REQUEST).accountStatus()).isEqualTo(AccountStatus.ACTIVE);
    }

    @Test void rollbackRestoresAccountClubAuditSessionsAndNotifications() {
        long club = clubs.create(system, new CreateClubRequest("Rollback Club", "Technology", "Description", null, null, targetId)).id();
        jdbc.update("insert into notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) "
                + "values (?,?,?,?,?,?,?,CURRENT_TIMESTAMP)", targetId, "ACCOUNT_SUSPENDED", "Seed", "Seed",
                "USER", targetId, "account-moderation:1");
        assertThatThrownBy(() -> moderation.suspend(system, targetId, REQUEST)).isInstanceOf(RuntimeException.class);
        assertThat(sessions.authenticate(targetToken).userId()).isEqualTo(targetId);
        assertThat(moderation.get(system, targetId).accountStatus()).isEqualTo(AccountStatus.ACTIVE);
        assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.ACTIVE);
        assertThat(count("select count(*) from moderation_actions")).isZero();
        assertThat(count("select count(*) from audit_logs")).isZero();
        assertThat(count("select count(*) from club_audit where action='CLUB_PUBLISHING_SUSPENDED'")).isZero();
        assertThat(revocations.committed()).isEmpty();
    }

    @Test void searchDetailsHttpValidationAndOpenApiUseAdministrationContext() throws Exception {
        assertThat(moderation.search(system, "target", PlatformRole.STUDENT, AccountStatus.ACTIVE, 0, 20).items())
                .extracting(AccountResponse::userId).containsExactly(targetId);
        mvc.perform(get("/api/v1/admin/accounts/" + targetId).header("Authorization", "Bearer " + systemToken))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.email").value("target.student@iut-dhaka.edu"));
        mvc.perform(post("/api/v1/admin/accounts/" + targetId + "/suspend")
                        .header("Authorization", "Bearer " + systemToken).contentType("application/json").content("{}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/admin/accounts/{id}/suspend'].post").exists());
    }

    @Test void everyAccountAdministrationEndpointRejectsPersonalContext() throws Exception {
        contexts.select(system, new SelectContextRequest(ContextType.PERSONAL, null));
        String body = "{\"reason\":\"Policy review completed\",\"confirm\":true}";

        mvc.perform(get("/api/v1/admin/accounts").header("Authorization", "Bearer " + systemToken))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ACCESS_DENIED"));
        mvc.perform(get("/api/v1/admin/accounts/" + targetId).header("Authorization", "Bearer " + systemToken))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ACCESS_DENIED"));
        mvc.perform(get("/api/v1/admin/accounts/" + targetId + "/audit")
                        .header("Authorization", "Bearer " + systemToken))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ACCESS_DENIED"));
        mvc.perform(post("/api/v1/admin/accounts/" + targetId + "/suspend")
                        .header("Authorization", "Bearer " + systemToken)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ACCESS_DENIED"));
        mvc.perform(post("/api/v1/admin/accounts/" + targetId + "/restore")
                        .header("Authorization", "Bearer " + systemToken)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ACCESS_DENIED"));
    }
}
