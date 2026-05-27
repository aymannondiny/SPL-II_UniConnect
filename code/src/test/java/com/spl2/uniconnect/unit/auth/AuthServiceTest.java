package com.spl2.uniconnect.unit.auth;

import com.spl2.uniconnect.base.BaseUnitTest;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.auth.LoginRequest;
import com.spl2.uniconnect.dto.request.auth.RegisterRequest;
import com.spl2.uniconnect.dto.response.auth.LoginResponse;
import com.spl2.uniconnect.dto.response.auth.RegisterResponse;
import com.spl2.uniconnect.dto.response.auth.UserResponse;
import com.spl2.uniconnect.exception.EmailAlreadyExistsException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.security.JwtTokenProvider;
import com.spl2.uniconnect.security.UserDetailsImpl;
import com.spl2.uniconnect.service.auth.AuthService;
import com.spl2.uniconnect.service.auth.EmailVerificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@DisplayName("AuthService Unit Tests")
class AuthServiceTest extends BaseUnitTest {

    // ============================================
    // MOCKS - fake versions of dependencies
    // ============================================
    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private EmailVerificationService emailVerificationService;

    // ============================================
    // CLASS UNDER TEST
    // ============================================
    @InjectMocks
    private AuthService authService;

    // ============================================
    // TEST DATA
    // ============================================
    private User testUser;
    private RegisterRequest validRegisterRequest;
    private LoginRequest validLoginRequest;

    @BeforeEach
    void setUp() {
        // Build a test user that matches your User entity
        testUser = User.builder()
                .userId(1L)
                .email("student@iut-dhaka.edu")
                .passwordHash("$2a$10$encodedpassword")
                .fullName("Test Student")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();

        validRegisterRequest = RegisterRequest.builder()
                .email("student@iut-dhaka.edu")
                .password("Test@1234")
                .fullName("Test Student")
                .role(UserRole.STUDENT)
                .build();

        validLoginRequest = LoginRequest.builder()
                .email("student@iut-dhaka.edu")
                .password("Test@1234")
                .build();
    }

    // ============================================
    // REGISTRATION TESTS
    // ============================================

    @Nested
    @DisplayName("User Registration")
    class UserRegistration {

        @Test
        @DisplayName("Should register a new user successfully")
        void shouldRegisterNewUserSuccessfully() {
            // Given
            when(userRepository.existsByEmail(anyString())).thenReturn(false);
            when(passwordEncoder.encode(anyString())).thenReturn("$2a$10$encodedpassword");
            when(userRepository.save(any(User.class))).thenReturn(testUser);
            doNothing().when(emailVerificationService).sendVerificationEmail(any(User.class));

            // When
            RegisterResponse response = authService.register(validRegisterRequest);

            // Then
            assertThat(response).isNotNull();
            assertThat(response.getEmail()).isEqualTo("student@iut-dhaka.edu");
            assertThat(response.getFullName()).isEqualTo("Test Student");
            assertThat(response.getMessage()).contains("verify your account");

            // Verify interactions
            verify(userRepository).existsByEmail("student@iut-dhaka.edu");
            verify(passwordEncoder).encode("Test@1234");
            verify(userRepository).save(any(User.class));
            verify(emailVerificationService).sendVerificationEmail(any(User.class));
        }

        @Test
        @DisplayName("Should throw exception when email already exists")
        void shouldThrowExceptionWhenEmailAlreadyExists() {
            // Given
            when(userRepository.existsByEmail(anyString())).thenReturn(true);

            // When & Then
            assertThatThrownBy(() -> authService.register(validRegisterRequest))
                    .isInstanceOf(EmailAlreadyExistsException.class);

            // Verify user was NOT saved
            verify(userRepository, never()).save(any(User.class));
            verify(emailVerificationService, never()).sendVerificationEmail(any(User.class));
        }

