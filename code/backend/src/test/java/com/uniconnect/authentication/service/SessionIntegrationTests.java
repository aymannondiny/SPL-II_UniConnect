package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.*;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.security.PlatformRole;
import java.time.*;
import java.util.List;
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
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SessionIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired SessionService service;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired SessionTokenGenerator tokens;
    @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager transactions;
    @MockitoBean Clock clock;
    private static final Instant NOW = Instant.parse("2026-10-04T00:00:00Z");
    private Long userId;

    @BeforeEach
    void setup() {
        clean();
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        var user = User.register("Session Member", "session@iut-dhaka.edu",
                passwords.encode("password123"), PlatformRole.STUDENT);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
        userId = users.saveAndFlush(user).getUserId();
    }

    @AfterEach
    void clean() {
        jdbc.update("delete from authenticated_sessions");
        jdbc.update("delete from email_verification_tokens");
        jdbc.update("delete from users");
    }

    private SessionResponse login() {
        return service.login(new LoginRequest("SESSION@IUT-DHAKA.EDU", "password123"));
    }

    private void denied(String access) throws Exception {
        mvc.perform(get("/api/v1/auth/me").header("Authorization", "Bearer " + access))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTHENTICATION_REQUIRED"));
    }

    @Test
    void loginStoresOnlyHashesAndReturnsSafeCurrentUser() throws Exception {
        var response = login();
        assertThat(response.accessToken()).matches("[A-Za-z0-9_-]{43}");
        assertThat(response.refreshToken()).isNotEqualTo(response.accessToken());
        assertThat(response.accessExpiresAt()).isEqualTo(NOW.plusSeconds(900));
        assertThat(response.expiresAt()).isEqualTo(NOW.plus(Duration.ofDays(7)));
        var stored = jdbc.queryForMap("select access_token_hash, refresh_token_hash from authenticated_sessions");
        assertThat(stored.get("access_token_hash")).isEqualTo(tokens.hash(response.accessToken()));
        assertThat(stored.get("refresh_token_hash")).isEqualTo(tokens.hash(response.refreshToken()));
        mvc.perform(get("/api/v1/auth/me").header("Authorization", "Bearer " + response.accessToken()))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.userId").value(userId))
                .andExpect(jsonPath("$.accountStatus").value("ACTIVE"))
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
        denied(response.refreshToken());
        assertThatThrownBy(() -> service.refresh(response.accessToken())).isInstanceOf(InvalidSessionException.class);
    }

    @Test
    void loginHttpContractDoesNotCreateHttpSession() throws Exception {
        var result = mvc.perform(post("/api/v1/auth/login").contentType("application/json").content("""
                {"email":"SESSION@IUT-DHAKA.EDU","password":"password123"}
                """))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(header().doesNotExist("Set-Cookie"))
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.accessToken").isString()).andReturn();
        assertThat(result.getRequest().getSession(false)).isNull();
        mvc.perform(get("/api/v1/auth/me")).andExpect(status().isUnauthorized());
    }

    @Test
    void invalidCredentialsAndIneligibleAccountsHaveSameError() throws Exception {
        for (String email : List.of("unknown@iut-dhaka.edu", "session@iut-dhaka.edu")) {
            mvc.perform(post("/api/v1/auth/login").contentType("application/json")
                    .content("{\"email\":\"" + email + "\",\"password\":\"wrong-password\"}"))
                    .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
        }
        for (String status : List.of("PENDING_VERIFICATION", "SUSPENDED")) {
            jdbc.update("update users set account_status = ? where user_id = ?", status, userId);
            assertThatThrownBy(this::login).isInstanceOf(InvalidCredentialsException.class);
        }
        jdbc.update("update users set account_status = 'ACTIVE', anonymized_at = ? where user_id = ?",
                LocalDateTime.ofInstant(NOW, ZoneOffset.UTC), userId);
        assertThatThrownBy(this::login).isInstanceOf(InvalidCredentialsException.class);
        assertThat(jdbc.queryForObject("select count(*) from authenticated_sessions", Integer.class)).isZero();
    }

    @Test
    void accessExpiresAtBoundaryButRefreshWorksUntilAbsoluteExpiry() throws Exception {
        var first = login();
        when(clock.instant()).thenReturn(NOW.plusSeconds(900));
        denied(first.accessToken());
        var next = service.refresh(first.refreshToken());
        assertThat(next.expiresAt()).isEqualTo(first.expiresAt());
        when(clock.instant()).thenReturn(NOW.plus(Duration.ofDays(7)).minusSeconds(1));
        var last = service.refresh(next.refreshToken());
        assertThat(last.accessExpiresAt()).isEqualTo(first.expiresAt());
        when(clock.instant()).thenReturn(first.expiresAt());
        denied(last.accessToken());
        assertThatThrownBy(() -> service.refresh(last.refreshToken())).isInstanceOf(InvalidSessionException.class);
    }

    @Test
    void refreshRotatesBothTokensAndOldTokensCannotBeReused() throws Exception {
        var first = login();
        mvc.perform(post("/api/v1/auth/refresh").contentType("application/json")
                .content("{\"refreshToken\":\"" + first.refreshToken() + "\"}"))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.sessionId").value(first.sessionId().toString()));
        denied(first.accessToken());
        assertThatThrownBy(() -> service.refresh(first.refreshToken())).isInstanceOf(InvalidSessionException.class);
    }

    @Test
    void logoutRevokesOnlyCurrentSessionAndBothItsTokens() throws Exception {
        var first = login();
        var second = login();
        mvc.perform(post("/api/v1/auth/logout").header("Authorization", "Bearer " + first.accessToken()))
                .andExpect(status().isNoContent());
        denied(first.accessToken());
        assertThatThrownBy(() -> service.refresh(first.refreshToken())).isInstanceOf(InvalidSessionException.class);
        assertThat(service.authenticate(second.accessToken()).userId()).isEqualTo(userId);
    }

    @Test
    void everyRequestRechecksStatusAndPlatformRole() throws Exception {
        var session = login();
        mvc.perform(get("/api/v1/admin/test").header("Authorization", "Bearer " + session.accessToken()))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ACCESS_DENIED"));
        jdbc.update("update users set platform_role = 'SYSTEM_ADMIN' where user_id = ?", userId);
        mvc.perform(get("/api/v1/admin/test").header("Authorization", "Bearer " + session.accessToken()))
                .andExpect(status().isNotFound());
        jdbc.update("update users set account_status = 'SUSPENDED' where user_id = ?", userId);
        denied(session.accessToken());
        assertThatThrownBy(() -> service.refresh(session.refreshToken())).isInstanceOf(InvalidSessionException.class);
        jdbc.update("update users set account_status = 'ACTIVE', anonymized_at = ? where user_id = ?",
                LocalDateTime.ofInstant(NOW, ZoneOffset.UTC), userId);
        denied(session.accessToken());
    }

    @Test
    void accountRevocationJoinsTransactionAndReactivationDoesNotRestoreSessions() throws Exception {
        var session = login();
        var transaction = new TransactionTemplate(transactions);
        transaction.executeWithoutResult(status -> {
            service.revokeAllForAccount(userId);
            status.setRollbackOnly();
        });
        assertThat(service.authenticate(session.accessToken()).userId()).isEqualTo(userId);
        transaction.executeWithoutResult(status -> {
            service.revokeAllForAccount(userId);
            jdbc.update("update users set account_status = 'SUSPENDED' where user_id = ?", userId);
        });
        jdbc.update("update users set account_status = 'ACTIVE' where user_id = ?", userId);
        denied(session.accessToken());
        assertThatThrownBy(() -> service.refresh(session.refreshToken())).isInstanceOf(InvalidSessionException.class);
    }

    @Test
    void concurrentRefreshHasOnlyOneWinner() throws Exception {
        var first = login();
        var start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            Callable<Boolean> refresh = () -> {
                start.await();
                try { service.refresh(first.refreshToken()); return true; }
                catch (InvalidSessionException e) { return false; }
            };
            var a = executor.submit(refresh);
            var b = executor.submit(refresh);
            start.countDown();
            assertThat(List.of(a.get(10, TimeUnit.SECONDS), b.get(10, TimeUnit.SECONDS)))
                    .containsExactlyInAnyOrder(true, false);
        }
    }

    @Test
    void malformedInputsAndMissingOrUnsupportedCredentialsUseApiError() throws Exception {
        mvc.perform(post("/api/v1/auth/login").contentType("application/json").content("{}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        mvc.perform(post("/api/v1/auth/refresh").contentType("application/json").content("{"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("MALFORMED_REQUEST"));
        mvc.perform(post("/api/v1/auth/refresh").contentType("application/json")
                .content("{\"refreshToken\":\"invalid\"}"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("INVALID_SESSION"));
        denied("invalid");
        mvc.perform(get("/api/v1/auth/me").header("Authorization", "Basic abc"))
                .andExpect(status().isUnauthorized());
        var session = login();
        mvc.perform(get("/api/v1/auth/me").header("Authorization", "Bearer " + session.accessToken(), "Bearer other"))
                .andExpect(status().isUnauthorized());
    }
    @Test
    void concurrentLogoutAndRefreshCannotLeaveUsableReplacement() throws Exception {
        var first = login();
        var principal = service.authenticate(first.accessToken());
        var start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            var refresh = executor.submit(() -> {
                start.await();
                try { return service.refresh(first.refreshToken()); }
                catch (InvalidSessionException e) { return null; }
            });
            var logout = executor.submit(() -> {
                start.await();
                service.logout(principal);
                return true;
            });
            start.countDown();
            var replacement = refresh.get(10, TimeUnit.SECONDS);
            assertThat(logout.get(10, TimeUnit.SECONDS)).isTrue();
            if (replacement != null) {
                assertThatThrownBy(() -> service.authenticate(replacement.accessToken()))
                        .isInstanceOf(InvalidSessionException.class);
                assertThatThrownBy(() -> service.refresh(replacement.refreshToken()))
                        .isInstanceOf(InvalidSessionException.class);
            }
        }
        denied(first.accessToken());
    }

    @Test
    void oversizedUtf8PasswordFailsWithoutEncoderException() throws Exception {
        mvc.perform(post("/api/v1/auth/login").contentType("application/json")
                .content("{\"email\":\"session@iut-dhaka.edu\",\"password\":\"" + "é".repeat(40) + "\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
    }
}
