package com.spl2.uniconnect.unit.auth;

import com.spl2.uniconnect.base.BaseUnitTest;
import com.spl2.uniconnect.domain.user.TokenType;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.domain.user.VerificationToken;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.repository.user.VerificationTokenRepository;
import com.spl2.uniconnect.service.auth.EmailVerificationService;
import com.spl2.uniconnect.service.email.EmailService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@DisplayName("EmailVerificationService Unit Tests")
class EmailVerificationServiceTest extends BaseUnitTest {

    @Mock
    private VerificationTokenRepository tokenRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private EmailVerificationService emailVerificationService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .userId(1L)
                .email("student@iut-dhaka.edu")
                .passwordHash("encoded")
                .fullName("Test Student")
                .role(UserRole.STUDENT)
                .emailVerified(false)
                .build();
    }

    // ============================================
    // SEND VERIFICATION EMAIL TESTS
    // ============================================

    @Nested
    @DisplayName("Send Verification Email")
    class SendVerificationEmail {

        @Test
        @DisplayName("Should send verification email successfully")
        void shouldSendVerificationEmailSuccessfully() {
            // Given
            doNothing().when(tokenRepository)
                    .deleteByUserIdAndTokenType(anyLong(), any(TokenType.class));
            when(tokenRepository.save(any(VerificationToken.class)))
                    .thenAnswer(invocation -> invocation.getArgument(0));
            doNothing().when(emailService).sendVerificationEmail(any(User.class), anyString());

            // When
            emailVerificationService.sendVerificationEmail(testUser);

            // Then
            verify(tokenRepository).deleteByUserIdAndTokenType(1L, TokenType.EMAIL_VERIFICATION);
            verify(tokenRepository).save(any(VerificationToken.class));
            verify(emailService).sendVerificationEmail(eq(testUser), anyString());
        }

        @Test
        @DisplayName("Should create token with correct type")
        void shouldCreateTokenWithCorrectType() {
            // Given
            doNothing().when(tokenRepository).deleteByUserIdAndTokenType(anyLong(), any());
            ArgumentCaptor<VerificationToken> tokenCaptor =
                    ArgumentCaptor.forClass(VerificationToken.class);
            when(tokenRepository.save(tokenCaptor.capture()))
                    .thenAnswer(invocation -> invocation.getArgument(0));

            // When
            emailVerificationService.sendVerificationEmail(testUser);

            // Then
            VerificationToken savedToken = tokenCaptor.getValue();
            assertThat(savedToken.getTokenType()).isEqualTo(TokenType.EMAIL_VERIFICATION);
            assertThat(savedToken.getUser()).isEqualTo(testUser);
            assertThat(savedToken.getToken()).isNotBlank();
        }

        @Test
        @DisplayName("Should create token that expires in 24 hours")
        void shouldCreateTokenExpiringIn24Hours() {
            // Given
            doNothing().when(tokenRepository).deleteByUserIdAndTokenType(anyLong(), any());
            ArgumentCaptor<VerificationToken> tokenCaptor =
                    ArgumentCaptor.forClass(VerificationToken.class);
            when(tokenRepository.save(tokenCaptor.capture()))
                    .thenAnswer(invocation -> invocation.getArgument(0));

            // When
            LocalDateTime beforeTest = LocalDateTime.now();
            emailVerificationService.sendVerificationEmail(testUser);
            LocalDateTime afterTest = LocalDateTime.now();

            // Then
            VerificationToken savedToken = tokenCaptor.getValue();
            assertThat(savedToken.getExpiresAt())
                    .isAfter(beforeTest.plusHours(23))
                    .isBefore(afterTest.plusHours(25));
        }

        @Test
        @DisplayName("Should delete old tokens before creating new one")
        void shouldDeleteOldTokensBeforeCreatingNew() {
            // Given
            doNothing().when(tokenRepository).deleteByUserIdAndTokenType(anyLong(), any());
            when(tokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));

            // When
            emailVerificationService.sendVerificationEmail(testUser);

            // Then - delete is called BEFORE save
            var inOrder = inOrder(tokenRepository);
            inOrder.verify(tokenRepository).deleteByUserIdAndTokenType(anyLong(), any());
            inOrder.verify(tokenRepository).save(any());
        }
    }

    // ============================================
    // VERIFY EMAIL TESTS
    // ============================================

    @Nested
    @DisplayName("Verify Email")
    class VerifyEmail {

        @Test
        @DisplayName("Should verify email successfully with valid token")
        void shouldVerifyEmailSuccessfully() {
            // Given
            VerificationToken validToken = VerificationToken.builder()
                    .user(testUser)
                    .token("valid-token-123")
                    .tokenType(TokenType.EMAIL_VERIFICATION)
                    .expiresAt(LocalDateTime.now().plusHours(1))
                    .build();

            when(tokenRepository.findValidToken(eq("valid-token-123"), any(LocalDateTime.class)))
                    .thenReturn(Optional.of(validToken));
            when(userRepository.save(any(User.class))).thenReturn(testUser);
            doNothing().when(tokenRepository).delete(any(VerificationToken.class));
            doNothing().when(emailService).sendWelcomeEmail(any(User.class));

            // When
            emailVerificationService.verifyEmail("valid-token-123");

            // Then
            verify(userRepository).save(argThat(user -> user.getEmailVerified()));
            verify(tokenRepository).delete(validToken);
            verify(emailService).sendWelcomeEmail(testUser);
        }

        @Test
        @DisplayName("Should throw exception for invalid token")
        void shouldThrowExceptionForInvalidToken() {
            // Given
            when(tokenRepository.findValidToken(eq("invalid-token"), any(LocalDateTime.class)))
                    .thenReturn(Optional.empty());

            // When & Then
            assertThatThrownBy(() -> emailVerificationService.verifyEmail("invalid-token"))
                    .isInstanceOf(RuntimeException.class)
                    .hasMessageContaining("Invalid or expired");
        }

        @Test
        @DisplayName("Should not re-verify already verified email")
        void shouldNotReVerifyAlreadyVerifiedEmail() {
            // Given
            testUser.setEmailVerified(true); // Already verified

            VerificationToken token = VerificationToken.builder()
                    .user(testUser)
                    .token("token-123")
                    .tokenType(TokenType.EMAIL_VERIFICATION)
                    .expiresAt(LocalDateTime.now().plusHours(1))
                    .build();

            when(tokenRepository.findValidToken(anyString(), any()))
                    .thenReturn(Optional.of(token));

            // When
            emailVerificationService.verifyEmail("token-123");

            // Then - user should NOT be saved again
            verify(userRepository, never()).save(any(User.class));
        }

        @Test
        @DisplayName("Should send welcome email after successful verification")
        void shouldSendWelcomeEmailAfterVerification() {
            // Given
            VerificationToken validToken = VerificationToken.builder()
                    .user(testUser)
                    .token("valid-token")
                    .tokenType(TokenType.EMAIL_VERIFICATION)
                    .expiresAt(LocalDateTime.now().plusHours(1))
                    .build();

            when(tokenRepository.findValidToken(anyString(), any()))
                    .thenReturn(Optional.of(validToken));
            when(userRepository.save(any())).thenReturn(testUser);

            // When
            emailVerificationService.verifyEmail("valid-token");

            // Then
            verify(emailService).sendWelcomeEmail(testUser);
        }
    }

    // ============================================
    // RESEND VERIFICATION TESTS
    // ============================================

    @Nested
    @DisplayName("Resend Verification Email")
    class ResendVerificationEmail {

        @Test
        @DisplayName("Should resend verification email successfully")
        void shouldResendVerificationEmailSuccessfully() {
            // Given
            when(userRepository.findByEmail("student@iut-dhaka.edu"))
                    .thenReturn(Optional.of(testUser));
            doNothing().when(tokenRepository).deleteByUserIdAndTokenType(anyLong(), any());
            when(tokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));
            doNothing().when(emailService).sendVerificationEmail(any(), anyString());

            // When
            emailVerificationService.resendVerificationEmail("student@iut-dhaka.edu");

            // Then
            verify(emailService).sendVerificationEmail(eq(testUser), anyString());
        }

        @Test
        @DisplayName("Should throw exception when resending to already verified user")
        void shouldThrowExceptionForAlreadyVerifiedUser() {
            // Given
            testUser.setEmailVerified(true);
            when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(testUser));

            // When & Then
            assertThatThrownBy(() ->
                    emailVerificationService.resendVerificationEmail("student@iut-dhaka.edu"))
                    .isInstanceOf(RuntimeException.class)
                    .hasMessageContaining("already verified");
        }

        @Test
        @DisplayName("Should throw exception when user not found")
        void shouldThrowExceptionWhenUserNotFound() {
            // Given
            when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());

            // When & Then
            assertThatThrownBy(() ->
                    emailVerificationService.resendVerificationEmail("notfound@iut-dhaka.edu"))
                    .isInstanceOf(RuntimeException.class);
        }
    }

    // ============================================
    // CLEANUP TESTS
    // ============================================

    @Nested
    @DisplayName("Cleanup Expired Tokens")
    class CleanupExpiredTokens {

        @Test
        @DisplayName("Should delete expired tokens and return count")
        void shouldDeleteExpiredTokens() {
            // Given
            when(tokenRepository.deleteAllExpiredTokens(any(LocalDateTime.class))).thenReturn(5);

            // When
            int deleted = emailVerificationService.cleanupExpiredTokens();

            // Then
            assertThat(deleted).isEqualTo(5);
            verify(tokenRepository).deleteAllExpiredTokens(any(LocalDateTime.class));
        }
    }
}
