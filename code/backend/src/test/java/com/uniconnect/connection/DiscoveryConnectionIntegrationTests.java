package com.uniconnect.connection;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.*;
import com.uniconnect.connection.domain.ConnectionStatus;
import com.uniconnect.connection.dto.*;
import com.uniconnect.connection.service.*;
import com.uniconnect.notification.service.NotificationService;
import com.uniconnect.profile.domain.*;
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
class DiscoveryConnectionIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired SessionService sessions;
    @Autowired PersonalProfileService profiles;
    @Autowired ProfilePrivacyService privacy;
    @Autowired MemberProfileService members;
    @Autowired AcademicCatalogService catalog;
    @Autowired ConnectionService connections;
    @Autowired ConnectionListService lists;
    @Autowired NotificationService notifications;
    @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager transactions;
    @MockitoBean Clock clock;
    private SessionPrincipal admin, alice, bob, carol;
    private String aliceToken, bobToken, carolToken;
    private Long degreeId, departmentId, programmeId;
    private static final Instant NOW = Instant.parse("2026-10-08T00:00:00Z");

    @BeforeEach
    void setup() {
        clean();
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        admin = sessions.authenticate(account("Admin", PlatformRole.SYSTEM_ADMIN));
        aliceToken = account("Alice", PlatformRole.STUDENT);
        bobToken = account("Bob", PlatformRole.STUDENT);
        carolToken = account("Carol", PlatformRole.ALUMNI);
        alice = sessions.authenticate(aliceToken);
        bob = sessions.authenticate(bobToken);
        carol = sessions.authenticate(carolToken);
        departmentId = catalog.createDepartment(admin, new DepartmentRequest("Computing", "CSE")).id();
        programmeId = catalog.createProgramme(admin, new ProgrammeRequest("Software Engineering", "SWE", departmentId)).id();
        degreeId = catalog.createDegree(admin, new DegreeRequest(programmeId, DegreeLevel.BACHELOR, 4, 1, 4, true)).id();
        profiles.saveStudent(alice, student("Alice", "A-1"));
        profiles.saveStudent(bob, student("Bob", "B-1"));
        profiles.saveAlumni(carol, new AlumniProfileRequest("Carol", degreeId, "Alumni bio", null,
                List.of("Java"), List.of("Robotics"), 2024, "Example Company", "Engineer", "Software", "Private history", null));
    }
    @AfterEach
    void clean() {
        for (String table : List.of("notifications", "connections", "profile_skills", "profile_interests", "personal_profiles", "skills", "interests",
                "programme_degrees", "programmes", "departments", "password_reset_tokens", "email_verification_tokens", "authenticated_sessions", "users"))
            jdbc.update("delete from " + table);
    }
    private String account(String name, PlatformRole role) {
        User user = User.register(name, name.toLowerCase(Locale.ROOT) + "@iut-dhaka.edu", passwords.encode("password123"), role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
        users.saveAndFlush(user);
        return sessions.login(new LoginRequest(user.getEmail(), "password123")).accessToken();
    }
    private StudentProfileRequest student(String name, String number) {
        return new StudentProfileRequest(name, degreeId, "Private bio", null, List.of("Java", "SQL"),
                List.of("Robotics"), number, 2, 2029, true, false);
    }
    private ConnectionResponse send() { return connections.send(alice, new ConnectionRequest(bob.userId(), "Hello")); }
    private MemberSearch search(List<String> skills, String company, Integer year, Boolean available) {
        return new MemberSearch(null, null, null, null, skills, year, available, null, company, null, null, "NAME_ASC", 0, 20);
    }

    @Test
    void defaultPrivacyHidesDetailsAndSensitiveFieldsHaveNoPublicRepresentation() throws Exception {
        assertThat(privacy.get(bob).detailsVisibility()).isEqualTo(ProfileVisibility.CONNECTIONS_ONLY);
        mvc.perform(get("/api/v1/members/" + bob.userId()).header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.fullName").value("Bob"))
                .andExpect(jsonPath("$.programme.code").value("SWE"))
                .andExpect(jsonPath("$.detailsVisible").value(false))
                .andExpect(jsonPath("$.details").doesNotExist())
                .andExpect(jsonPath("$.email").doesNotExist()).andExpect(jsonPath("$.studentNumber").doesNotExist());
        assertThat(members.view(bob, bob.userId()).details().student().yearOfStudy()).isEqualTo(2);
        assertThat(members.view(admin, bob.userId()).detailsVisible()).isFalse();
    }
    @Test
    void privateFilterCountsDoNotRevealHiddenSkillsYearsAvailabilityOrCompany() {
        assertThat(members.search(alice, search(List.of(), null, null, null)).totalElements()).isEqualTo(2);
        assertThat(members.search(alice, search(List.of("java"), null, null, null)).totalElements()).isZero();
        assertThat(members.search(alice, search(List.of(), null, 2, null)).totalElements()).isZero();
        assertThat(members.search(alice, search(List.of(), null, null, true)).totalElements()).isZero();
        assertThat(members.search(alice, search(List.of(), "example", null, null)).totalElements()).isZero();
        privacy.update(carol, new PrivacyRequest(ProfileVisibility.ALL_MEMBERS));
        assertThat(members.search(alice, search(List.of(" JAVA "), "EXAMPLE", null, null)).items())
                .extracting(MemberProfileResponse::userId).containsExactly(carol.userId());
    }
    @Test
    void acceptedConnectionUnlocksDetailsAndRemovalImmediatelyHidesThem() throws Exception {
        var request = send();
        assertThat(members.view(alice, bob.userId()).detailsVisible()).isFalse();
        connections.accept(bob, request.id());
        assertThat(members.view(alice, bob.userId()).details().sharedSkills()).containsExactly("java", "sql");
        assertThat(members.search(alice, search(List.of("java", "sql"), null, 2, true)).items()).hasSize(1);
        mvc.perform(get("/api/v1/members/" + bob.userId()).header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isOk()).andExpect(jsonPath("$.details.student.studentNumber").doesNotExist())
                .andExpect(jsonPath("$.email").doesNotExist());
        connections.remove(alice, request.id());
        assertThat(members.view(alice, bob.userId()).detailsVisible()).isFalse();
        assertThat(members.search(alice, search(List.of("java"), null, null, null)).totalElements()).isZero();
    }
    @Test
    void privacyChangesAreOwnerOnlyAndSurviveProfileReplacement() throws Exception {
        mvc.perform(patch("/api/v1/profile/me/privacy").header("Authorization", "Bearer " + bobToken)
                .contentType("application/json").content("{\"detailsVisibility\":\"ALL_MEMBERS\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.detailsVisibility").value("ALL_MEMBERS"));
        profiles.saveStudent(bob, student("Bob Updated", "B-1"));
        assertThat(privacy.get(bob).detailsVisibility()).isEqualTo(ProfileVisibility.ALL_MEMBERS);
        assertThat(privacy.get(alice).detailsVisibility()).isEqualTo(ProfileVisibility.CONNECTIONS_ONLY);
        assertThat(members.view(alice, bob.userId()).detailsVisible()).isTrue();
        privacy.update(bob, new PrivacyRequest(ProfileVisibility.CONNECTIONS_ONLY));
        assertThat(members.view(alice, bob.userId()).detailsVisible()).isFalse();
    }
    @Test
    void selfRequestsAndDuplicateDirectionsAreRejected() {
        assertThatThrownBy(() -> connections.send(alice, new ConnectionRequest(alice.userId(), null))).isInstanceOf(BadRequestException.class);
        send();
        assertThatThrownBy(this::send).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> connections.send(bob, new ConnectionRequest(alice.userId(), null))).isInstanceOf(ConflictException.class);
        assertThat(jdbc.queryForObject("select count(*) from connections", Integer.class)).isEqualTo(1);
        assertThat(jdbc.queryForObject("select count(*) from notifications", Integer.class)).isEqualTo(1);
    }
    @Test
    void onlyReceiverAcceptsOrRejectsAndOnlySenderCancels() {
        long id = send().id();
        assertThatThrownBy(() -> connections.accept(alice, id)).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> connections.reject(alice, id)).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> connections.cancel(bob, id)).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> connections.accept(carol, id)).isInstanceOf(ResourceNotFoundException.class);
        connections.cancel(alice, id);
        assertThat(connections.get(bob, id).status()).isEqualTo(ConnectionStatus.CANCELLED);
        assertThatThrownBy(() -> connections.accept(bob, id)).isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> connections.remove(bob, id)).isInstanceOf(ConflictException.class);
    }
    @Test
    void closedHistoryIsRetainedAndNewRequestsHaveNewIds() {
        var first = send();
        connections.reject(bob, first.id());
        var second = connections.send(bob, new ConnectionRequest(alice.userId(), null));
        connections.accept(alice, second.id());
        connections.remove(bob, second.id());
        var third = send();
        assertThat(third.id()).isNotEqualTo(first.id()).isNotEqualTo(second.id());
        assertThat(connections.get(alice, first.id()).status()).isEqualTo(ConnectionStatus.REJECTED);
        assertThat(connections.get(alice, second.id()).status()).isEqualTo(ConnectionStatus.REMOVED);
        assertThat(jdbc.queryForObject("select count(*) from connections", Integer.class)).isEqualTo(3);
    }
    @Test
    void notificationsAreExactlyOnceAndOnlyRecipientCanRead() throws Exception {
        var request = send();
        assertThat(notifications.list(alice, 0, 20).totalElements()).isZero();
        var notice = notifications.list(bob, 0, 20).items().getFirst();
        assertThat(notice.referenceId()).isEqualTo(request.id());
        mvc.perform(patch("/api/v1/notifications/" + notice.id() + "/read").header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isNotFound());
        assertThat(notifications.read(bob, notice.id()).readAt()).isNotNull();
        connections.accept(bob, request.id());
        assertThatThrownBy(() -> connections.accept(bob, request.id())).isInstanceOf(ConflictException.class);
        assertThat(notifications.list(alice, 0, 20).totalElements()).isEqualTo(1);
        assertThat(notifications.list(bob, 0, 20).totalElements()).isEqualTo(1);
        assertThatThrownBy(() -> connections.get(carol, request.id())).isInstanceOf(ResourceNotFoundException.class);
    }
    @Test
    void rollbackRemovesBothConnectionAndNotification() {
        new TransactionTemplate(transactions).executeWithoutResult(status -> { send(); status.setRollbackOnly(); });
        assertThat(jdbc.queryForObject("select count(*) from connections", Integer.class)).isZero();
        assertThat(jdbc.queryForObject("select count(*) from notifications", Integer.class)).isZero();
    }
    @Test
    void unavailableUsersAreHiddenAndCannotReceiveNewRequests() {
        jdbc.update("update users set account_status = 'SUSPENDED' where user_id = ?", bob.userId());
        jdbc.update("update users set anonymized_at = ? where user_id = ?", LocalDateTime.ofInstant(NOW, ZoneOffset.UTC), carol.userId());
        assertThat(members.search(alice, search(List.of(), null, null, null)).totalElements()).isZero();
        assertThatThrownBy(() -> members.view(alice, bob.userId())).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(this::send).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> members.view(alice, carol.userId())).isInstanceOf(ResourceNotFoundException.class);
    }
    @Test
    void suspendedPeerCannotBeAcceptedButRequestCanBeRejected() {
        long id = send().id();
        jdbc.update("update users set account_status = 'SUSPENDED' where user_id = ?", alice.userId());
        assertThatThrownBy(() -> connections.accept(bob, id)).isInstanceOf(ResourceNotFoundException.class);
        assertThat(connections.reject(bob, id).status()).isEqualTo(ConnectionStatus.REJECTED);
    }
    @Test
    void revokedAndExpiredSessionsCannotCallServices() {
        sessions.logout(alice);
        assertThatThrownBy(this::send).isInstanceOf(InvalidSessionException.class);
        assertThatThrownBy(() -> privacy.update(alice, new PrivacyRequest(ProfileVisibility.ALL_MEMBERS))).isInstanceOf(InvalidSessionException.class);
        assertThatThrownBy(() -> members.search(alice, search(List.of(), null, null, null))).isInstanceOf(InvalidSessionException.class);
        when(clock.instant()).thenReturn(NOW.plusSeconds(3600));
        assertThatThrownBy(() -> notifications.list(bob, 0, 20)).isInstanceOf(InvalidSessionException.class);
    }
    @Test
    void listsSupportIncomingOutgoingSearchSortingAndDerivedCount() throws Exception {
        var one = send();
        var two = connections.send(carol, new ConnectionRequest(alice.userId(), null));
        assertThat(lists.list(alice, ConnectionStatus.PENDING, "INCOMING", null, "NEWEST", 0, 20).items())
                .extracting(ConnectionListItem::otherUserId).containsExactly(carol.userId());
        connections.accept(bob, one.id());
        connections.accept(alice, two.id());
        var page = lists.list(alice, ConnectionStatus.ACCEPTED, "ALL", null, "NAME", 0, 1);
        assertThat(page.totalElements()).isEqualTo(2);
        assertThat(page.items().getFirst().fullName()).isEqualTo("Bob");
        assertThat(lists.list(alice, ConnectionStatus.ACCEPTED, "ALL", "CAR", "NAME", 0, 20).totalElements()).isEqualTo(1);
        mvc.perform(get("/api/v1/connections").header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isOk()).andExpect(jsonPath("$.totalElements").value(2));
        connections.remove(carol, two.id());
        assertThat(lists.list(alice, ConnectionStatus.ACCEPTED, "ALL", null, "NAME", 0, 20).totalElements()).isEqualTo(1);
    }
    @Test
    void basicFiltersArePublicAndPaginationIsStable() {
        var criteria = new MemberSearch("b", PlatformRole.STUDENT, departmentId, programmeId, List.of(), null,
                null, null, null, null, null, "NAME_ASC", 0, 1);
        assertThat(members.search(alice, criteria).items()).extracting(MemberProfileResponse::userId).containsExactly(bob.userId());
        var page = members.search(alice, new MemberSearch(null, null, null, null, List.of(), null, null, null,
                null, null, null, "NAME_DESC", 1, 1));
        assertThat(page.totalElements()).isEqualTo(2);
        assertThat(page.items()).extracting(MemberProfileResponse::userId).containsExactly(bob.userId());
    }
    @Test
    void httpValidationUsesApiErrorsAndAnonymousRequestsAreRejected() throws Exception {
        mvc.perform(get("/api/v1/members")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/members").param("size", "51").header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("INVALID_PAGE"));
        mvc.perform(get("/api/v1/members").param("role", "INVALID").header("Authorization", "Bearer " + aliceToken))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("INVALID_PARAMETER"));
        mvc.perform(post("/api/v1/connections").header("Authorization", "Bearer " + aliceToken)
                .contentType("application/json").content("{}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        mvc.perform(patch("/api/v1/profile/me/privacy").header("Authorization", "Bearer " + aliceToken)
                .contentType("application/json").content("{}"))
                .andExpect(status().isBadRequest());
        assertThatThrownBy(() -> connections.send(alice, new ConnectionRequest(bob.userId(), "x".repeat(1001)))).isInstanceOf(BadRequestException.class);
    }
    @Test
    void simultaneousOppositeRequestsProduceOneOpenRecordAndOneNotification() throws Exception {
        var start = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var first = pool.submit(() -> concurrentSend(start, alice, bob));
            var second = pool.submit(() -> concurrentSend(start, bob, alice));
            start.countDown();
            assertThat(List.of(first.get(15, TimeUnit.SECONDS), second.get(15, TimeUnit.SECONDS))).containsExactlyInAnyOrder("created", "conflict");
        }
        assertThat(jdbc.queryForObject("select count(*) from connections where open_low is not null", Integer.class)).isEqualTo(1);
        assertThat(jdbc.queryForObject("select count(*) from notifications", Integer.class)).isEqualTo(1);
    }
    private String concurrentSend(CountDownLatch start, SessionPrincipal sender, SessionPrincipal receiver) throws Exception {
        start.await();
        try { connections.send(sender, new ConnectionRequest(receiver.userId(), null)); return "created"; }
        catch (ConflictException e) { return "conflict"; }
    }
    @Test
    void simultaneousAcceptAndCancelHaveOneWinner() throws Exception {
        long id = send().id();
        var start = new CountDownLatch(1);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var first = pool.submit(() -> transition(start, () -> connections.accept(bob, id)));
            var second = pool.submit(() -> transition(start, () -> connections.cancel(alice, id)));
            start.countDown();
            assertThat(List.of(first.get(15, TimeUnit.SECONDS), second.get(15, TimeUnit.SECONDS))).containsExactlyInAnyOrder("updated", "conflict");
        }
        var status = connections.get(alice, id).status();
        assertThat(status).isIn(ConnectionStatus.ACCEPTED, ConnectionStatus.CANCELLED);
        assertThat(jdbc.queryForObject("select count(*) from notifications", Integer.class)).isEqualTo(status == ConnectionStatus.ACCEPTED ? 2 : 1);
    }
    private String transition(CountDownLatch start, Runnable action) throws Exception {
        start.await();
        try { action.run(); return "updated"; } catch (ConflictException e) { return "conflict"; }
    }
    @Test
    void databaseConstraintRejectsReverseDuplicateEvenOutsideService() {
        send();
        assertThatThrownBy(() -> jdbc.update("insert into connections (requester_id, receiver_id, user_low, user_high, open_low, open_high, status, requested_at) values (?, ?, ?, ?, ?, ?, 'PENDING', ?)",
                bob.userId(), alice.userId(), Math.min(alice.userId(), bob.userId()), Math.max(alice.userId(), bob.userId()),
                Math.min(alice.userId(), bob.userId()), Math.max(alice.userId(), bob.userId()), LocalDateTime.ofInstant(NOW, ZoneOffset.UTC)))
                .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class);
    }
    @Test
    void openApiIncludesSuccessSchemasAndSessionSecurity() throws Exception {
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/members'].get.responses['200'].content").exists())
                .andExpect(jsonPath("$.paths['/api/v1/connections'].post.responses['201'].content").exists())
                .andExpect(jsonPath("$.paths['/api/v1/profile/me/privacy'].patch.security[0].sessionBearer").exists())
                .andExpect(jsonPath("$.paths['/api/v1/notifications'].get.responses['200']").exists());
    }
}
