package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.BadRequestException;
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
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PasswordResetIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired PasswordResetService service;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired AuthenticationTokenGenerator generator;
    @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager transactions;
    @MockitoBean PasswordResetEmailSender sender;
    @MockitoBean Clock clock;
    private static final Instant NOW = Instant.parse("2026-10-04T00:00:00Z");
    private static final String EMAIL = "reset@iut-dhaka.edu";
    private Long userId;
    private String delivered;

    @BeforeEach
    void setup() {
        clean();
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        doAnswer(call -> { delivered = call.getArgument(1); return null; }).when(sender).send(anyString(), anyString());
        var user = User.register("Reset Member", EMAIL, passwords.encode("password123"), PlatformRole.STUDENT);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
        userId = users.saveAndFlush(user).getUserId();
    }

    @AfterEach
    void clean() {
        jdbc.update("delete from password_reset_tokens");
        jdbc.update("delete from authenticated_sessions");
        jdbc.update("delete from email_verification_tokens");
        jdbc.update("delete from users");
    }

    private String request() { service.requestReset(EMAIL); return delivered; }
    private void invalid(String token) {
        assertThatThrownBy(() -> service.reset(token, "newPassword123"))
                .isInstanceOf(BadRequestException.class).hasMessage("Password reset link is invalid or no longer usable.");
    }

    @Test
    void requestNormalizesEmailAndStoresOnlyOneHourTokenHash() {
        String originalHash = users.findById(userId).orElseThrow().getPasswordHash();
        service.requestReset("  RESET@IUT-DHAKA.EDU  ");
        verify(sender).send(eq(EMAIL), eq(delivered));
        assertThat(delivered).matches("[A-Za-z0-9_-]{43}");
        assertThat(jdbc.queryForObject("select token_hash from password_reset_tokens", String.class))
                .isEqualTo(generator.hash(delivered)).isNotEqualTo(delivered);
        assertThat(jdbc.queryForObject("select expires_at from password_reset_tokens", LocalDateTime.class))
                .isEqualTo(LocalDateTime.ofInstant(NOW.plusSeconds(3600), ZoneOffset.UTC));
        assertThat(users.findById(userId).orElseThrow().getPasswordHash()).isEqualTo(originalHash);
    }

    @Test
    void successfulResetConsumesLinkChangesPasswordAndRevokesEverySession() throws Exception {
        var first = sessions.login(new LoginRequest(EMAIL, "password123"));
        var second = sessions.login(new LoginRequest(EMAIL, "password123"));
        String token = request();
        mvc.perform(post("/api/v1/auth/reset-password").contentType("application/json")
                .content("{\"token\":\"" + token + "\",\"newPassword\":\"newPassword123\"}"))
                .andExpect(status().isNoContent()).andExpect(content().string(""));
        assertThatThrownBy(() -> sessions.login(new LoginRequest(EMAIL, "password123"))).isInstanceOf(InvalidCredentialsException.class);
        for (var session : List.of(first, second)) {
            assertThatThrownBy(() -> sessions.authenticate(session.accessToken())).isInstanceOf(InvalidSessionException.class);
            assertThatThrownBy(() -> sessions.refresh(session.refreshToken())).isInstanceOf(InvalidSessionException.class);
        }
        assertThat(jdbc.queryForObject("select count(*) from authenticated_sessions where revoked_at is null", Integer.class)).isZero();
        assertThat(jdbc.queryForObject("select used_at from password_reset_tokens", LocalDateTime.class)).isNotNull();
        assertThat(jdbc.queryForObject("select revoked_at from password_reset_tokens", LocalDateTime.class)).isNull();
        invalid(token);
        assertThat(sessions.login(new LoginRequest(EMAIL, "newPassword123"))).isNotNull();
    }

    @Test
    void requestResponseIsGenericForUnknownAnonymizedAndDeliveryFailure() throws Exception {
        for (String email : List.of("unknown@iut-dhaka.edu", EMAIL)) {
            if (email.equals(EMAIL)) doThrow(new PasswordResetDeliveryException()).when(sender).send(anyString(), anyString());
            mvc.perform(post("/api/v1/auth/forgot-password").contentType("application/json")
                    .content("{\"email\":\"" + email + "\"}"))
                    .andExpect(status().isAccepted()).andExpect(content().string(""));
        }
        verify(sender, times(1)).send(eq(EMAIL), anyString());
        clearInvocations(sender);
        jdbc.update("update users set anonymized_at = ? where user_id = ?", LocalDateTime.ofInstant(NOW, ZoneOffset.UTC), userId);
        mvc.perform(post("/api/v1/auth/forgot-password").contentType("application/json")
                .content("{\"email\":\"" + EMAIL + "\"}"))
                .andExpect(status().isAccepted()).andExpect(content().string(""));
        verifyNoInteractions(sender);
        assertThat(jdbc.queryForObject("select count(*) from password_reset_tokens", Integer.class)).isZero();
    }

    @Test
    void failedDeliveryRollsBackReplacementAndLeavesOriginalLinkUsable() {
        String first = request();
        doThrow(new PasswordResetDeliveryException()).when(sender).send(anyString(), anyString());
        assertThatThrownBy(() -> service.requestReset(EMAIL)).isInstanceOf(PasswordResetDeliveryException.class);
        assertThat(jdbc.queryForObject("select count(*) from password_reset_tokens", Integer.class)).isEqualTo(1);
        service.reset(first, "newPassword123");
    }

    @Test
    void replacementRejectsOldLinkAndExpiryIsExclusive() {
        String first = request();
        String second = request();
        invalid(first);
        when(clock.instant()).thenReturn(NOW.plusSeconds(3600));
        invalid(second);
        assertThat(passwords.matches("password123", users.findById(userId).orElseThrow().getPasswordHash())).isTrue();
    }

    @Test
    void linkWorksImmediatelyBeforeExpiry() {
        String token = request();
        when(clock.instant()).thenReturn(NOW.plusSeconds(3599));
        service.reset(token, "newPassword123");
    }

    @Test
    void pendingAndSuspendedAccountsKeepTheirStatusAndCannotLogin() {
        for (String status : List.of("PENDING_VERIFICATION", "SUSPENDED")) {
            jdbc.update("update users set account_status = ? where user_id = ?", status, userId);
            service.reset(request(), "newPassword123");
            assertThat(jdbc.queryForObject("select account_status from users where user_id = ?", String.class, userId)).isEqualTo(status);
            assertThat(passwords.matches("newPassword123", users.findById(userId).orElseThrow().getPasswordHash())).isTrue();
            assertThatThrownBy(() -> sessions.login(new LoginRequest(EMAIL, "newPassword123"))).isInstanceOf(InvalidCredentialsException.class);
        }
    }

    @Test
    void anonymizationAfterIssuanceInvalidatesLink() {
        String token = request();
        jdbc.update("update users set anonymized_at = ? where user_id = ?", LocalDateTime.ofInstant(NOW, ZoneOffset.UTC), userId);
        invalid(token);
    }

    @Test
    void invalidRequestsUseApiErrorAndDoNotConsumeToken() throws Exception {
        String token = request();
        for (String path : List.of("forgot-password", "reset-password")) {
            mvc.perform(post("/api/v1/auth/" + path).contentType("application/json").content("{}"))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
            mvc.perform(post("/api/v1/auth/" + path).contentType("application/json").content("{"))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("MALFORMED_REQUEST"));
        }
        for (String password : List.of("short", "x".repeat(73))) {
            mvc.perform(post("/api/v1/auth/reset-password").contentType("application/json")
                    .content("{\"token\":\"" + token + "\",\"newPassword\":\"" + password + "\"}"))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        }
        mvc.perform(post("/api/v1/auth/reset-password").contentType("application/json")
                .content("{\"token\":\"" + token + "\",\"newPassword\":\"" + "é".repeat(40) + "\"}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("INVALID_PASSWORD"));
        mvc.perform(post("/api/v1/auth/reset-password").contentType("application/json")
                .content("{\"token\":\"invalid\",\"newPassword\":\"newPassword123\"}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("INVALID_PASSWORD_RESET_TOKEN"));
        invalid(generator.generate());
        service.reset(token, "newPassword123");
    }

    @Test
    void rollbackRestoresPasswordTokenAndSessionsTogether() {
        var session = sessions.login(new LoginRequest(EMAIL, "password123"));
        String token = request();
        new TransactionTemplate(transactions).executeWithoutResult(status -> {
            service.reset(token, "newPassword123");
            status.setRollbackOnly();
        });
        assertThat(passwords.matches("password123", users.findById(userId).orElseThrow().getPasswordHash())).isTrue();
        assertThat(sessions.authenticate(session.accessToken()).userId()).isEqualTo(userId);
        service.reset(token, "newPassword123");
    }

    @Test
    void concurrentConsumersHaveOnlyOneWinner() throws Exception {
        String token = request();
        var start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            Callable<Boolean> reset = () -> {
                start.await();
                try { service.reset(token, "newPassword123"); return true; }
                catch (BadRequestException e) { return false; }
            };
            var a = executor.submit(reset);
            var b = executor.submit(reset);
            start.countDown();
            assertThat(List.of(a.get(10, TimeUnit.SECONDS), b.get(10, TimeUnit.SECONDS)))
                    .containsExactlyInAnyOrder(true, false);
        }
    }

    @Test
    void concurrentRefreshCannotLeaveUsableSessionAfterReset() throws Exception {
        var original = sessions.login(new LoginRequest(EMAIL, "password123"));
        String token = request();
        var start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(2)) {
            var refresh = executor.submit(() -> {
                start.await();
                try { return sessions.refresh(original.refreshToken()); }
                catch (InvalidSessionException e) { return null; }
            });
            var reset = executor.submit(() -> { start.await(); service.reset(token, "newPassword123"); return true; });
            start.countDown();
            var replacement = refresh.get(10, TimeUnit.SECONDS);
            assertThat(reset.get(10, TimeUnit.SECONDS)).isTrue();
            if (replacement != null) {
                assertThatThrownBy(() -> sessions.authenticate(replacement.accessToken())).isInstanceOf(InvalidSessionException.class);
                assertThatThrownBy(() -> sessions.refresh(replacement.refreshToken())).isInstanceOf(InvalidSessionException.class);
            }
        }
        assertThatThrownBy(() -> sessions.authenticate(original.accessToken())).isInstanceOf(InvalidSessionException.class);
    }
}