        @Test
        @DisplayName("Should encode password before saving")
        void shouldEncodePasswordBeforeSaving() {
            // Given
            when(userRepository.existsByEmail(anyString())).thenReturn(false);
            when(passwordEncoder.encode("Test@1234")).thenReturn("$2a$10$encodedpassword");
            when(userRepository.save(any(User.class))).thenReturn(testUser);

            // When
            authService.register(validRegisterRequest);

            // Then - verify password was encoded
            verify(passwordEncoder).encode("Test@1234");

            // Verify the saved user has encoded password, NOT plain text
            verify(userRepository).save(argThat(user ->
                    !user.getPasswordHash().equals("Test@1234") // not plain text
            ));
        }

        @Test
        @DisplayName("Should save user with emailVerified = false on registration")
        void shouldSaveUserWithEmailNotVerified() {
            // Given
            when(userRepository.existsByEmail(anyString())).thenReturn(false);
            when(passwordEncoder.encode(anyString())).thenReturn("encoded");
            when(userRepository.save(any(User.class))).thenReturn(testUser);

            // When
            authService.register(validRegisterRequest);

            // Then - verify user saved with emailVerified = false
            verify(userRepository).save(argThat(user ->
                    !user.getEmailVerified()
            ));
        }

        @Test
        @DisplayName("Should send verification email after successful registration")
        void shouldSendVerificationEmailAfterRegistration() {
            // Given
            when(userRepository.existsByEmail(anyString())).thenReturn(false);
            when(passwordEncoder.encode(anyString())).thenReturn("encoded");
            when(userRepository.save(any(User.class))).thenReturn(testUser);
            doNothing().when(emailVerificationService).sendVerificationEmail(any(User.class));

            // When
            authService.register(validRegisterRequest);

            // Then
            verify(emailVerificationService, times(1)).sendVerificationEmail(any(User.class));
        }

        @Test
        @DisplayName("Should register alumni user successfully")
        void shouldRegisterAlumniSuccessfully() {
            // Given
            RegisterRequest alumniRequest = RegisterRequest.builder()
                    .email("alumni@iut-dhaka.edu")
                    .password("Test@1234")
                    .fullName("Test Alumni")
                    .role(UserRole.ALUMNI)
                    .build();

            User alumniUser = User.builder()
                    .userId(2L)
                    .email("alumni@iut-dhaka.edu")
                    .passwordHash("encoded")
                    .fullName("Test Alumni")
                    .role(UserRole.ALUMNI)
                    .emailVerified(false)
                    .build();

            when(userRepository.existsByEmail(anyString())).thenReturn(false);
            when(passwordEncoder.encode(anyString())).thenReturn("encoded");
            when(userRepository.save(any(User.class))).thenReturn(alumniUser);

            // When
            RegisterResponse response = authService.register(alumniRequest);

            // Then
            assertThat(response.getEmail()).isEqualTo("alumni@iut-dhaka.edu");
        }
    }

    // ============================================
    // LOGIN TESTS
    // ============================================

    @Nested
    @DisplayName("User Login")
    class UserLogin {

        @Test
        @DisplayName("Should login successfully with valid credentials")
        void shouldLoginSuccessfullyWithValidCredentials() {
            // Given
            UserDetailsImpl userDetails = mock(UserDetailsImpl.class);
            when(userDetails.getUserId()).thenReturn(1L);

            Authentication authentication = mock(Authentication.class);
            when(authentication.getPrincipal()).thenReturn(userDetails);

            when(authenticationManager.authenticate(any())).thenReturn(authentication);
            when(jwtTokenProvider.generateToken(any(Authentication.class))).thenReturn("jwt.token.here");
            when(jwtTokenProvider.getExpirationSeconds()).thenReturn(3600L);
            when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));

            // When
            LoginResponse response = authService.login(validLoginRequest);

