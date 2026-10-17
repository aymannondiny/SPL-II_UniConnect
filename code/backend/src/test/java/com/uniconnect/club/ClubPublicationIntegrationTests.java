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
import tools.jackson.databind.json.JsonMapper;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:uniconnect_publications;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ClubPublicationIntegrationTests {
    @Autowired PublicationService publications;
    @Autowired ClubService clubs;
    @Autowired ClubContextService contexts;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired JsonMapper json;
    @Autowired PlatformTransactionManager transactions;
    @MockitoBean Clock clock;
    private SessionPrincipal system, alice, bob, carol;
    private String aliceToken, bobToken, hash;
    private long club, aliceAssignment, bobAssignment;
    private static final Instant NOW = Instant.parse("2026-10-12T10:00:00Z");
    private static final LocalDateTime TIME = LocalDateTime.ofInstant(NOW, ZoneOffset.UTC);
    @BeforeEach
    void setup() {
        clean(); when(clock.instant()).thenReturn(NOW); when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        hash = passwords.encode("password123");
        system = sessions.authenticate(account("System", PlatformRole.SYSTEM_ADMIN));
        aliceToken = account("Alice", PlatformRole.STUDENT); alice = sessions.authenticate(aliceToken);
        bobToken = account("Bob", PlatformRole.STUDENT); bob = sessions.authenticate(bobToken);
        carol = sessions.authenticate(account("Carol", PlatformRole.STUDENT));
        contexts.select(system, new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION, null));
        club = clubs.create(system, new CreateClubRequest("Computing Club", "Technology", "Student club", null, null, alice.userId())).id();
        aliceAssignment = select(alice, club);
        bobAssignment = clubs.assignRepresentative(alice, club, new AssignRepresentativeRequest(bob.userId())).id(); select(bob, club);
    }
    @AfterEach
    void clean() {
        for (String table : List.of("club_publication_audit", "club_announcements", "club_events", "authenticated_sessions", "club_audit",
                "club_role_assignments", "clubs", "notifications", "users")) jdbc.update("delete from " + table);
    }
    private String account(String name, PlatformRole role) {
        var user = User.register(name, name.toLowerCase(Locale.ROOT) + "@iut-dhaka.edu", hash, role);
        user.verifyEmail(TIME); users.saveAndFlush(user);
        return sessions.login(new LoginRequest(user.getEmail(), "password123")).accessToken();
    }
    private long select(SessionPrincipal actor, long clubId) {
        var context = contexts.get(actor).availableContexts().stream().filter(c -> Objects.equals(c.clubId(), clubId)).findFirst().orElseThrow();
        contexts.select(actor, new SelectContextRequest(ContextType.CLUB, context.assignmentId())); return context.assignmentId();
    }
    private AnnouncementRequest announcement(AnnouncementStatus status) { return new AnnouncementRequest("Workshop", "Join our workshop", AnnouncementPriority.NORMAL, status, null); }
    private AnnouncementEditRequest edit(String title) { return new AnnouncementEditRequest(title, "Updated description", AnnouncementPriority.IMPORTANT, null); }
    private PublicationActionRequest reason() { return new PublicationActionRequest(true, "Correcting club publication"); }
    private EventRequest event(long startSeconds, long endSeconds) {
        return new EventRequest("Workshop", "Learn Java", "Lab 1", "https://example.org/register", TIME.plusSeconds(startSeconds), TIME.plusSeconds(startSeconds), TIME.plusSeconds(endSeconds));
    }
    private long auditCount() { return jdbc.queryForObject("select count(*) from club_publication_audit", Long.class); }
    private String manage() { return "/api/v1/clubs/" + club + "/publications"; }

    @Test
    void draftIsPrivateAndPublishingIsIdempotent() throws Exception {
        var draft = publications.createAnnouncement(bob, club, announcement(AnnouncementStatus.UNPUBLISHED));
        assertThat(draft.publishedAt()).isNull(); assertThat(draft.authorAssignmentId()).isEqualTo(bobAssignment);
        assertThat(publications.announcements(null, null, null, null, null, 0, 20).totalElements()).isZero();
        mvc.perform(get("/api/v1/announcements/" + draft.id())).andExpect(status().isNotFound());
        mvc.perform(get(manage() + "/announcements")).andExpect(status().isUnauthorized());
        assertThatThrownBy(() -> publications.managedAnnouncement(carol, club, draft.id())).isInstanceOf(ForbiddenException.class);
        var published = publications.publish(bob, club, draft.id());
        assertThat(published.status()).isEqualTo(AnnouncementStatus.PUBLISHED); assertThat(published.publishedAt()).isEqualTo(TIME);
        publications.publish(bob, club, draft.id()); assertThat(auditCount()).isEqualTo(2);
        mvc.perform(get("/api/v1/announcements/" + draft.id())).andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", "no-store")).andExpect(jsonPath("$.title").value("Workshop"));
    }
    @Test
    void representativeCannotManageAnotherAssignmentAndAdministratorCan() {
        var own = publications.createAnnouncement(bob, club, announcement(AnnouncementStatus.UNPUBLISHED));
        var other = publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.UNPUBLISHED));
        assertThat(publications.managedAnnouncements(bob, club, null, 0, 20).items()).extracting(AnnouncementResponse::id).containsExactly(own.id());
        assertThat(publications.managedAnnouncements(alice, club, null, 0, 20).totalElements()).isEqualTo(2);
        assertThatThrownBy(() -> publications.editAnnouncement(bob, club, other.id(), edit("No"))).isInstanceOf(ForbiddenException.class);
        var edited = publications.editAnnouncement(alice, club, own.id(), edit("Approved"));
        assertThat(edited.authorAssignmentId()).isEqualTo(bobAssignment); assertThat(edited.authorUserId()).isEqualTo(bob.userId());
        assertThat(edited.title()).isEqualTo("Approved");
        assertThatThrownBy(() -> publications.auditHistory(bob, club, 0, 20)).isInstanceOf(ForbiddenException.class);
    }
    @Test
    void regrantDoesNotRestoreOldAuthorshipRightsForEitherPublicationType() {
        var a = publications.createAnnouncement(bob, club, announcement(AnnouncementStatus.UNPUBLISHED));
        var e = publications.createEvent(bob, club, event(60, 120));
        clubs.revokeRepresentative(alice, club, bobAssignment, new RevokeRepresentativeRequest("Term ended", true));
        assertThatThrownBy(() -> publications.editAnnouncement(bob, club, a.id(), edit("No"))).isInstanceOf(ForbiddenException.class);
        var replacement = clubs.assignRepresentative(alice, club, new AssignRepresentativeRequest(bob.userId())); select(bob, club);
        assertThat(replacement.id()).isNotEqualTo(bobAssignment);
        assertThatThrownBy(() -> publications.publish(bob, club, a.id())).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> publications.removeEvent(bob, club, e.id(), reason())).isInstanceOf(ForbiddenException.class);
        assertThat(publications.managedAnnouncements(bob, club, null, 0, 20).totalElements()).isZero();
        assertThat(publications.managedEvents(bob, club, null, null, 0, 20).totalElements()).isZero();
        publications.publish(alice, club, a.id()); publications.removeEvent(alice, club, e.id(), reason());
    }
    @Test
    void replacementAdministratorCanManageRetainedPublications() {
        var a = publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.UNPUBLISHED));
        clubs.replaceAdministrator(system, club, new ReplaceAdministratorRequest(carol.userId(), "Handover", true));
        assertThatThrownBy(() -> publications.publish(alice, club, a.id())).isInstanceOf(ForbiddenException.class);
        select(carol, club); assertThat(publications.publish(carol, club, a.id()).authorAssignmentId()).isEqualTo(aliceAssignment);
    }
    @Test
    void contextMustMatchAndExpiredSessionsCannotPublish() {
        contexts.select(bob, new SelectContextRequest(ContextType.PERSONAL, null));
        assertThatThrownBy(() -> publications.createEvent(bob, club, event(60, 120))).isInstanceOf(ForbiddenException.class);
        var second = clubs.create(system, new CreateClubRequest("Arts", "Culture", "Arts club", null, null, carol.userId()));
        select(carol, second.id());
        assertThatThrownBy(() -> publications.createAnnouncement(carol, club, announcement(AnnouncementStatus.PUBLISHED))).isInstanceOf(ForbiddenException.class);
        when(clock.instant()).thenReturn(NOW.plusSeconds(901));
        assertThatThrownBy(() -> publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.PUBLISHED))).isInstanceOf(InvalidSessionException.class);
    }
    @Test
    void suspendedActorCannotPublishAndSystemRoleAloneCannotPublish() {
        assertThatThrownBy(() -> publications.createEvent(system, club, event(60, 120))).isInstanceOf(ForbiddenException.class);
        jdbc.update("update users set account_status='SUSPENDED' where user_id=?", bob.userId());
        assertThatThrownBy(() -> publications.createEvent(bob, club, event(60, 120))).isInstanceOf(InvalidSessionException.class);
    }
    @Test
    void unpublishRepublishAndRemoveRetainIdentityAndAuditSnapshots() {
        var a = publications.createAnnouncement(bob, club, announcement(AnnouncementStatus.PUBLISHED));
        var unpublished = publications.unpublish(bob, club, a.id(), reason());
        assertThat(unpublished.publishedAt()).isEqualTo(a.publishedAt());
        assertThatThrownBy(() -> publications.publicAnnouncement(a.id())).isInstanceOf(ResourceNotFoundException.class);
        publications.editAnnouncement(bob, club, a.id(), edit("Revised")); when(clock.instant()).thenReturn(NOW.plusSeconds(10));
        var republished = publications.publish(bob, club, a.id()); assertThat(republished.publishedAt()).isEqualTo(TIME.plusSeconds(10));
        assertThat(republished.authorAssignmentId()).isEqualTo(a.authorAssignmentId());
        var removed = publications.removeAnnouncement(alice, club, a.id(), reason());
        assertThat(removed.status()).isEqualTo(AnnouncementStatus.REMOVED); assertThat(removed.removedAt()).isNotNull();
        publications.removeAnnouncement(alice, club, a.id(), reason()); assertThat(auditCount()).isEqualTo(5);
        assertThatThrownBy(() -> publications.editAnnouncement(alice, club, a.id(), edit("No"))).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> publications.publish(alice, club, a.id())).isInstanceOf(ConflictException.class);
        var audit = publications.auditHistory(alice, club, 0, 20).items().getFirst();
        assertThat(audit.reason()).isEqualTo(reason().reason()); assertThat(audit.actorAssignmentId()).isEqualTo(aliceAssignment);
        assertThat(json.readTree(audit.beforeSnapshot()).get("status").asText()).isEqualTo("PUBLISHED");
        assertThat(json.readTree(audit.afterSnapshot()).get("status").asText()).isEqualTo("REMOVED");
    }
    @Test
    void expirationBoundaryHidesContentAndCannotBeUndoneByEditing() {
        var a = publications.createAnnouncement(bob, club, new AnnouncementRequest("Expires", "Soon", AnnouncementPriority.URGENT, AnnouncementStatus.PUBLISHED, TIME.plusSeconds(10)));
        when(clock.instant()).thenReturn(NOW.plusSeconds(9)); assertThat(publications.publicAnnouncement(a.id()).status()).isEqualTo(AnnouncementStatus.PUBLISHED);
        when(clock.instant()).thenReturn(NOW.plusSeconds(10));
        assertThatThrownBy(() -> publications.publicAnnouncement(a.id())).isInstanceOf(ResourceNotFoundException.class);
        assertThat(publications.announcements(null, null, null, null, null, 0, 20).totalElements()).isZero();
        assertThat(publications.managedAnnouncements(alice, club, AnnouncementStatus.EXPIRED, 0, 20).items()).extracting(AnnouncementResponse::id).containsExactly(a.id());
        assertThatThrownBy(() -> publications.editAnnouncement(bob, club, a.id(), edit("Revive"))).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> publications.unpublish(bob, club, a.id(), reason())).isInstanceOf(ConflictException.class);
        publications.removeAnnouncement(alice, club, a.id(), reason());
    }
    @Test
    void draftWithStaleExpiryRequiresEditingBeforePublication() {
        var a = publications.createAnnouncement(bob, club, new AnnouncementRequest("Draft", "Content", AnnouncementPriority.NORMAL, AnnouncementStatus.UNPUBLISHED, TIME.plusSeconds(10)));
        when(clock.instant()).thenReturn(NOW.plusSeconds(11));
        assertThatThrownBy(() -> publications.publish(bob, club, a.id())).isInstanceOf(BadRequestException.class);
        assertThat(publications.managedAnnouncement(bob, club, a.id()).status()).isEqualTo(AnnouncementStatus.UNPUBLISHED);
        publications.editAnnouncement(bob, club, a.id(), edit("Ready")); publications.publish(bob, club, a.id());
    }
    @Test
    void combinedFiltersAndCountsApplyBeforePaginationWithStableOrdering() {
        var a = publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.PUBLISHED));
        var b = publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.PUBLISHED));
        publications.createAnnouncement(alice, club, new AnnouncementRequest("Urgent", "Content", AnnouncementPriority.URGENT, AnnouncementStatus.PUBLISHED, null));
        publications.createAnnouncement(alice, club, announcement(AnnouncementStatus.UNPUBLISHED));
        var filtered = publications.announcements(club, "TECHNOLOGY", AnnouncementPriority.NORMAL, TIME, TIME.plusSeconds(1), 0, 1);
        assertThat(filtered.totalElements()).isEqualTo(2); assertThat(filtered.items().getFirst().id()).isEqualTo(b.id());
        assertThat(publications.announcements(club, "Technology", AnnouncementPriority.NORMAL, TIME, TIME.plusSeconds(1), 1, 1).items().getFirst().id()).isEqualTo(a.id());
        assertThat(publications.announcements(club, null, null, null, TIME, 0, 20).totalElements()).isZero();
        assertThat(publications.announcements(club, "Culture", null, null, null, 0, 20).totalElements()).isZero();
    }
    @Test
    void eventTimingIncludesExactEndAndPastHistoryRetainsContent() {
        var e = publications.createEvent(bob, club, event(10, 20));
        assertThat(e.timing()).isEqualTo(EventTiming.UPCOMING);
        when(clock.instant()).thenReturn(NOW.plusSeconds(10)); assertThat(publications.publicEvent(e.id()).timing()).isEqualTo(EventTiming.ACTIVE);
        when(clock.instant()).thenReturn(NOW.plusSeconds(20));
        assertThat(publications.events(club, null, EventTiming.ACTIVE, false, 0, 20).totalElements()).isEqualTo(1);
        assertThat(publications.events(club, null, EventTiming.PAST, true, 0, 20).totalElements()).isZero();
        when(clock.instant()).thenReturn(NOW.plusSeconds(21));
        assertThat(publications.events(club, null, null, false, 0, 20).totalElements()).isZero();
        var past = publications.events(club, null, EventTiming.PAST, true, 0, 20).items().getFirst();
        assertThat(past.id()).isEqualTo(e.id()); assertThat(past.description()).isEqualTo(e.description());
        assertThat(past.authorAssignmentId()).isEqualTo(bobAssignment); assertThat(past.timing()).isEqualTo(EventTiming.PAST);
        assertThatThrownBy(() -> publications.editEvent(bob, club, e.id(), event(30, 40))).isInstanceOf(ConflictException.class);
    }
    @Test
    void eventPermissionsRemovalAndHistoryAreEnforced() throws Exception {
        var e = publications.createEvent(alice, club, event(10, 20));
        assertThatThrownBy(() -> publications.editEvent(bob, club, e.id(), event(30, 40))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> publications.removeEvent(bob, club, e.id(), reason())).isInstanceOf(ForbiddenException.class);
        var updated = publications.editEvent(alice, club, e.id(), event(15, 25)); assertThat(updated.startsAt()).isEqualTo(TIME.plusSeconds(15));
        when(clock.instant()).thenReturn(NOW.plusSeconds(30));
        mvc.perform(get("/api/v1/clubs/" + club + "/events/history")).andExpect(status().isOk()).andExpect(jsonPath("$.totalElements").value(1));
        publications.removeEvent(alice, club, e.id(), reason()); publications.removeEvent(alice, club, e.id(), reason());
        assertThat(auditCount()).isEqualTo(3); assertThat(publications.events(club, null, EventTiming.PAST, true, 0, 20).totalElements()).isZero();
        mvc.perform(get("/api/v1/events/" + e.id())).andExpect(status().isNotFound());
        assertThat(publications.managedEvent(alice, club, e.id()).status()).isEqualTo(EventStatus.REMOVED);
    }
    @Test
    void eventFeedFilteringCountsOnlyMatchingCurrentEvents() {
        publications.createEvent(alice, club, event(-30, -10));
        var active = publications.createEvent(alice, club, event(-10, 30));
        publications.createEvent(alice, club, event(40, 60));
        var result = publications.events(club, "technology", EventTiming.ACTIVE, false, 0, 1);
        assertThat(result.totalElements()).isEqualTo(1); assertThat(result.items().getFirst().id()).isEqualTo(active.id());
        assertThat(publications.events(club, "technology", null, false, 0, 1).totalElements()).isEqualTo(2);
        assertThat(publications.events(club, null, EventTiming.PAST, true, 0, 1).totalElements()).isEqualTo(1);
    }
    @Test
    void publishingSuspensionPreservesVisibilityButBlocksDraftsAndNewPublications() {
        var a = publications.createAnnouncement(bob, club, announcement(AnnouncementStatus.PUBLISHED));
        var draft = publications.createAnnouncement(bob, club, announcement(AnnouncementStatus.UNPUBLISHED));
        var e = publications.createEvent(bob, club, event(10, 20));
        jdbc.update("update clubs set status='PUBLISHING_SUSPENDED' where club_id=?", club);
        assertThat(publications.publicAnnouncement(a.id()).id()).isEqualTo(a.id()); assertThat(publications.publicEvent(e.id()).id()).isEqualTo(e.id());
        assertThatThrownBy(() -> publications.createAnnouncement(bob, club, announcement(AnnouncementStatus.UNPUBLISHED))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> publications.publish(bob, club, draft.id())).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> publications.createEvent(bob, club, event(10, 20))).isInstanceOf(ForbiddenException.class);
        publications.editAnnouncement(bob, club, a.id(), edit("Correction")); publications.unpublish(bob, club, a.id(), reason());
        publications.removeEvent(bob, club, e.id(), reason());
    }
    @Test
    void removedClubHidesAllPublicContentAndBlocksManagement() {
        var a = publications.createAnnouncement(bob, club, announcement(AnnouncementStatus.PUBLISHED)); var e = publications.createEvent(bob, club, event(10, 20));
        jdbc.update("update clubs set status='REMOVED' where club_id=?", club);
        assertThat(publications.announcements(null, null, null, null, null, 0, 20).totalElements()).isZero();
        assertThat(publications.events(null, null, null, false, 0, 20).totalElements()).isZero();
        assertThatThrownBy(() -> publications.publicAnnouncement(a.id())).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> publications.publicEvent(e.id())).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> publications.managedAnnouncement(bob, club, a.id())).isInstanceOf(ResourceNotFoundException.class);
    }
    @Test
    void confirmationDateAndUrlValidationLeaveNoPartialWrites() {
        var a = publications.createAnnouncement(bob, club, announcement(AnnouncementStatus.PUBLISHED));
        assertThatThrownBy(() -> publications.removeAnnouncement(bob, club, a.id(), new PublicationActionRequest(false, "Reason"))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> publications.unpublish(bob, club, a.id(), new PublicationActionRequest(true, " "))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> publications.createAnnouncement(bob, club, new AnnouncementRequest("Title", "Content", AnnouncementPriority.NORMAL, AnnouncementStatus.EXPIRED, null))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> publications.createAnnouncement(bob, club, new AnnouncementRequest("Title", "Content", AnnouncementPriority.NORMAL, AnnouncementStatus.PUBLISHED, TIME))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> publications.createEvent(bob, club, event(10, 10))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> publications.createEvent(bob, club, new EventRequest("Title", "Description", null, "javascript:alert(1)", null, TIME, TIME.plusHours(1)))).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> publications.createEvent(bob, club, new EventRequest("Title", "Description", null, null, TIME.plusSeconds(1), TIME, TIME.plusHours(1)))).isInstanceOf(BadRequestException.class);
        assertThat(auditCount()).isEqualTo(1);
    }
    @Test
    void mutationAndAuditRollbackTogether() {
        new TransactionTemplate(transactions).executeWithoutResult(tx -> { publications.createEvent(bob, club, event(10, 20)); tx.setRollbackOnly(); });
        assertThat(auditCount()).isZero(); assertThat(publications.events(null, null, null, false, 0, 20).totalElements()).isZero();
    }
    @Test
    void concurrentPublishCreatesOneTransitionAndAudit() throws Exception {
        var a = publications.createAnnouncement(bob, club, announcement(AnnouncementStatus.UNPUBLISHED)); var gate = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var first = pool.submit(() -> { gate.await(); return publications.publish(bob, club, a.id()); });
            var second = pool.submit(() -> { gate.await(); return publications.publish(bob, club, a.id()); });
            gate.countDown(); assertThat(first.get(15, TimeUnit.SECONDS).id()).isEqualTo(second.get(15, TimeUnit.SECONDS).id());
        }
        assertThat(auditCount()).isEqualTo(2);
    }
    @Test
    void restValidatesBodiesFiltersAndDocumentsSuccessResponses() throws Exception {
        mvc.perform(post(manage() + "/announcements").header("Authorization", "Bearer " + bobToken).contentType("application/json").content("{}"))
                .andExpect(status().isBadRequest());
        mvc.perform(post(manage() + "/events").header("Authorization", "Bearer " + bobToken).contentType("application/json").content(json.writeValueAsString(event(10, 20))))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.authorAssignmentId").value(bobAssignment));
        mvc.perform(get("/api/v1/events?size=51")).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/events?timing=PAST")).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/announcements?priority=INVALID")).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/announcements?publishedFrom=2026-10-13T00:00:00&publishedBefore=2026-10-12T00:00:00")).andExpect(status().isBadRequest());
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/clubs/{clubId}/publications/events'].post.responses['201']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/auth/contexts'].get.responses['200']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/clubs/{id}/operators'].get.responses['200']").exists());
    }
}
