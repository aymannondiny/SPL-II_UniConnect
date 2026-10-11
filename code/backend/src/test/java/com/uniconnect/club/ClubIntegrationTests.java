package com.uniconnect.club;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.*;
import com.uniconnect.club.domain.*;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.service.*;
import com.uniconnect.notification.service.NotificationService;
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
class ClubIntegrationTests {
    @Autowired ClubService clubs;
    @Autowired ClubContextService contexts;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired NotificationService notifications;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired PlatformTransactionManager transactions;
    @MockitoBean Clock clock;
    private SessionPrincipal system, alice, bob, carol, alumni;
    private String systemToken, aliceToken, hash;
    private static final Instant NOW = Instant.parse("2026-10-10T00:00:00Z");
    @BeforeEach
    void setup() {
        clean(); when(clock.instant()).thenReturn(NOW); when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        hash = passwords.encode("password123");
        systemToken = account("System", PlatformRole.SYSTEM_ADMIN); system = sessions.authenticate(systemToken);
        aliceToken = account("Alice", PlatformRole.STUDENT); alice = sessions.authenticate(aliceToken);
        bob = sessions.authenticate(account("Bob", PlatformRole.STUDENT));
        carol = sessions.authenticate(account("Carol", PlatformRole.STUDENT));
        alumni = sessions.authenticate(account("Alumni", PlatformRole.ALUMNI));
        contexts.select(system, new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION, null));
    }
    @AfterEach
    void clean() {
        // Sessions reference assignments; clear them before retained assignment history.
        for (String table : List.of("authenticated_sessions", "club_audit", "club_role_assignments", "clubs",
                "chat_message_states", "chat_messages", "chat_participants", "chat_conversations", "notifications", "connections",
                "profile_skills", "profile_interests", "personal_profiles", "skills", "interests", "programme_degrees", "programmes", "departments",
                "password_reset_tokens", "email_verification_tokens", "users")) jdbc.update("delete from " + table);
    }
    private String account(String name, PlatformRole role) {
        var user = User.register(name, name.toLowerCase(Locale.ROOT) + "@iut-dhaka.edu", hash, role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC)); users.saveAndFlush(user);
        return sessions.login(new LoginRequest(user.getEmail(), "password123")).accessToken();
    }
    private CreateClubRequest request(String name, SessionPrincipal administrator) {
        return new CreateClubRequest(name, "Technology", "University student club", null, "club@iut-dhaka.edu", administrator.userId());
    }
    private ClubResponse create(String name, SessionPrincipal administrator) { return clubs.create(system, request(name, administrator)); }
    private long selectClub(SessionPrincipal actor, long clubId) {
        var option = contexts.get(actor).availableContexts().stream().filter(c -> Objects.equals(c.clubId(), clubId)).findFirst().orElseThrow();
        contexts.select(actor, new SelectContextRequest(ContextType.CLUB, option.assignmentId())); return option.assignmentId();
    }
    private int count(String table) { return jdbc.queryForObject("select count(*) from " + table, Integer.class); }
    private ReplaceAdministratorRequest replacement(SessionPrincipal user) { return new ReplaceAdministratorRequest(user.userId(), "Term handover", true); }
    private RevokeRepresentativeRequest revoke() { return new RevokeRepresentativeRequest("Representative term completed", true); }

    @Test
    void createIsAtomicAndPreservesStudentRoleWithOneGrantNotification() {
        var club = create("Computing Club", alice);
        assertThat(club.status()).isEqualTo(ClubStatus.ACTIVE);
        assertThat(count("clubs")).isEqualTo(1); assertThat(count("club_role_assignments")).isEqualTo(1);
        assertThat(count("notifications")).isEqualTo(1); assertThat(count("club_audit")).isEqualTo(2);
        assertThat(sessions.currentUser(alice).platformRole()).isEqualTo(PlatformRole.STUDENT);
        var option = contexts.get(alice).availableContexts().get(1);
        assertThat(option.clubRole()).isEqualTo(ClubRole.CLUB_ADMINISTRATOR);
        var notification = notifications.list(alice, 0, 20).items().getFirst();
        assertThat(notification.referenceType()).isEqualTo("CLUB"); assertThat(notification.referenceId()).isEqualTo(club.id());
        assertThat(notification.message()).contains("CLUB_ADMINISTRATOR");
    }
    @Test
    void systemRoleAndSystemContextAreBothRequired() {
        assertThatThrownBy(() -> clubs.create(alice, request("Club", bob))).isInstanceOf(ForbiddenException.class);
        contexts.select(system, new SelectContextRequest(ContextType.PERSONAL, null));
        assertThatThrownBy(() -> create("Club", alice)).isInstanceOf(ForbiddenException.class);
        assertThat(count("clubs")).isZero();
        assertThatThrownBy(() -> contexts.select(alice, new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION, null))).isInstanceOf(ForbiddenException.class);
    }
    @Test
    void databaseRoleIsRecheckedInsteadOfTrustingPrincipalRole() {
        var forged = new SessionPrincipal(alice.sessionId(), alice.userId(), PlatformRole.SYSTEM_ADMIN);
        assertThatThrownBy(() -> contexts.select(forged, new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION, null))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> clubs.create(forged, request("Club", bob))).isInstanceOf(ForbiddenException.class);
    }
    @Test
    void assigneesMustBeActiveStudents() {
        assertThatThrownBy(() -> create("Alumni club", alumni)).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> create("System club", system)).isInstanceOf(BadRequestException.class);
        jdbc.update("update users set account_status='SUSPENDED' where user_id=?", alice.userId());
        assertThatThrownBy(() -> create("Suspended club", alice)).isInstanceOf(BadRequestException.class);
        jdbc.update("update users set anonymized_at=? where user_id=?", LocalDateTime.ofInstant(NOW, ZoneOffset.UTC), bob.userId());
        assertThatThrownBy(() -> create("Anonymized club", bob)).isInstanceOf(BadRequestException.class);
        assertThat(count("clubs")).isZero(); assertThat(count("notifications")).isZero();
    }
    @Test
    void normalizedNamesAndOneAdministratorPerUserAreEnforced() {
        create(" Computing Club ", alice);
        assertThatThrownBy(() -> create("computing club", bob)).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> create("Another Club", alice)).isInstanceOf(ConflictException.class);
        assertThat(count("clubs")).isEqualTo(1);
    }
    @Test
    void transactionRollbackRemovesClubAssignmentAuditAndNotification() {
        new TransactionTemplate(transactions).executeWithoutResult(status -> { create("Rolled back", alice); status.setRollbackOnly(); });
        for (String table : List.of("clubs", "club_role_assignments", "club_audit", "notifications")) assertThat(count(table)).isZero();
    }
    @Test
    void selectedContextMustMatchTheManagedClubAndAdministratorRole() {
        var first = create("First", alice); var second = create("Second", bob);
        assertThatThrownBy(() -> clubs.assignRepresentative(alice, first.id(), new AssignRepresentativeRequest(carol.userId()))).isInstanceOf(ForbiddenException.class);
        selectClub(alice, first.id());
        assertThatThrownBy(() -> clubs.assignRepresentative(alice, second.id(), new AssignRepresentativeRequest(carol.userId()))).isInstanceOf(ForbiddenException.class);
        clubs.assignRepresentative(alice, first.id(), new AssignRepresentativeRequest(carol.userId())); selectClub(carol, first.id());
        assertThatThrownBy(() -> clubs.assignRepresentative(carol, first.id(), new AssignRepresentativeRequest(bob.userId()))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> clubs.operators(carol, first.id(), "ALL", 0, 20)).isInstanceOf(ForbiddenException.class);
    }
    @Test
    void representativesCanServeMultipleClubsButCannotHoldTwoRolesInOneClub() {
        var first = create("First", alice); var second = create("Second", bob);
        selectClub(alice, first.id()); selectClub(bob, second.id());
        clubs.assignRepresentative(alice, first.id(), new AssignRepresentativeRequest(carol.userId()));
        clubs.assignRepresentative(bob, second.id(), new AssignRepresentativeRequest(carol.userId()));
        assertThat(contexts.get(carol).availableContexts()).hasSize(3);
        assertThatThrownBy(() -> clubs.assignRepresentative(alice, first.id(), new AssignRepresentativeRequest(carol.userId()))).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> clubs.assignRepresentative(alice, first.id(), new AssignRepresentativeRequest(alice.userId()))).isInstanceOf(ConflictException.class);
        clubs.assignRepresentative(bob, second.id(), new AssignRepresentativeRequest(alice.userId()));
        assertThat(contexts.get(alice).availableContexts()).hasSize(3);
    }
    @Test
    void representativeGrantRejectsAlumniAndSuspendedStudents() {
        var club = create("Club", alice); selectClub(alice, club.id());
        assertThatThrownBy(() -> clubs.assignRepresentative(alice, club.id(), new AssignRepresentativeRequest(alumni.userId()))).isInstanceOf(BadRequestException.class);
        jdbc.update("update users set account_status='SUSPENDED' where user_id=?", bob.userId());
        assertThatThrownBy(() -> clubs.assignRepresentative(alice, club.id(), new AssignRepresentativeRequest(bob.userId()))).isInstanceOf(BadRequestException.class);
    }
    @Test
    void revocationClearsEverySelectedSessionAndRetainsHistoryAndPersonalAccess() {
        var club = create("Club", alice); selectClub(alice, club.id());
        var assignment = clubs.assignRepresentative(alice, club.id(), new AssignRepresentativeRequest(bob.userId()));
        var otherLogin = sessions.login(new LoginRequest("bob@iut-dhaka.edu", "password123")); var otherSession = sessions.authenticate(otherLogin.accessToken());
        selectClub(bob, club.id()); selectClub(otherSession, club.id());
        var result = clubs.revokeRepresentative(alice, club.id(), assignment.id(), revoke());
        assertThat(result.current()).isFalse(); assertThat(result.revokedBy()).isEqualTo(alice.userId());
        assertThat(contexts.get(bob).activeContext().contextType()).isEqualTo(ContextType.PERSONAL);
        assertThat(contexts.get(otherSession).activeContext().contextType()).isEqualTo(ContextType.PERSONAL);
        assertThat(contexts.get(bob).availableContexts()).hasSize(1);
        assertThat(sessions.currentUser(bob).platformRole()).isEqualTo(PlatformRole.STUDENT);
        assertThat(clubs.operators(alice, club.id(), "REVOKED", 0, 20).items()).extracting(AssignmentResponse::id).containsExactly(assignment.id());
        assertThatThrownBy(() -> contexts.select(bob, new SelectContextRequest(ContextType.CLUB, assignment.id()))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> clubs.revokeRepresentative(alice, club.id(), assignment.id(), revoke())).isInstanceOf(ConflictException.class);
        assertThat(notifications.list(bob, 0, 20).totalElements()).isEqualTo(2);
    }
    @Test
    void revokingOneClubDoesNotClearAnotherSelectedClub() {
        var first = create("First", alice); var second = create("Second", bob);
        selectClub(alice, first.id()); selectClub(bob, second.id());
        var assignment = clubs.assignRepresentative(alice, first.id(), new AssignRepresentativeRequest(carol.userId()));
        clubs.assignRepresentative(bob, second.id(), new AssignRepresentativeRequest(carol.userId())); selectClub(carol, second.id());
        clubs.revokeRepresentative(alice, first.id(), assignment.id(), revoke());
        assertThat(contexts.get(carol).activeContext().clubId()).isEqualTo(second.id());
    }
    @Test
    void administratorCannotBeRevokedThroughRepresentativeEndpoint() {
        var club = create("Club", alice); long assignment = selectClub(alice, club.id());
        assertThatThrownBy(() -> clubs.revokeRepresentative(alice, club.id(), assignment, revoke())).isInstanceOf(ForbiddenException.class);
        assertThat(clubs.operators(alice, club.id(), "CURRENT", 0, 20).totalElements()).isEqualTo(1);
    }
    @Test
    void replacementRevokesOldAdministratorAndPreservesAuditAndNotifications() {
        var club = create("Club", alice); long old = selectClub(alice, club.id());
        var replacement = clubs.replaceAdministrator(system, club.id(), replacement(bob));
        assertThat(replacement.role()).isEqualTo(ClubRole.CLUB_ADMINISTRATOR);
        assertThat(contexts.get(alice).activeContext().contextType()).isEqualTo(ContextType.PERSONAL);
        assertThatThrownBy(() -> clubs.operators(alice, club.id(), "ALL", 0, 20)).isInstanceOf(ForbiddenException.class);
        selectClub(bob, club.id()); assertThat(clubs.operators(bob, club.id(), "CURRENT", 0, 20).items()).extracting(AssignmentResponse::id).containsExactly(replacement.id());
        assertThat(clubs.operators(bob, club.id(), "REVOKED", 0, 20).items()).extracting(AssignmentResponse::id).containsExactly(old);
        assertThat(clubs.auditHistory(system, club.id(), 0, 20).items()).extracting(ClubAuditResponse::action).contains("ADMINISTRATOR_REPLACED", "ROLE_REVOKED", "ROLE_GRANTED");
        assertThat(notifications.list(alice, 0, 20).totalElements()).isEqualTo(2);
        create("Alice's next club", alice);
    }
    @Test
    void promotingRepresentativeUsesNewAssignmentAndInvalidatesOldContext() {
        var club = create("Club", alice); selectClub(alice, club.id());
        var rep = clubs.assignRepresentative(alice, club.id(), new AssignRepresentativeRequest(bob.userId())); selectClub(bob, club.id());
        var admin = clubs.replaceAdministrator(system, club.id(), replacement(bob));
        assertThat(admin.id()).isNotEqualTo(rep.id());
        assertThat(contexts.get(bob).activeContext().contextType()).isEqualTo(ContextType.PERSONAL);
        assertThatThrownBy(() -> contexts.select(bob, new SelectContextRequest(ContextType.CLUB, rep.id()))).isInstanceOf(ForbiddenException.class);
        selectClub(bob, club.id()); assertThat(clubs.operators(bob, club.id(), "CURRENT", 0, 20).totalElements()).isEqualTo(1);
    }
    @Test
    void failedReplacementDoesNotRevokeCurrentAdministrator() {
        var first = create("First", alice); create("Second", bob); long old = selectClub(alice, first.id());
        assertThatThrownBy(() -> clubs.replaceAdministrator(system, first.id(), replacement(bob))).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> clubs.replaceAdministrator(system, first.id(), replacement(alumni))).isInstanceOf(BadRequestException.class);
        assertThat(clubs.operators(alice, first.id(), "CURRENT", 0, 20).items().getFirst().id()).isEqualTo(old);
        assertThat(count("notifications")).isEqualTo(2);
    }
    @Test
    void contextSelectionIsSessionScopedAndSurvivesTokenRefresh() {
        var club = create("Club", alice); selectClub(alice, club.id());
        var login = sessions.login(new LoginRequest("alice@iut-dhaka.edu", "password123")); var other = sessions.authenticate(login.accessToken());
        assertThat(contexts.get(other).activeContext().contextType()).isEqualTo(ContextType.PERSONAL);
        assertThat(contexts.get(alice).activeContext().clubId()).isEqualTo(club.id());
        selectClub(other, club.id()); var refreshed = sessions.refresh(login.refreshToken());
        assertThat(contexts.get(sessions.authenticate(refreshed.accessToken())).activeContext().clubId()).isEqualTo(club.id());
    }
    @Test
    void cannotSelectAnotherUsersAssignmentOrAttachAssignmentToPersonalContext() {
        var club = create("Club", alice); long assignment = selectClub(alice, club.id());
        assertThatThrownBy(() -> contexts.select(bob, new SelectContextRequest(ContextType.CLUB, assignment))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> contexts.select(alice, new SelectContextRequest(ContextType.PERSONAL, assignment))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> contexts.select(alice, new SelectContextRequest(ContextType.CLUB, null))).isInstanceOf(BadRequestException.class);
    }
    @Test
    void revokedExpiredAndSuspendedSessionsCannotExerciseClubAuthority() {
        var club = create("Club", alice); selectClub(alice, club.id()); sessions.logout(alice);
        assertThatThrownBy(() -> clubs.operators(alice, club.id(), "CURRENT", 0, 20)).isInstanceOf(InvalidSessionException.class);
        jdbc.update("update users set account_status='SUSPENDED' where user_id=?", bob.userId());
        assertThatThrownBy(() -> contexts.get(bob)).isInstanceOf(InvalidSessionException.class);
        when(clock.instant()).thenReturn(NOW.plusSeconds(901));
        assertThatThrownBy(() -> contexts.get(system)).isInstanceOf(InvalidSessionException.class);
    }
    @Test
    void directoryIncludesPublishingSuspendedClubsButExcludesRemovedClubs() {
        var first = create("Computing", alice); var second = create("Robotics", bob);
        jdbc.update("update clubs set status='PUBLISHING_SUSPENDED' where club_id=?", first.id());
        jdbc.update("update clubs set status='REMOVED' where club_id=?", second.id());
        assertThat(clubs.directory(carol, "comput", 0, 20).items()).extracting(ClubResponse::id).containsExactly(first.id());
        assertThat(clubs.get(carol, first.id()).status()).isEqualTo(ClubStatus.PUBLISHING_SUSPENDED);
        assertThatThrownBy(() -> clubs.get(carol, second.id())).isInstanceOf(ResourceNotFoundException.class);
        assertThat(contexts.get(bob).availableContexts()).hasSize(1);
    }
    @Test
    void confirmationAndProfileValidationAreEnforced() {
        assertThatThrownBy(() -> clubs.create(system, new CreateClubRequest(" ", "Tech", "Description", null, null, alice.userId()))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> clubs.create(system, new CreateClubRequest("Club", "Tech", "Description", "javascript:alert(1)", null, alice.userId()))).isInstanceOf(BadRequestException.class);
        var club = create("Club", alice); selectClub(alice, club.id());
        var rep = clubs.assignRepresentative(alice, club.id(), new AssignRepresentativeRequest(bob.userId()));
        assertThatThrownBy(() -> clubs.revokeRepresentative(alice, club.id(), rep.id(), new RevokeRepresentativeRequest("Reason", false))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> clubs.replaceAdministrator(system, club.id(), new ReplaceAdministratorRequest(carol.userId(), "Reason", null))).isInstanceOf(BadRequestException.class);
    }
    @Test
    void simultaneousCreationForSameAdministratorHasOneWinner() throws Exception {
        var start = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var a = pool.submit(() -> attempt(start, () -> create("First", alice)));
            var b = pool.submit(() -> attempt(start, () -> create("Second", alice)));
            start.countDown(); assertThat(List.of(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS))).containsExactlyInAnyOrder("ok", "conflict");
        }
        assertThat(count("clubs")).isEqualTo(1); assertThat(count("notifications")).isEqualTo(1);
    }
    @Test
    void concurrentRevokeAndContextSelectionCannotLeaveRevokedContextActive() throws Exception {
        var club = create("Club", alice); selectClub(alice, club.id());
        var assignment = clubs.assignRepresentative(alice, club.id(), new AssignRepresentativeRequest(bob.userId()));
        var start = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var choosing = pool.submit(() -> {
                start.await();
                try { contexts.select(bob, new SelectContextRequest(ContextType.CLUB, assignment.id())); } catch (ForbiddenException expected) { }
                return true;
            });
            var revoking = pool.submit(() -> { start.await(); clubs.revokeRepresentative(alice, club.id(), assignment.id(), revoke()); return true; });
            start.countDown(); choosing.get(15, TimeUnit.SECONDS); revoking.get(15, TimeUnit.SECONDS);
        }
        assertThat(contexts.get(bob).activeContext().contextType()).isEqualTo(ContextType.PERSONAL);
    }
    private String attempt(CountDownLatch start, Runnable action) throws Exception {
        start.await(); try { action.run(); return "ok"; } catch (ConflictException expected) { return "conflict"; }
    }
    @Test
    void restRequiresAuthValidatesRequestsAndDocumentsCreatedResponses() throws Exception {
        mvc.perform(get("/api/v1/clubs")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/admin/clubs").header("Authorization", "Bearer " + aliceToken).contentType("application/json").content("{}"))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/admin/clubs").header("Authorization", "Bearer " + systemToken).contentType("application/json").content("{}"))
                .andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/auth/contexts").header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.activeContext.contextType").value("PERSONAL"));
        mvc.perform(get("/api/v1/clubs?size=51").header("Authorization", "Bearer " + aliceToken)).andExpect(status().isBadRequest());
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/admin/clubs'].post.responses['201']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/auth/contexts/active'].put.security[0].sessionBearer").exists());
    }
}
