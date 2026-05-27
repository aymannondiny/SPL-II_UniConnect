package com.spl2.uniconnect.unit.auth;

import com.spl2.uniconnect.base.BaseUnitTest;
import com.spl2.uniconnect.domain.user.TokenType;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.domain.user.VerificationToken;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.repository.user.VerificationTokenRepository;
import com.spl2.uniconnect.service.auth.PasswordResetService;
import com.spl2.uniconnect.service.email.EmailService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@DisplayName("PasswordResetService Unit Tests")
class PasswordResetServiceTest extends BaseUnitTest {

    @Mock
    private VerificationTokenRepository tokenRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private EmailService emailService;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private PasswordResetService passwordResetService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .userId(1L)
                .email("student@iut-dhaka.edu")
                .passwordHash("$2a$10$oldEncodedPassword")
                .fullName("Test Student")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();
    }

    // ============================================
    // REQUEST PASSWORD RESET TESTS
    // ============================================

    @Nested
    @DisplayName("Request Password Reset")
    class RequestPasswordReset {

        @Test
        @DisplayName("Should send password reset email successfully")
        void shouldSendPasswordResetEmailSuccessfully() {
            // Given
            when(userRepository.findByEmail("student@iut-dhaka.edu"))
                    .thenReturn(Optional.of(testUser));
            doNothing().when(tokenRepository)
                    .deleteByUserIdAndTokenType(anyLong(), any(TokenType.class));
            when(tokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));
            doNothing().when(emailService).sendPasswordResetEmail(any(User.class), anyString());

            // When
            passwordResetService.requestPasswordReset("student@iut-dhaka.edu");

            // Then
            verify(tokenRepository).deleteByUserIdAndTokenType(1L, TokenType.PASSWORD_RESET);
            verify(tokenRepository).save(any(VerificationToken.class));
            verify(emailService).sendPasswordResetEmail(eq(testUser), anyString());
        }

        @Test
        @DisplayName("Should throw exception when email not found")
        void shouldThrowExceptionWhenEmailNotFound() {
            // Given
            when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());

            // When & Then
            assertThatThrownBy(() ->
                    passwordResetService.requestPasswordReset("notfound@iut-dhaka.edu"))
                    .isInstanceOf(RuntimeException.class);

            verify(emailService, never()).sendPasswordResetEmail(any(), anyString());
        }

        @Test
        @DisplayName("Should create reset token expiring in 1 hour")
        void shouldCreateResetTokenExpiringIn1Hour() {
            // Given
            when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(testUser));
            doNothing().when(tokenRepository).deleteByUserIdAndTokenType(anyLong(), any());

            ArgumentCaptor<VerificationToken> tokenCaptor =
                    ArgumentCaptor.forClass(VerificationToken.class);
            when(tokenRepository.save(tokenCaptor.capture()))
                    .thenAnswer(i -> i.getArgument(0));

            // When
            LocalDateTime before = LocalDateTime.now();
            passwordResetService.requestPasswordReset("student@iut-dhaka.edu");
            LocalDateTime after = LocalDateTime.now();

            // Then
            VerificationToken savedToken = tokenCaptor.getValue();
            assertThat(savedToken.getTokenType()).isEqualTo(TokenType.PASSWORD_RESET);
            assertThat(savedToken.getExpiresAt())
                    .isAfter(before.plusMinutes(59))
                    .isBefore(after.plusMinutes(61));
        }

        @Test
        @DisplayName("Should delete old reset tokens before creating new one")
        void shouldDeleteOldTokensBeforeCreatingNew() {
            // Given
            when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(testUser));
            doNothing().when(tokenRepository).deleteByUserIdAndTokenType(anyLong(), any());
            when(tokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));

            // When
            passwordResetService.requestPasswordReset("student@iut-dhaka.edu");

            // Then - verify order: delete THEN save
            var inOrder = inOrder(tokenRepository);
            inOrder.verify(tokenRepository).deleteByUserIdAndTokenType(anyLong(), any());
            inOrder.verify(tokenRepository).save(any());
        }
    }

    // ============================================
    // RESET PASSWORD TESTS
    // ============================================

    @Nested
    @DisplayName("Reset Password")
    class ResetPassword {

        @Test
        @DisplayName("Should reset password successfully with valid token")
        void shouldResetPasswordSuccessfully() {
            // Given
            VerificationToken validToken = VerificationToken.builder()
                    .user(testUser)
                    .token("reset-token-123")
                    .tokenType(TokenType.PASSWORD_RESET)
                    .expiresAt(LocalDateTime.now().plusHours(1))
                    .build();

            when(tokenRepository.findValidToken(eq("reset-token-123"), any()))
                    .thenReturn(Optional.of(validToken));
            when(passwordEncoder.encode("NewPassword@123")).thenReturn("$2a$10$newEncoded");
            when(userRepository.save(any(User.class))).thenReturn(testUser);
            doNothing().when(tokenRepository).delete(any(VerificationToken.class));

            // When
            passwordResetService.resetPassword("reset-token-123", "NewPassword@123");

            // Then
            verify(passwordEncoder).encode("NewPassword@123");
            verify(userRepository).save(argThat(user ->
                    user.getPasswordHash().equals("$2a$10$newEncoded")
            ));
            verify(tokenRepository).delete(validToken);
        }

        @Test
        @DisplayName("Should throw exception for invalid reset token")
        void shouldThrowExceptionForInvalidToken() {
            // Given
            when(tokenRepository.findValidToken(anyString(), any())).thenReturn(Optional.empty());

            // When & Then
            assertThatThrownBy(() ->
                    passwordResetService.resetPassword("invalid-token", "NewPassword@123"))
                    .isInstanceOf(RuntimeException.class)
                    .hasMessageContaining("Invalid or expired");

            verify(userRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should delete token after successful password reset")
        void shouldDeleteTokenAfterReset() {
            // Given
            VerificationToken validToken = VerificationToken.builder()
                    .user(testUser)
                    .token("valid-reset-token")
                    .tokenType(TokenType.PASSWORD_RESET)
                    .expiresAt(LocalDateTime.now().plusHours(1))
                    .build();

            when(tokenRepository.findValidToken(anyString(), any()))
                    .thenReturn(Optional.of(validToken));
            when(passwordEncoder.encode(anyString())).thenReturn("encoded");
            when(userRepository.save(any())).thenReturn(testUser);

            // When
            passwordResetService.resetPassword("valid-reset-token", "NewPassword@123");

            // Then
            verify(tokenRepository).delete(validToken);
        }

        @Test
        @DisplayName("Should encode new password before saving")
        void shouldEncodeNewPasswordBeforeSaving() {
            // Given
            VerificationToken validToken = VerificationToken.builder()
                    .user(testUser)
                    .token("token")
                    .tokenType(TokenType.PASSWORD_RESET)
                    .expiresAt(LocalDateTime.now().plusHours(1))
                    .build();

            when(tokenRepository.findValidToken(anyString(), any()))
                    .thenReturn(Optional.of(validToken));
            when(passwordEncoder.encode("NewPassword@123")).thenReturn("$2a$10$encoded");
            when(userRepository.save(any())).thenReturn(testUser);

            // When
            passwordResetService.resetPassword("token", "NewPassword@123");

            // Then - password must be encoded, not plain text
            verify(userRepository).save(argThat(user ->
                    !user.getPasswordHash().equals("NewPassword@123")
            ));
        }
    }

    // ============================================
    // VALIDATE RESET TOKEN TESTS
    // ============================================

    @Nested
    @DisplayName("Validate Reset Token")
    class ValidateResetToken {

        @Test
        @DisplayName("Should return true for valid token")
        void shouldReturnTrueForValidToken() {
            // Given
            VerificationToken validToken = VerificationToken.builder()
                    .user(testUser)
                    .token("valid-token")
                    .tokenType(TokenType.PASSWORD_RESET)
                    .expiresAt(LocalDateTime.now().plusHours(1))
                    .build();

            when(tokenRepository.findValidToken(eq("valid-token"), any()))
                    .thenReturn(Optional.of(validToken));

            // When
            boolean isValid = passwordResetService.validateResetToken("valid-token");

            // Then
            assertThat(isValid).isTrue();
        }

        @Test
        @DisplayName("Should return false for invalid token")
        void shouldReturnFalseForInvalidToken() {
            // Given
            when(tokenRepository.findValidToken(anyString(), any()))
                    .thenReturn(Optional.empty());

            // When
            boolean isValid = passwordResetService.validateResetToken("invalid-token");

            // Then
            assertThat(isValid).isFalse();
        }
    }
}
