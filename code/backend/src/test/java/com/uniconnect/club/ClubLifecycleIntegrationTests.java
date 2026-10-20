package com.uniconnect.club;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.*;
import com.uniconnect.club.domain.*;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.service.*;
import com.uniconnect.club.publication.domain.*;
import com.uniconnect.club.publication.dto.*;
import com.uniconnect.club.publication.service.PublicationService;
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

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:club_lifecycle;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ClubLifecycleIntegrationTests {
    @Autowired ClubService clubs;
    @Autowired ClubLifecycleService lifecycle;
    @Autowired ClubContextService contexts;
    @Autowired PublicationService publications;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired PlatformTransactionManager transactions;
    @MockitoBean Clock clock;
    private SessionPrincipal system, alice, bob;
    private String systemToken, aliceToken, hash;
    private long club, assignment;
    private static final Instant NOW = Instant.parse("2026-10-16T00:00:00Z");
    private static final ClubLifecycleRequest REASON = new ClubLifecycleRequest("Reviewed by administration", true);
    @BeforeEach void setup() {
        clean(); when(clock.instant()).thenReturn(NOW); when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        hash = passwords.encode("password123");
        systemToken = account("System", PlatformRole.SYSTEM_ADMIN); system = sessions.authenticate(systemToken);
        aliceToken = account("Alice", PlatformRole.STUDENT); alice = sessions.authenticate(aliceToken);
        bob = sessions.authenticate(account("Bob", PlatformRole.STUDENT));
        contexts.select(system, new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION, null));
        club = clubs.create(system, new CreateClubRequest("Lifecycle club", "Technology", "Test club", null, null, alice.userId())).id();
        assignment = select(alice, club);
    }
    @AfterEach void clean() {
        for (String table : List.of("club_publication_audit", "club_announcements", "club_events", "authenticated_sessions", "club_creation_requests",
                "club_audit", "club_role_assignments", "clubs", "notifications", "users")) jdbc.update("delete from " + table);
    }
    private String account(String name, PlatformRole role) {
        var user = User.register(name, name.toLowerCase(Locale.ROOT)+"@iut-dhaka.edu", hash, role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC)); users.saveAndFlush(user);
        return sessions.login(new LoginRequest(user.getEmail(), "password123")).accessToken();
    }
    private long select(SessionPrincipal actor, long id) {
        var option = contexts.get(actor).availableContexts().stream().filter(c -> Objects.equals(c.clubId(), id)).findFirst().orElseThrow();
        contexts.select(actor, new SelectContextRequest(ContextType.CLUB, option.assignmentId())); return option.assignmentId();
    }
    private AnnouncementRequest announcement(AnnouncementStatus status) {
        return new AnnouncementRequest("Notice", "Content", AnnouncementPriority.NORMAL, status, null);
    }
    private EventRequest event() {
        var start = LocalDateTime.ofInstant(NOW.plusSeconds(3600), ZoneOffset.UTC);
        return new EventRequest("Event", "Description", "Lab", null, null, start, start.plusHours(1));
    }
    private int count(String sql) { return jdbc.queryForObject(sql, Integer.class); }
    @Test void suspensionPreservesVisibilityButBlocksNewPublishing() {
        long notice = publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.PUBLISHED)).id();
        long draft = publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.UNPUBLISHED)).id();
        long event = publications.createEvent(alice, club, event()).id();
        lifecycle.suspend(system, club, REASON);
        assertThat(clubs.get(bob, club).status()).isEqualTo(ClubStatus.PUBLISHING_SUSPENDED);
        assertThat(publications.publicAnnouncement(notice).id()).isEqualTo(notice);
        assertThat(publications.publicEvent(event).id()).isEqualTo(event);
        var pausedDraft = publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.UNPUBLISHED));
        assertThat(pausedDraft.status()).isEqualTo(AnnouncementStatus.UNPUBLISHED);
        assertThatThrownBy(() -> publications.publish(alice, club, draft)).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.PUBLISHED))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> publications.createEvent(alice, club, event())).isInstanceOf(ForbiddenException.class);
        publications.editAnnouncement(alice, club, notice, new AnnouncementEditRequest("Updated", "Content", AnnouncementPriority.NORMAL, null));
        lifecycle.restore(system, club, REASON);
        assertThat(publications.publish(alice, club, draft).status()).isEqualTo(AnnouncementStatus.PUBLISHED);
    }
    @Test void transitionsAreAuditedAndRetriesDoNotDuplicateNotifications() {
        lifecycle.suspend(system, club, REASON); lifecycle.suspend(system, club, REASON);
        lifecycle.restore(system, club, REASON); lifecycle.restore(system, club, REASON);
        assertThat(count("select count(*) from club_audit where action like 'CLUB_PUBLISHING_%'")).isEqualTo(2);
        assertThat(count("select count(*) from notifications where type='PUBLISHING_RESTORED'")).isEqualTo(1);
        var audit = clubs.auditHistory(system, club, 0, 20).items().getFirst();
        assertThat(audit.previousState()).isEqualTo(ClubStatus.PUBLISHING_SUSPENDED);
        assertThat(audit.newState()).isEqualTo(ClubStatus.ACTIVE);
        assertThat(audit.targetAssignmentId()).isNull();
        assertThat(audit.actorId()).isEqualTo(system.userId());
        assertThat(audit.reason()).isEqualTo(REASON.reason());
        lifecycle.suspend(system, club, REASON); lifecycle.restore(system, club, REASON);
        assertThat(count("select count(*) from notifications where type='PUBLISHING_RESTORED'")).isEqualTo(2);
    }
    @Test void restorationRequiresEligibleAdministratorAndReplacementDoesNotAutoRestore() {
        lifecycle.suspend(system, club, REASON);
        jdbc.update("update users set account_status='SUSPENDED' where user_id=?", alice.userId());
        assertThatThrownBy(() -> lifecycle.restore(system, club, REASON)).isInstanceOf(ConflictException.class);
        clubs.replaceAdministrator(system, club, new ReplaceAdministratorRequest(bob.userId(), "Eligible replacement", true));
        assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.PUBLISHING_SUSPENDED);
        assertThat(lifecycle.restore(system, club, REASON).status()).isEqualTo(ClubStatus.ACTIVE);
        assertThat(jdbc.queryForObject("select recipient_id from notifications where type='PUBLISHING_RESTORED'", Long.class)).isEqualTo(bob.userId());
    }
    @Test void nonStudentAndAnonymizedAdministratorsCannotRestorePublishing() {
        lifecycle.suspend(system, club, REASON);
        jdbc.update("update users set platform_role='ALUMNI' where user_id=?", alice.userId());
        assertThatThrownBy(() -> lifecycle.restore(system, club, REASON)).isInstanceOf(ConflictException.class);
        jdbc.update("update users set platform_role='STUDENT',anonymized_at=CURRENT_TIMESTAMP where user_id=?", alice.userId());
        assertThatThrownBy(() -> lifecycle.restore(system, club, REASON)).isInstanceOf(ConflictException.class);
        assertThat(count("select count(*) from notifications where type='PUBLISHING_RESTORED'")).isZero();
    }
    @Test void archiveHidesClubAndPublicationsButPreservesThemForRestoration() {
        long notice = publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.PUBLISHED)).id();
        long event = publications.createEvent(alice, club, event()).id();

        assertThat(lifecycle.archive(system, club, REASON).status()).isEqualTo(ClubStatus.ARCHIVED);
        assertThat(lifecycle.archive(system, club, REASON).status()).isEqualTo(ClubStatus.ARCHIVED);
        assertThat(contexts.get(alice).activeContext().contextType()).isEqualTo(ContextType.PERSONAL);
        assertThat(contexts.get(alice).availableContexts()).hasSize(1);
        assertThat(clubs.directory(bob, "Lifecycle club", 0, 20).items()).isEmpty();
        assertThatThrownBy(() -> clubs.get(alice, club)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> publications.publicAnnouncement(notice)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> publications.publicEvent(event)).isInstanceOf(ResourceNotFoundException.class);
        assertThat(clubs.adminDirectory(system, "Lifecycle club", 0, 20).items())
                .singleElement().satisfies(row -> assertThat(row.club().status()).isEqualTo(ClubStatus.ARCHIVED));
        assertThat(count("select count(*) from club_announcements")).isEqualTo(1);
        assertThat(count("select count(*) from club_events")).isEqualTo(1);
        assertThat(count("select count(*) from club_audit where action='CLUB_ARCHIVED'")).isEqualTo(1);

        assertThat(lifecycle.restoreArchive(system, club, REASON).status()).isEqualTo(ClubStatus.ACTIVE);
        assertThat(clubs.directory(bob, "Lifecycle club", 0, 20).items()).hasSize(1);
        assertThat(publications.publicAnnouncement(notice).id()).isEqualTo(notice);
        assertThat(publications.publicEvent(event).id()).isEqualTo(event);
        assertThat(contexts.get(alice).availableContexts()).hasSize(2);
        var audits = clubs.auditHistory(system, club, 0, 20).items();
        assertThat(audits).extracting(ClubAuditResponse::action)
                .containsSubsequence("CLUB_ARCHIVE_RESTORED", "CLUB_ARCHIVED");
        assertThat(audits.getFirst().previousState()).isEqualTo(ClubStatus.ARCHIVED);
        assertThat(audits.getFirst().newState()).isEqualTo(ClubStatus.ACTIVE);
    }
    @Test void restoringArchivedSuspendedClubReturnsItToSuspendedState() {
        lifecycle.suspend(system, club, REASON);
        lifecycle.archive(system, club, REASON);

        assertThat(lifecycle.restoreArchive(system, club, REASON).status()).isEqualTo(ClubStatus.PUBLISHING_SUSPENDED);
        assertThatThrownBy(() -> publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.PUBLISHED)))
                .isInstanceOf(ForbiddenException.class);
        assertThat(clubs.auditHistory(system, club, 0, 20).items()).extracting(ClubAuditResponse::action)
                .containsSubsequence("CLUB_ARCHIVE_RESTORED", "CLUB_ARCHIVED", "CLUB_PUBLISHING_SUSPENDED");
    }
    @Test void deletingAnArchivedClubRemovesItFromAdminListAndItCannotBeRestored() {
        lifecycle.archive(system, club, REASON);
        assertThat(clubs.adminDirectory(system, "Lifecycle club", 0, 20).totalElements()).isEqualTo(1);

        assertThat(lifecycle.delete(system, club, REASON).status()).isEqualTo(ClubStatus.REMOVED);
        assertThat(clubs.adminDirectory(system, "Lifecycle club", 0, 20).items()).isEmpty();
        assertThat(clubs.adminDirectory(system, "Lifecycle club", 0, 20).totalElements()).isZero();
        assertThatThrownBy(() -> lifecycle.restoreArchive(system, club, REASON)).isInstanceOf(ConflictException.class);
        assertThat(count("select count(*) from club_audit where action='CLUB_REMOVED'")).isEqualTo(1);
    }
    @Test void removalRetainsContentAndHistoryAndPreservesAdministratorAssignments() {
        long notice = publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.PUBLISHED)).id();
        long event = publications.createEvent(alice, club, event()).id();
        var rep = clubs.assignRepresentative(alice, club, new AssignRepresentativeRequest(bob.userId())); select(bob, club);
        var second = sessions.authenticate(sessions.login(new LoginRequest("alice@iut-dhaka.edu", "password123")).accessToken()); select(second, club);
        lifecycle.remove(system, club, REASON); lifecycle.remove(system, club, REASON);
        for (var actor : List.of(alice, bob, second)) {
            assertThat(contexts.get(actor).activeContext().contextType()).isEqualTo(ContextType.PERSONAL);
            assertThat(contexts.get(actor).availableContexts()).hasSize(1);
            assertThat(sessions.currentUser(actor)).isNotNull();
        }
        assertThatThrownBy(() -> contexts.select(bob, new SelectContextRequest(ContextType.CLUB, rep.id()))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> publications.publicAnnouncement(notice)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> publications.publicEvent(event)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> clubs.get(alice, club)).isInstanceOf(ResourceNotFoundException.class);
        assertThat(clubs.directory(alice, "", 0, 20).items()).isEmpty();
        assertThatThrownBy(() -> clubs.assignRepresentative(alice, club, new AssignRepresentativeRequest(bob.userId()))).isInstanceOf(ResourceNotFoundException.class);
        assertThat(count("select count(*) from club_announcements")).isEqualTo(1);
        assertThat(count("select count(*) from club_events")).isEqualTo(1);
        assertThat(count("select count(*) from club_publication_audit")).isEqualTo(2);
        assertThat(count("select count(*) from club_role_assignments where revoked_at is null")).isEqualTo(2);
        assertThat(count("select count(*) from club_audit where action='CLUB_REMOVED'")).isEqualTo(1);
        assertThat(lifecycle.get(system, club).status()).isEqualTo(ClubStatus.REMOVED);
        assertThat(clubs.auditHistory(system, club, 0, 20).items()).extracting(ClubAuditResponse::action).contains("CLUB_REMOVED");
        assertThatThrownBy(() -> lifecycle.restore(system, club, REASON)).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> lifecycle.suspend(system, club, REASON)).isInstanceOf(ConflictException.class);
        clubs.create(system, new CreateClubRequest("Next club", "Tech", "Description", null, null, alice.userId()));
    }
    @Test void removalOfOneClubLeavesOtherClubContextIntact() {
        long other = clubs.create(system, new CreateClubRequest("Other", "Tech", "Description", null, null, bob.userId())).id();
        select(bob, other); clubs.assignRepresentative(bob, other, new AssignRepresentativeRequest(alice.userId())); select(alice, other);
        lifecycle.suspend(system, club, REASON); lifecycle.remove(system, club, REASON);
        assertThat(contexts.get(alice).activeContext().clubId()).isEqualTo(other);
        assertThat(contexts.get(bob).activeContext().clubId()).isEqualTo(other);
    }
    @Test void removalRollsBackStateAssignmentsContextsAuditsAndNotificationsTogether() {
        int audits = count("select count(*) from club_audit"); int notices = count("select count(*) from notifications");
        new TransactionTemplate(transactions).executeWithoutResult(status -> { lifecycle.remove(system, club, REASON); status.setRollbackOnly(); });
        assertThat(clubs.get(alice, club).status()).isEqualTo(ClubStatus.ACTIVE);
        assertThat(contexts.get(alice).activeContext().assignmentId()).isEqualTo(assignment);
        assertThat(count("select count(*) from club_audit")).isEqualTo(audits);
        assertThat(count("select count(*) from notifications")).isEqualTo(notices);
    }
    @Test void authorizationAppliesToActionsRetriesAndRetainedReads() {
        assertThatThrownBy(() -> lifecycle.suspend(alice, club, REASON)).isInstanceOf(ForbiddenException.class);
        contexts.select(system, new SelectContextRequest(ContextType.PERSONAL, null));
        assertThatThrownBy(() -> lifecycle.remove(system, club, REASON)).isInstanceOf(ForbiddenException.class);
        contexts.select(system, new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION, null));
        lifecycle.remove(system, club, REASON);
        assertThatThrownBy(() -> lifecycle.remove(alice, club, REASON)).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> lifecycle.get(alice, club)).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> clubs.auditHistory(alice, club, 0, 20)).isInstanceOf(ForbiddenException.class);
        sessions.logout(system);
        assertThatThrownBy(() -> lifecycle.remove(system, club, REASON)).isInstanceOf(InvalidSessionException.class);
    }
    @Test void concurrentSuspensionProducesOneTransition() throws Exception {
        var start = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var a = pool.submit(() -> { start.await(); return lifecycle.suspend(system, club, REASON); });
            var b = pool.submit(() -> { start.await(); return lifecycle.suspend(system, club, REASON); });
            start.countDown(); a.get(15, TimeUnit.SECONDS); b.get(15, TimeUnit.SECONDS);
        }
        assertThat(count("select count(*) from club_audit where action='CLUB_PUBLISHING_SUSPENDED'")).isEqualTo(1);
        assertThat(count("select count(*) from notifications where type='PUBLISHING_SUSPENDED'")).isEqualTo(1);
    }
    @Test void httpValidationAuthorizationAndOpenApi() throws Exception {
        String path = "/api/v1/admin/clubs/"+club+"/publishing/suspend";
        mvc.perform(post(path).contentType("application/json").content("{}")).andExpect(status().isUnauthorized());
        mvc.perform(post(path).header("Authorization", "Bearer "+aliceToken).contentType("application/json").content("{\"reason\":\"Review\",\"confirm\":true}")).andExpect(status().isForbidden());
        String archivePath = "/api/v1/admin/clubs/"+club+"/archive";
        String restoreArchivePath = archivePath+"/restore";
        mvc.perform(post(archivePath).header("Authorization", "Bearer "+aliceToken).contentType("application/json").content("{\"reason\":\"Review\",\"confirm\":true}"))
                .andExpect(status().isForbidden());
        mvc.perform(post(archivePath).header("Authorization", "Bearer "+systemToken).contentType("application/json").content("{\"reason\":\"Review\",\"confirm\":true}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("ARCHIVED"));
        mvc.perform(post(restoreArchivePath).header("Authorization", "Bearer "+systemToken).contentType("application/json").content("{\"reason\":\"Review\",\"confirm\":true}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("ACTIVE"));
        for (String body : List.of("{}", "{\"reason\":\"Review\",\"confirm\":false}", "{\"reason\":\" \",\"confirm\":true}"))
            mvc.perform(post(path).header("Authorization", "Bearer "+systemToken).contentType("application/json").content(body)).andExpect(status().isBadRequest());
        mvc.perform(post(path).header("Authorization", "Bearer "+systemToken).contentType("application/json").content("{\"reason\":\"Review\",\"confirm\":true}"))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store")).andExpect(jsonPath("$.status").value("PUBLISHING_SUSPENDED"));
        mvc.perform(post("/api/v1/admin/clubs/"+club+"/delete").header("Authorization", "Bearer "+systemToken)
                        .contentType("application/json").content("{\"reason\":\"No longer required\",\"confirm\":true}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("REMOVED"));
        mvc.perform(get("/api/v1/admin/clubs").header("Authorization", "Bearer "+systemToken).param("search", "Lifecycle club"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.totalElements").value(0));
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/admin/clubs/{id}/publishing/restore'].post.responses['200']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/admin/clubs/{id}/archive'].post.responses['200']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/admin/clubs/{id}/archive/restore'].post.responses['200']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/admin/clubs/{id}/delete'].post.responses['200']").exists());
    }
}
