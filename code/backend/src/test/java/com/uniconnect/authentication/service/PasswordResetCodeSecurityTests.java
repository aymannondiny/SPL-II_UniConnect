package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.security.PlatformRole;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@SpringBootTest
@ActiveProfiles("test")
class PasswordResetCodeSecurityTests {
    private static final Instant NOW = Instant.parse("2026-10-27T00:00:00Z");
    private static final String EMAIL = "recovery@iut-dhaka.edu";
    private static final String PASSWORD = "R7!mQ2#vL9@x";

    @Autowired PasswordResetService service;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired VerificationCodeGenerator generator;
    @Autowired JdbcTemplate jdbc;
    @MockitoBean PasswordResetEmailSender sender;
    @MockitoBean Clock clock;

    private String delivered;
    private Long userId;

    @BeforeEach
    void setUp() {
        clean();
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        doAnswer(call -> {
            delivered = call.getArgument(1);
            return null;
        }).when(sender).send(anyString(), anyString());
        User user = User.register("Recovery Member", EMAIL, passwords.encode("password123"), PlatformRole.STUDENT);
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

    @Test
    void cooldownAndHourlyLimitDoNotInvalidateTheCurrentCode() {
        service.requestReset(EMAIL);
        String first = delivered;
        when(clock.instant()).thenReturn(NOW.plusSeconds(59));
        service.requestReset(EMAIL);
        assertThat(delivered).isEqualTo(first);
        verify(sender, times(1)).send(eq(EMAIL), anyString());
        for (int issuance = 1; issuance < 5; issuance++) {
            when(clock.instant()).thenReturn(NOW.plusSeconds(60L * issuance));
            service.requestReset(EMAIL);
        }
        String latest = delivered;
        when(clock.instant()).thenReturn(NOW.plusSeconds(300));
        service.requestReset(EMAIL);
        verify(sender, times(5)).send(eq(EMAIL), anyString());
        assertThat(jdbc.queryForObject("select count(*) from password_reset_tokens", Integer.class)).isEqualTo(5);
        service.reset(EMAIL, latest, PASSWORD);
    }

    @Test
    void hourlyLimitAllowsIssuanceAfterTheWindow() {
        for (int issuance = 0; issuance < 5; issuance++) {
            when(clock.instant()).thenReturn(NOW.plusSeconds(60L * issuance));
            service.requestReset(EMAIL);
        }
        when(clock.instant()).thenReturn(NOW.plusSeconds(3601));
        service.requestReset(EMAIL);
        verify(sender, times(6)).send(eq(EMAIL), anyString());
    }

    @Test
    void fifthWrongAttemptPersistsRevocationWithoutChangingPasswordOrSession() {
        var session = sessions.login(new LoginRequest(EMAIL, "password123"));
        service.requestReset(EMAIL);
        String correct = delivered;
        String wrong = correct.equals("000000") ? "000001" : "000000";
        for (int attempt = 1; attempt <= 5; attempt++) {
            assertThatThrownBy(() -> service.reset(EMAIL, wrong, PASSWORD))
                    .isInstanceOf(BadRequestException.class);
            assertThat(jdbc.queryForObject("select failed_attempts from password_reset_tokens", Integer.class))
                    .isEqualTo(attempt);
        }
        assertThatThrownBy(() -> service.reset(EMAIL, correct, PASSWORD))
                .isInstanceOf(BadRequestException.class);
        assertThat(passwords.matches("password123", users.findById(userId).orElseThrow().getPasswordHash())).isTrue();
        assertThat(sessions.authenticate(session.accessToken()).userId()).isEqualTo(userId);
    }

    @Test
    void correctCodeAfterFourWrongAttemptsStillWorks() {
        service.requestReset(EMAIL);
        String correct = delivered;
        String wrong = correct.equals("000000") ? "000001" : "000000";
        for (int attempt = 0; attempt < 4; attempt++) {
            assertThatThrownBy(() -> service.reset(EMAIL, wrong, PASSWORD))
                    .isInstanceOf(BadRequestException.class);
        }
        service.reset("  RECOVERY@IUT-DHAKA.EDU  ", correct, PASSWORD);
        assertThat(sessions.login(new LoginRequest(EMAIL, PASSWORD))).isNotNull();
    }

    @Test
    void codesAreSaltedAccountBoundAndSeparateFromSignupVerification() {
        service.requestReset(EMAIL);
        String digest = jdbc.queryForObject("select token_hash from password_reset_tokens", String.class);
        String salt = jdbc.queryForObject("select code_salt from password_reset_tokens", String.class);
        assertThat(salt).hasSize(43);
        assertThat(generator.matches(userId, EMAIL, salt, digest, delivered)).isTrue();
        assertThat(generator.matches(userId, "other@iut-dhaka.edu", salt, digest, delivered)).isFalse();
        assertThatThrownBy(() -> service.reset("other@iut-dhaka.edu", delivered, PASSWORD))
                .isInstanceOf(BadRequestException.class);
        assertThat(jdbc.queryForObject("select count(*) from email_verification_tokens", Integer.class)).isZero();
    }

    @Test
    void oldLinkRecordsCannotBeRedeemedAsCodes() {
        jdbc.update("insert into password_reset_tokens (user_id, token_hash, created_at, expires_at) values (?, ?, ?, ?)",
                userId, "a".repeat(64), LocalDateTime.ofInstant(NOW, ZoneOffset.UTC),
                LocalDateTime.ofInstant(NOW.plusSeconds(3600), ZoneOffset.UTC));
        assertThatThrownBy(() -> service.reset(EMAIL, "123456", PASSWORD))
                .isInstanceOf(BadRequestException.class);
    }
}
