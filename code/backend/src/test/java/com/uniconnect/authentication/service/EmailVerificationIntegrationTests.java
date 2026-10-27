package com.uniconnect.authentication.service;

import com.uniconnect.authentication.dto.VerifyEmailRequest;
import com.uniconnect.authentication.repository.EmailVerificationTokenRepository;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.security.AccountStatus;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = {
        "spring.datasource.url=${verification.integration.url:jdbc:h2:mem:uniconnect;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE}",
        "spring.datasource.driver-class-name=${verification.integration.driver:org.h2.Driver}",
        "spring.datasource.username=${verification.integration.username:sa}",
        "spring.datasource.password=${verification.integration.password:}"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(EmailVerificationIntegrationTests.CodeConfiguration.class)
class EmailVerificationIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired UserRepository users;
    @Autowired EmailVerificationTokenRepository challenges;
    @Autowired EmailVerificationService service;
    @Autowired ControlledVerificationCodeGenerator generator;
    @MockitoBean VerificationEmailSender sender;
    @MockitoBean Clock clock;

    private record Delivery(String email, String code) {}
    private final List<Delivery> deliveries = new CopyOnWriteArrayList<>();
    private final AtomicReference<Instant> current = new AtomicReference<>();
    private static final Instant NOW = Instant.parse("2026-09-28T00:00:00Z");

    @BeforeEach
    void setup() {
        jdbc.update("delete from email_verification_tokens");
        jdbc.update("delete from users");
        reset(sender, clock);
        generator.clear();
        deliveries.clear();
        current.set(NOW);
        when(clock.instant()).thenAnswer(call -> current.get());
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        doAnswer(call -> {
            deliveries.add(new Delivery(call.getArgument(0), call.getArgument(1)));
            return null;
        }).when(sender).send(anyString(), anyString());
    }

    @AfterEach
    void cleanup() {
        jdbc.update("delete from authenticated_sessions");
        jdbc.update("delete from email_verification_tokens");
        jdbc.update("delete from users");
    }

    private String register(String email) throws Exception {
        mvc.perform(post("/api/v1/auth/register").contentType("application/json").content("""
                {"fullName":"Test Member","email":"%s",
                 "password":"R7!mQ2#vL9@x","platformRole":"STUDENT"}
                """.formatted(email)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accountStatus").value("PENDING_VERIFICATION"))
                .andExpect(jsonPath("$.code").doesNotExist())
                .andExpect(jsonPath("$.token").doesNotExist());
        return deliveries.getLast().code();
    }

    private org.springframework.test.web.servlet.ResultActions verifyCode(String email, String code) throws Exception {
        return mvc.perform(post("/api/v1/auth/verify-email").contentType("application/json")
                .content("{\"email\":\"" + email + "\",\"code\":\"" + code + "\"}"));
    }

    private org.springframework.test.web.servlet.ResultActions resend(String email) throws Exception {
        return mvc.perform(post("/api/v1/auth/resend-verification").contentType("application/json")
                .content("{\"email\":\"" + email + "\"}"));
    }

    private void advance(Duration duration) {
        current.updateAndGet(value -> value.plus(duration));
    }

    @Test
    void registrationSendsLeadingZeroCodeToNormalizedEmailAndStoresOnlyBoundDigest() throws Exception {
        generator.force("012345");
        String raw = register("VERIFY@IUT-DHAKA.EDU");
        assertThat(raw).isEqualTo("012345");
        assertThat(deliveries.getFirst().email()).isEqualTo("verify@iut-dhaka.edu");
        var challenge = challenges.findAll().getFirst();
        assertThat(challenge.getCodeDigest()).hasSize(64).doesNotContain(raw);
        assertThat(challenge.getCodeSalt()).hasSize(43).doesNotContain(raw);
        assertThat(challenge.getExpiresAt()).isEqualTo(
                LocalDateTime.ofInstant(NOW.plus(Duration.ofMinutes(10)), ZoneOffset.UTC));
        assertThat(new VerifyEmailRequest("verify@iut-dhaka.edu", raw).toString())
                .doesNotContain(raw).contains("<redacted>");
    }

    @Test
    void correctEmailAndCodeActivateExactlyOnceAndDoNotCreateSession() throws Exception {
        String raw = register("verify@iut-dhaka.edu");
        verifyCode("VERIFY@IUT-DHAKA.EDU", raw)
                .andExpect(status().isNoContent()).andExpect(content().string(""));
        assertThat(users.findByEmail("verify@iut-dhaka.edu").orElseThrow().getAccountStatus())
                .isEqualTo(AccountStatus.ACTIVE);
        verifyCode("verify@iut-dhaka.edu", raw).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_VERIFICATION_CODE"));
        assertThat(jdbc.queryForObject("select count(*) from authenticated_sessions", Integer.class)).isZero();
    }

    @Test
    void wrongEmailWrongCodeMalformedInputAndExpiryBoundaryAreRejected() throws Exception {
        String raw = register("verify@iut-dhaka.edu");
        verifyCode("wrong@iut-dhaka.edu", raw).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_VERIFICATION_CODE"));
        assertThat(challenges.findAll().getFirst().getFailedAttempts()).isZero();
        verifyCode("verify@iut-dhaka.edu", "999999").andExpect(status().isBadRequest());
        assertThat(challenges.findAll().getFirst().getFailedAttempts()).isOne();
        verifyCode("verify@iut-dhaka.edu", "12345").andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        mvc.perform(post("/api/v1/auth/verify-email").contentType("application/json").content("{"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("MALFORMED_REQUEST"));
        current.set(NOW.plus(Duration.ofMinutes(10)));
        verifyCode("verify@iut-dhaka.edu", raw).andExpect(status().isBadRequest());
        assertThat(users.findByEmail("verify@iut-dhaka.edu").orElseThrow().getAccountStatus())
                .isEqualTo(AccountStatus.PENDING_VERIFICATION);
    }

    @Test
    void fifthWrongAttemptDurablyExhaustsChallengeAcrossFailedRequests() throws Exception {
        String raw = register("verify@iut-dhaka.edu");
        String wrong = raw.equals("000000") ? "000001" : "000000";
        for (int attempt = 1; attempt <= 5; attempt++) {
            verifyCode("verify@iut-dhaka.edu", wrong).andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("INVALID_VERIFICATION_CODE"));
            assertThat(challenges.findAll().getFirst().getFailedAttempts()).isEqualTo(attempt);
        }
        verifyCode("verify@iut-dhaka.edu", raw).andExpect(status().isBadRequest());
        assertThat(users.findByEmail("verify@iut-dhaka.edu").orElseThrow().getAccountStatus())
                .isEqualTo(AccountStatus.PENDING_VERIFICATION);
    }

    @Test
    void sameNumericCodeCanBeIssuedToDifferentAccounts() throws Exception {
        generator.force("123456", "123456");
        assertThat(register("one@iut-dhaka.edu")).isEqualTo("123456");
        assertThat(register("two@iut-dhaka.edu")).isEqualTo("123456");
        assertThat(challenges.findAll()).extracting("codeDigest").doesNotHaveDuplicates();
        verifyCode("one@iut-dhaka.edu", "123456").andExpect(status().isNoContent());
        verifyCode("two@iut-dhaka.edu", "123456").andExpect(status().isNoContent());
    }

    @Test
    void resendEnforcesCooldownAndRollingIssuanceLimit() throws Exception {
        register("verify@iut-dhaka.edu");
        resend("verify@iut-dhaka.edu").andExpect(status().isAccepted())
                .andExpect(content().string(""))
                .andExpect(header().doesNotExist("Retry-After"));
        assertThat(challenges.count()).isOne();
        assertThat(deliveries).hasSize(1);
        for (int issuance = 2; issuance <= 5; issuance++) {
            advance(Duration.ofSeconds(60));
            resend("VERIFY@IUT-DHAKA.EDU").andExpect(status().isAccepted());
        }
        advance(Duration.ofSeconds(60));
        resend("verify@iut-dhaka.edu").andExpect(status().isAccepted())
                .andExpect(content().string(""))
                .andExpect(header().doesNotExist("Retry-After"));
        assertThat(challenges.count()).isEqualTo(5);
        assertThat(deliveries).hasSize(5);
        advance(Duration.ofMinutes(56));
        resend("verify@iut-dhaka.edu").andExpect(status().isAccepted());
        assertThat(challenges.count()).isEqualTo(6);
        assertThat(deliveries).hasSize(6);
    }

    @Test
    void resendInvalidatesOldCodeAndNeverReusesImmediatelyPreviousCode() throws Exception {
        generator.force("111111", "111111", "222222");
        String old = register("verify@iut-dhaka.edu");
        advance(Duration.ofSeconds(60));
        resend("verify@iut-dhaka.edu").andExpect(status().isAccepted());
        String replacement = deliveries.getLast().code();
        assertThat(old).isEqualTo("111111");
        assertThat(replacement).isEqualTo("222222");
        verifyCode("verify@iut-dhaka.edu", old).andExpect(status().isBadRequest());
        verifyCode("verify@iut-dhaka.edu", replacement).andExpect(status().isNoContent());
    }

    @Test
    void failedDeliveryRollsBackRegistrationAndPreservesPreviousChallengeAndAllowance() throws Exception {
        doThrow(new VerificationDeliveryException()).when(sender).send(anyString(), anyString());
        mvc.perform(post("/api/v1/auth/register").contentType("application/json").content("""
                {"fullName":"Test","email":"fail@iut-dhaka.edu",
                 "password":"R7!mQ2#vL9@x","platformRole":"ALUMNI"}
                """))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("VERIFICATION_EMAIL_UNAVAILABLE"));
        assertThat(users.count()).isZero();
        assertThat(challenges.count()).isZero();

        reset(sender);
        doAnswer(call -> { deliveries.add(new Delivery(call.getArgument(0), call.getArgument(1))); return null; })
                .when(sender).send(anyString(), anyString());
        String old = register("verify@iut-dhaka.edu");
        advance(Duration.ofSeconds(60));
        doThrow(new VerificationDeliveryException()).when(sender).send(anyString(), anyString());
        resend("verify@iut-dhaka.edu").andExpect(status().isAccepted());
        assertThat(challenges.count()).isOne();
        verifyCode("verify@iut-dhaka.edu", old).andExpect(status().isNoContent());
    }

    @Test
    void unknownAndIneligibleResendsAreGenericAndAccountsCannotBeReactivated() throws Exception {
        String raw = register("verify@iut-dhaka.edu");
        jdbc.update("update users set account_status = 'SUSPENDED'");
        verifyCode("verify@iut-dhaka.edu", raw).andExpect(status().isBadRequest());
        resend("verify@iut-dhaka.edu").andExpect(status().isAccepted()).andExpect(content().string(""));
        jdbc.update("update users set account_status = 'PENDING_VERIFICATION', anonymized_at = CURRENT_TIMESTAMP");
        verifyCode("verify@iut-dhaka.edu", raw).andExpect(status().isBadRequest());
        resend("verify@iut-dhaka.edu").andExpect(status().isAccepted());
        resend("unknown@iut-dhaka.edu").andExpect(status().isAccepted());
        jdbc.update("update users set account_status = 'ACTIVE', anonymized_at = null");
        verifyCode("verify@iut-dhaka.edu", raw).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_VERIFICATION_CODE"));
        resend("verify@iut-dhaka.edu").andExpect(status().isAccepted());
        verify(sender, times(1)).send(anyString(), anyString());
    }

    @Test
    void concurrentVerificationHasOneSuccessAndConcurrentFailuresLoseNoIncrements() throws Exception {
        String verificationCode = register("verify@iut-dhaka.edu");
        assertThat(runConcurrently(2, () -> {
            service.verify("verify@iut-dhaka.edu", verificationCode);
            return true;
        }, BadRequestException.class)).containsExactlyInAnyOrder(true, false);

        jdbc.update("delete from email_verification_tokens");
        jdbc.update("delete from users");
        deliveries.clear();
        String attemptsCode = register("attempts@iut-dhaka.edu");
        String wrong = attemptsCode.equals("000000") ? "000001" : "000000";
        assertThat(runConcurrently(5, () -> {
            service.verify("attempts@iut-dhaka.edu", wrong);
            return true;
        }, BadRequestException.class)).containsOnly(false);
        assertThat(challenges.findAll().getFirst().getFailedAttempts()).isEqualTo(5);
    }

    @Test
    void concurrentResendsRespectCooldownAndVerifyResendInteractionIsConsistent() throws Exception {
        String original = register("verify@iut-dhaka.edu");
        advance(Duration.ofSeconds(60));
        var resendResults = runConcurrently(2, () -> {
            service.resend("verify@iut-dhaka.edu");
            return true;
        }, BadRequestException.class);
        assertThat(resendResults).containsOnly(true);
        assertThat(challenges.count()).isEqualTo(2);
        assertThat(deliveries).hasSize(2);

        String replacement = deliveries.getLast().code();
        advance(Duration.ofSeconds(60));
        try (var executor = Executors.newFixedThreadPool(2)) {
            CountDownLatch start = new CountDownLatch(1);
            Future<Boolean> verified = executor.submit(() -> {
                start.await();
                try { service.verify("verify@iut-dhaka.edu", replacement); return true; }
                catch (BadRequestException exception) { return false; }
            });
            Future<Boolean> resent = executor.submit(() -> {
                start.await();
                service.resend("verify@iut-dhaka.edu");
                return true;
            });
            start.countDown();
            boolean activated = verified.get(10, TimeUnit.SECONDS);
            boolean replacementIssued = resent.get(10, TimeUnit.SECONDS);
            assertThat(replacementIssued).isTrue();
            if (activated) {
                assertThat(users.findByEmail("verify@iut-dhaka.edu").orElseThrow().getAccountStatus())
                        .isEqualTo(AccountStatus.ACTIVE);
            } else {
                verifyCode("verify@iut-dhaka.edu", deliveries.getLast().code())
                        .andExpect(status().isNoContent());
            }
        }
        verifyCode("verify@iut-dhaka.edu", original).andExpect(status().isBadRequest());
    }

    @Test
    void loginIsDeniedBeforeVerificationAndAllowedAfterward() throws Exception {
        String raw = register("verify@iut-dhaka.edu");
        mvc.perform(post("/api/v1/auth/login").contentType("application/json").content("""
                {"email":"verify@iut-dhaka.edu","password":"R7!mQ2#vL9@x"}
                """))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
        verifyCode("verify@iut-dhaka.edu", raw).andExpect(status().isNoContent());
        mvc.perform(post("/api/v1/auth/login").contentType("application/json").content("""
                {"email":"verify@iut-dhaka.edu","password":"R7!mQ2#vL9@x"}
                """))
                .andExpect(status().isOk()).andExpect(jsonPath("$.accessToken").isString());
    }

    private <E extends RuntimeException> List<Boolean> runConcurrently(int count, Callable<Boolean> action,
            Class<E> expectedFailure) throws Exception {
        try (var executor = Executors.newFixedThreadPool(count)) {
            CountDownLatch start = new CountDownLatch(1);
            List<Future<Boolean>> futures = new ArrayList<>();
            for (int index = 0; index < count; index++) {
                futures.add(executor.submit(() -> {
                    start.await();
                    try { return action.call(); }
                    catch (RuntimeException exception) {
                        if (expectedFailure.isInstance(exception)) return false;
                        throw exception;
                    }
                }));
            }
            start.countDown();
            List<Boolean> results = new ArrayList<>();
            for (Future<Boolean> future : futures) results.add(future.get(10, TimeUnit.SECONDS));
            return results;
        }
    }

    @TestConfiguration
    static class CodeConfiguration {
        @Bean
        @Primary
        ControlledVerificationCodeGenerator controlledVerificationCodeGenerator() {
            return new ControlledVerificationCodeGenerator();
        }
    }

    static final class ControlledVerificationCodeGenerator extends VerificationCodeGenerator {
        private final Queue<String> forced = new ArrayDeque<>();

        synchronized void force(String... codes) {
            forced.addAll(List.of(codes));
        }

        synchronized void clear() {
            forced.clear();
        }

        @Override
        public synchronized String generateCode() {
            return forced.isEmpty() ? super.generateCode() : forced.remove();
        }
    }
}