            // Then
            assertThat(response).isNotNull();
            assertThat(response.getToken()).isEqualTo("jwt.token.here");
            assertThat(response.getTokenType()).isEqualTo("Bearer");
            assertThat(response.getUser().getEmail()).isEqualTo("student@iut-dhaka.edu");
        }

        @Test
        @DisplayName("Should throw exception with invalid credentials")
        void shouldThrowExceptionWithInvalidCredentials() {
            // Given
            when(authenticationManager.authenticate(any()))
                    .thenThrow(new BadCredentialsException("Invalid credentials"));

            // When & Then
            assertThatThrownBy(() -> authService.login(validLoginRequest))
                    .isInstanceOf(BadCredentialsException.class);

            // Verify no token was generated
            verify(jwtTokenProvider, never()).generateToken(any(Authentication.class));
        }

        @Test
        @DisplayName("Should include user info in login response")
        void shouldIncludeUserInfoInLoginResponse() {
            // Given
            UserDetailsImpl userDetails = mock(UserDetailsImpl.class);
            when(userDetails.getUserId()).thenReturn(1L);

            Authentication authentication = mock(Authentication.class);
            when(authentication.getPrincipal()).thenReturn(userDetails);

            when(authenticationManager.authenticate(any())).thenReturn(authentication);
            when(jwtTokenProvider.generateToken(any())).thenReturn("test.jwt.token");
            when(jwtTokenProvider.getExpirationSeconds()).thenReturn(3600L);
            when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));

            // When
            LoginResponse response = authService.login(validLoginRequest);

            // Then
            assertThat(response.getUser()).isNotNull();
            assertThat(response.getUser().getEmail()).isEqualTo("student@iut-dhaka.edu");
            assertThat(response.getUser().getFullName()).isEqualTo("Test Student");
            assertThat(response.getUser().getRole()).isEqualTo("STUDENT");
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when user not in DB after auth")
        void shouldThrowExceptionWhenUserNotFoundAfterAuth() {
            // Given
            UserDetailsImpl userDetails = mock(UserDetailsImpl.class);
            when(userDetails.getUserId()).thenReturn(999L);

            Authentication authentication = mock(Authentication.class);
            when(authentication.getPrincipal()).thenReturn(userDetails);

            when(authenticationManager.authenticate(any())).thenReturn(authentication);
            when(jwtTokenProvider.generateToken(any())).thenReturn("token");
            when(userRepository.findById(999L)).thenReturn(Optional.empty());

            // When & Then
            assertThatThrownBy(() -> authService.login(validLoginRequest))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    // ============================================
    // GET CURRENT USER TESTS
    // ============================================

    @Nested
    @DisplayName("Get Current User")
    class GetCurrentUser {

        @Test
        @DisplayName("Should return current user successfully")
        void shouldReturnCurrentUserSuccessfully() {
            // Given
            when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));

            // When
            UserResponse response = authService.getCurrentUser(1L);

            // Then
            assertThat(response).isNotNull();
            assertThat(response.getUserId()).isEqualTo(1L);
            assertThat(response.getEmail()).isEqualTo("student@iut-dhaka.edu");
            assertThat(response.getFullName()).isEqualTo("Test Student");
            assertThat(response.getRole()).isEqualTo("STUDENT");
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException for non-existent user")
        void shouldThrowExceptionForNonExistentUser() {
            // Given
            when(userRepository.findById(999L)).thenReturn(Optional.empty());

            // When & Then
            assertThatThrownBy(() -> authService.getCurrentUser(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    // ============================================
    // MAP TO USER RESPONSE TESTS
    // ============================================

    @Nested
    @DisplayName("Map User to Response")
    class MapToUserResponse {

        @Test
        @DisplayName("Should map all user fields correctly")
        void shouldMapAllUserFieldsCorrectly() {
            // When
            UserResponse response = authService.mapToUserResponse(testUser);

            // Then
            assertThat(response.getUserId()).isEqualTo(1L);
            assertThat(response.getEmail()).isEqualTo("student@iut-dhaka.edu");
            assertThat(response.getFullName()).isEqualTo("Test Student");
            assertThat(response.getRole()).isEqualTo("STUDENT");
            assertThat(response.getEmailVerified()).isTrue();
        }

        @Test
        @DisplayName("Should map role as string not enum")
        void shouldMapRoleAsString() {
            // When
            UserResponse response = authService.mapToUserResponse(testUser);

            // Then - role should be String "STUDENT" not enum
            assertThat(response.getRole()).isInstanceOf(String.class);
            assertThat(response.getRole()).isEqualTo("STUDENT");
        }
    }
}
