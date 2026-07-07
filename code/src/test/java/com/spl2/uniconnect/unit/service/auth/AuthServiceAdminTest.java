package com.spl2.uniconnect.unit.service.auth;

import com.spl2.uniconnect.domain.user.AdminProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.auth.CreateAdminRequest;
import com.spl2.uniconnect.dto.response.auth.RegisterResponse;
import com.spl2.uniconnect.exception.EmailAlreadyExistsException;
import com.spl2.uniconnect.repository.user.AdminProfileRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.service.auth.AuthService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("AuthService - Admin Creation Unit Tests")
class AuthServiceAdminTest {

    @Mock(lenient = true)
    private UserRepository userRepository;

    @Mock(lenient = true)
    private AdminProfileRepository adminProfileRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private AuthService authService;

    @Test
    @DisplayName("Should throw exception when email already exists")
    void testCreateAdminWithDuplicateEmail() {
        // Arrange
        String email = "duplicate@iut-dhaka.edu";

        CreateAdminRequest request = CreateAdminRequest.builder()
                .email(email)
                .password("AdminPassword123")
                .fullName("Duplicate Admin")
                .adminRole("Super Admin")
                .build();

        when(userRepository.existsByEmail(email)).thenReturn(true);

        // Act & Assert
        assertThrows(EmailAlreadyExistsException.class, () -> {
            authService.createAdmin(request);
        });

        // Verify
        verify(userRepository, times(1)).existsByEmail(email);
        verify(userRepository, never()).save(any(User.class));
        verify(adminProfileRepository, never()).save(any(AdminProfile.class));
    }

    @Test
    @DisplayName("Should create admin successfully")
    void testCreateAdminSuccess() {
        // Arrange
        String email = "admin@iut-dhaka.edu";
        String password = "AdminPassword123";

        CreateAdminRequest request = CreateAdminRequest.builder()
                .email(email)
                .password(password)
                .fullName("Test Admin")
                .adminRole("Super Admin")
                .build();

        User savedUser = User.builder()
                .userId(1L)
                .email(email)
                .fullName("Test Admin")
                .role(UserRole.SYSTEM_ADMIN)
                .emailVerified(true)
                .build();

        when(userRepository.existsByEmail(email)).thenReturn(false);
        when(passwordEncoder.encode(password)).thenReturn("hashed_password");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(userRepository.findById(1L)).thenReturn(java.util.Optional.of(savedUser));
        when(adminProfileRepository.save(any(AdminProfile.class)))
                .thenReturn(AdminProfile.builder()
                        .user(savedUser)
                        .adminRole("Super Admin")
                        .build());

        // Act
        RegisterResponse response = authService.createAdmin(request);

        // Assert
        assertNotNull(response);
        assertEquals(1L, response.getUserId());
        assertEquals(email, response.getEmail());
        assertEquals("Test Admin", response.getFullName());

        // Verify all steps were called
        verify(userRepository).existsByEmail(email);
        verify(passwordEncoder).encode(password);
        verify(userRepository).save(any(User.class));
        verify(userRepository).findById(1L);
        verify(adminProfileRepository).save(any(AdminProfile.class));
    }

    @Test
    @DisplayName("Should auto-verify admin email")
    void testCreateAdminEmailIsVerified() {
        // Arrange
        String email = "admin3@iut-dhaka.edu";
        String password = "AdminPassword123";

        CreateAdminRequest request = CreateAdminRequest.builder()
                .email(email)
                .password(password)
                .fullName("Admin 3")
                .adminRole("Super Admin")
                .build();

        User savedUser = User.builder()
                .userId(3L)
                .email(email)
                .fullName("Admin 3")
                .role(UserRole.SYSTEM_ADMIN)
                .emailVerified(true)  // ← Should be verified
                .build();

        when(userRepository.existsByEmail(email)).thenReturn(false);
        when(passwordEncoder.encode(password)).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(userRepository.findById(3L)).thenReturn(java.util.Optional.of(savedUser));
        when(adminProfileRepository.save(any(AdminProfile.class)))
                .thenReturn(AdminProfile.builder()
                        .user(savedUser)
                        .adminRole("Super Admin")
                        .build());

        // Act
        authService.createAdmin(request);

        // Assert
        assertTrue(savedUser.getEmailVerified());
    }

    @Test
    @DisplayName("Should create admin with SYSTEM_ADMIN role")
    void testCreateAdminHasSystemAdminRole() {
        // Arrange
        String email = "admin2@iut-dhaka.edu";
        String password = "AdminPassword123";

        CreateAdminRequest request = CreateAdminRequest.builder()
                .email(email)
                .password(password)
                .fullName("Admin 2")
                .adminRole("Super Admin")
                .build();

        User savedUser = User.builder()
                .userId(2L)
                .email(email)
                .fullName("Admin 2")
                .role(UserRole.SYSTEM_ADMIN)  // ← Must be SYSTEM_ADMIN
                .emailVerified(true)
                .build();

        when(userRepository.existsByEmail(email)).thenReturn(false);
        when(passwordEncoder.encode(password)).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(userRepository.findById(2L)).thenReturn(java.util.Optional.of(savedUser));
        when(adminProfileRepository.save(any(AdminProfile.class)))
                .thenReturn(AdminProfile.builder()
                        .user(savedUser)
                        .adminRole("Super Admin")
                        .build());

        // Act
        RegisterResponse response = authService.createAdmin(request);

        // Assert
        assertNotNull(response);
        assertEquals(UserRole.SYSTEM_ADMIN, savedUser.getRole());
    }

    @Test
    @DisplayName("Should encode password before saving")
    void testCreateAdminPasswordEncoded() {
        // Arrange
        String email = "admin5@iut-dhaka.edu";
        String plainPassword = "AdminPassword123";
        String encodedPassword = "$2a$10$encrypted";

        CreateAdminRequest request = CreateAdminRequest.builder()
                .email(email)
                .password(plainPassword)
                .fullName("Admin 5")
                .adminRole("Super Admin")
                .build();

        User savedUser = User.builder()
                .userId(5L)
                .email(email)
                .fullName("Admin 5")
                .role(UserRole.SYSTEM_ADMIN)
                .emailVerified(true)
                .build();

        when(userRepository.existsByEmail(email)).thenReturn(false);
        when(passwordEncoder.encode(plainPassword)).thenReturn(encodedPassword);
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(userRepository.findById(5L)).thenReturn(java.util.Optional.of(savedUser));
        when(adminProfileRepository.save(any(AdminProfile.class)))
                .thenReturn(AdminProfile.builder()
                        .user(savedUser)
                        .adminRole("Super Admin")
                        .build());

        // Act
        authService.createAdmin(request);

        // Assert
        verify(passwordEncoder).encode(plainPassword);
    }
}