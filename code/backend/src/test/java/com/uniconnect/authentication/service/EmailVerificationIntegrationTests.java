package com.uniconnect.authentication.service;

import com.uniconnect.authentication.repository.EmailVerificationTokenRepository;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.security.AccountStatus;
import java.time.*;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class EmailVerificationIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired UserRepository users;
    @Autowired EmailVerificationTokenRepository tokens;
    @Autowired EmailVerificationService service;
    @Autowired VerificationTokenGenerator generator;
    @MockitoBean VerificationEmailSender sender;
    @MockitoBean Clock clock;
    private final AtomicReference<String> delivered = new AtomicReference<>();
    private static final Instant NOW = Instant.parse("2026-09-28T00:00:00Z");

    @BeforeEach
    void setup() {
        jdbc.update("delete from email_verification_tokens");
        jdbc.update("delete from users");
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        doAnswer(call -> { delivered.set(call.getArgument(1)); return null; })
                .when(sender).send(anyString(), anyString());
    }

    @org.junit.jupiter.api.AfterEach
    void cleanup() {
        jdbc.update("delete from email_verification_tokens");
        jdbc.update("delete from users");
    }

    private String register() throws Exception {
        mvc.perform(post("/api/v1/auth/register").contentType("application/json").content("""
                {"fullName":"Test Member","email":"verify@iut-dhaka.edu",
                 "password":"password123","platformRole":"STUDENT"}
                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accountStatus").value("PENDING_VERIFICATION"))
                .andExpect(jsonPath("$.token").doesNotExist());
        return delivered.get();
    }

    private org.springframework.test.web.servlet.ResultActions verifyToken(String token) throws Exception {
        return mvc.perform(post("/api/v1/auth/verify-email").contentType("application/json")
                .content("{\"token\":\"" + token + "\"}"));
    }

    private void resend(String email) throws Exception {
        mvc.perform(post("/api/v1/auth/resend-verification").contentType("application/json")
                .content("{\"email\":\"" + email + "\"}"))
                .andExpect(status().isAccepted()).andExpect(content().string(""));
    }

    @Test
    void registrationStoresOnlyHashAndVerificationActivatesExactlyOnce() throws Exception {
        String raw = register();
        assertThat(raw).matches("[A-Za-z0-9_-]{43}");
        var token = tokens.findAll().getFirst();
        assertThat(token.getTokenHash()).isEqualTo(generator.hash(raw)).isNotEqualTo(raw);
        assertThat(token.getExpiresAt()).isEqualTo(LocalDateTime.ofInstant(NOW.plus(Duration.ofHours(24)), ZoneOffset.UTC));
        verifyToken(raw).andExpect(status().isNoContent()).andExpect(content().string(""));
        assertThat(users.findByEmail("verify@iut-dhaka.edu").orElseThrow().getAccountStatus())
                .isEqualTo(AccountStatus.ACTIVE);
        verifyToken(raw).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_VERIFICATION_TOKEN"));
    }

    @Test
    void expiryBoundaryIsRejectedWithoutActivatingUser() throws Exception {
        String raw = register();
        when(clock.instant()).thenReturn(NOW.plus(Duration.ofHours(24)));
        verifyToken(raw).andExpect(status().isBadRequest());
        assertThat(users.findByEmail("verify@iut-dhaka.edu").orElseThrow().getAccountStatus())
                .isEqualTo(AccountStatus.PENDING_VERIFICATION);
    }

    @Test
    void replacementRevokesPreviousLinkAndResetsExpiry() throws Exception {
        String old = register();
        when(clock.instant()).thenReturn(NOW.plus(Duration.ofHours(25)));
        resend("VERIFY@IUT-DHAKA.EDU");
        String replacement = delivered.get();
        assertThat(replacement).isNotEqualTo(old);
        verifyToken(old).andExpect(status().isBadRequest());
        verifyToken(replacement).andExpect(status().isNoContent());
        resend("verify@iut-dhaka.edu");
        resend("unknown@iut-dhaka.edu");
        verify(sender, times(2)).send(anyString(), anyString());
    }

    @Test
    void replacementInvalidatesUnexpiredLink() throws Exception {
        String old = register();
        resend("verify@iut-dhaka.edu");
        verifyToken(old).andExpect(status().isBadRequest());
        verifyToken(delivered.get()).andExpect(status().isNoContent());
    }

    @Test
    void invalidAndMalformedRequestsUseApiError() throws Exception {
        verifyToken("x".repeat(43)).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_VERIFICATION_TOKEN"))
                .andExpect(jsonPath("$.path").value("/api/v1/auth/verify-email"));
        verifyToken("").andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        mvc.perform(post("/api/v1/auth/verify-email").contentType("application/json").content("{"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("MALFORMED_REQUEST"));
        mvc.perform(post("/api/v1/auth/resend-verification").contentType("application/json").content("{\"email\":\"bad\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void suspendedAndAnonymizedAccountsCannotBeActivated() throws Exception {
        String raw = register();
        jdbc.update("update users set account_status = 'SUSPENDED'");
        verifyToken(raw).andExpect(status().isBadRequest());
        resend("verify@iut-dhaka.edu");
        jdbc.update("update users set account_status = 'PENDING_VERIFICATION', anonymized_at = CURRENT_TIMESTAMP");
        verifyToken(raw).andExpect(status().isBadRequest());
        resend("verify@iut-dhaka.edu");
        verify(sender, times(1)).send(anyString(), anyString());
    }

    @Test
    void registrationDeliveryFailureRollsBackUserAndToken() throws Exception {
        doThrow(new VerificationDeliveryException()).when(sender).send(anyString(), anyString());
        mvc.perform(post("/api/v1/auth/register").contentType("application/json").content("""
                {"fullName":"Test","email":"fail@iut-dhaka.edu","password":"password123","platformRole":"ALUMNI"}
                """))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("VERIFICATION_EMAIL_UNAVAILABLE"));
        assertThat(users.count()).isZero();
        assertThat(tokens.count()).isZero();
    }

    @Test
    void resendDeliveryFailureIsNonDisclosingAndPreservesOldToken() throws Exception {
        String old = register();
        doThrow(new VerificationDeliveryException()).when(sender).send(anyString(), anyString());
        resend("verify@iut-dhaka.edu");
        resend("unknown@iut-dhaka.edu");
        assertThat(tokens.count()).isEqualTo(1);
        verifyToken(old).andExpect(status().isNoContent());
    }

    @Test
    void concurrentConsumptionHasExactlyOneSuccess() throws Exception {
        String raw = register();
        try (var executor = Executors.newFixedThreadPool(2)) {
            CountDownLatch start = new CountDownLatch(1);
            List<Future<Boolean>> results = new ArrayList<>();
            for (int i = 0; i < 2; i++) {
                results.add(executor.submit(() -> {
                    start.await();
                    try { service.verify(raw); return true; }
                    catch (com.uniconnect.shared.exception.BadRequestException exception) { return false; }
                }));
            }
            start.countDown();
            int successes = 0;
            for (Future<Boolean> result : results) if (result.get(10, TimeUnit.SECONDS)) successes++;
            assertThat(successes).isEqualTo(1);
        }
    }
    @Test
    void concurrentResendAndVerificationLeaveOneConsistentOutcome() throws Exception {
        String original = register();
        try (var executor = Executors.newFixedThreadPool(2)) {
            CountDownLatch start = new CountDownLatch(1);
            Future<Boolean> verified = executor.submit(() -> {
                start.await();
                try { service.verify(original); return true; }
                catch (com.uniconnect.shared.exception.BadRequestException exception) { return false; }
            });
            Future<?> resent = executor.submit(() -> {
                start.await();
                service.resend("verify@iut-dhaka.edu");
                return null;
            });
            start.countDown();
            boolean activated = verified.get(10, TimeUnit.SECONDS);
            resent.get(10, TimeUnit.SECONDS);
            if (activated) {
                assertThat(users.findByEmail("verify@iut-dhaka.edu").orElseThrow().getAccountStatus())
                        .isEqualTo(AccountStatus.ACTIVE);
                assertThat(tokens.count()).isEqualTo(1);
            } else {
                assertThat(delivered.get()).isNotEqualTo(original);
                verifyToken(delivered.get()).andExpect(status().isNoContent());
            }
            verifyToken(original).andExpect(status().isBadRequest());
        }
    }
}
