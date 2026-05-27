package com.spl2.uniconnect.unit.service;

import com.spl2.uniconnect.domain.user.AdminProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.user.UpdateAdminProfileRequest;
import com.spl2.uniconnect.dto.response.user.AdminProfileResponse;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.AdminProfileMapper;
import com.spl2.uniconnect.repository.user.AdminProfileRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.service.user.AdminProfileService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.any;

@ExtendWith(MockitoExtension.class)
@DisplayName("AdminProfileService Unit Tests")
class AdminProfileServiceTest {

    @Mock
    private AdminProfileRepository adminProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private AdminProfileMapper adminProfileMapper;

    @InjectMocks
    private AdminProfileService adminProfileService;

    // =====================================================
    // TEST DATA
    // =====================================================

    private User testUser;
    private AdminProfile testAdminProfile;
    private AdminProfileResponse testAdminProfileResponse;
    private UpdateAdminProfileRequest testUpdateRequest;

    @BeforeEach
    void setUp() {
        // Build test user
        testUser = User.builder()
                .userId(1L)
                .email("admin@university.edu")
                .passwordHash("hashedPassword")
                .role(UserRole.SYSTEM_ADMIN)
                .fullName("Admin User")
                .profilePhoto("https://storage.example.com/admin.jpg")
                .emailVerified(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        // Build test admin profile
        testAdminProfile = AdminProfile.builder()
                .adminId(1L)
                .user(testUser)
                .adminRole("Super Admin")
                .build();

        // Build test response
        testAdminProfileResponse = AdminProfileResponse.builder()
                .adminId(1L)
                .userId(1L)
                .fullName("Admin User")
                .email("admin@university.edu")
                .profilePhoto("https://storage.example.com/admin.jpg")
                .adminRole("Super Admin")
                .createdAt(LocalDateTime.now())
                .build();

        // Build test update request
        testUpdateRequest = new UpdateAdminProfileRequest();
        testUpdateRequest.setAdminRole("Content Moderator");
    }

    // =====================================================
    // GET ADMIN PROFILE TESTS
    // =====================================================

    @Nested
    @DisplayName("getAdminProfileByUserId Tests")
    class GetAdminProfileByUserIdTests {

        @Test
        @DisplayName("Should return admin profile when user ID exists")
        void shouldReturnAdminProfile_WhenUserIdExists() {
            // Arrange
            when(adminProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testAdminProfile));
            when(adminProfileMapper.toResponse(testAdminProfile))
                    .thenReturn(testAdminProfileResponse);

            // Act
            AdminProfileResponse result = adminProfileService
                    .getAdminProfileByUserId(1L);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getAdminId()).isEqualTo(1L);
            assertThat(result.getFullName()).isEqualTo("Admin User");
            assertThat(result.getAdminRole()).isEqualTo("Super Admin");

            verify(adminProfileRepository, times(1)).findByUserUserId(1L);
            verify(adminProfileMapper, times(1)).toResponse(testAdminProfile);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when user ID not found")
        void shouldThrowResourceNotFoundException_WhenUserIdNotFound() {
            // Arrange
            when(adminProfileRepository.findByUserUserId(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    adminProfileService.getAdminProfileByUserId(999L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");

            verify(adminProfileMapper, never()).toResponse(any());
        }
    }

    @Nested
    @DisplayName("getAdminProfileByAdminId Tests")
    class GetAdminProfileByAdminIdTests {

        @Test
        @DisplayName("Should return admin profile when admin ID exists")
        void shouldReturnAdminProfile_WhenAdminIdExists() {
            // Arrange
            when(adminProfileRepository.findById(1L))
                    .thenReturn(Optional.of(testAdminProfile));
            when(adminProfileMapper.toResponse(testAdminProfile))
                    .thenReturn(testAdminProfileResponse);

            // Act
            AdminProfileResponse result = adminProfileService
                    .getAdminProfileByAdminId(1L);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getAdminId()).isEqualTo(1L);

            verify(adminProfileRepository, times(1)).findById(1L);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when admin ID not found")
        void shouldThrowResourceNotFoundException_WhenAdminIdNotFound() {
            // Arrange
            when(adminProfileRepository.findById(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    adminProfileService.getAdminProfileByAdminId(999L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");
        }
    }

    // =====================================================
    // GET ALL ADMINS TESTS
    // =====================================================

    @Nested
    @DisplayName("getAllAdmins Tests")
    class GetAllAdminsTests {

        @Test
        @DisplayName("Should return all admin profiles")
        void shouldReturnAllAdminProfiles() {
            // Arrange
            AdminProfile secondAdmin = AdminProfile.builder()
                    .adminId(2L)
                    .user(testUser)
                    .adminRole("Content Moderator")
                    .build();

            AdminProfileResponse secondResponse = AdminProfileResponse.builder()
                    .adminId(2L)
                    .adminRole("Content Moderator")
                    .build();

            when(adminProfileRepository.findAll())
                    .thenReturn(List.of(testAdminProfile, secondAdmin));
            when(adminProfileMapper.toResponse(testAdminProfile))
                    .thenReturn(testAdminProfileResponse);
            when(adminProfileMapper.toResponse(secondAdmin))
                    .thenReturn(secondResponse);

            // Act
            List<AdminProfileResponse> result = adminProfileService.getAllAdmins();

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(2);
            assertThat(result.get(0).getAdminRole()).isEqualTo("Super Admin");
            assertThat(result.get(1).getAdminRole()).isEqualTo("Content Moderator");

            verify(adminProfileRepository, times(1)).findAll();
        }

        @Test
        @DisplayName("Should return empty list when no admins exist")
        void shouldReturnEmptyList_WhenNoAdminsExist() {
            // Arrange
            when(adminProfileRepository.findAll()).thenReturn(List.of());

            // Act
            List<AdminProfileResponse> result = adminProfileService.getAllAdmins();

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).isEmpty();
        }
    }

    // =====================================================
    // GET ADMINS BY ROLE TESTS
    // =====================================================

    @Nested
    @DisplayName("getAdminsByRole Tests")
    class GetAdminsByRoleTests {

        @Test
        @DisplayName("Should return admins by role")
        void shouldReturnAdmins_ByRole() {
            // Arrange
            when(adminProfileRepository.findByAdminRole("Super Admin"))
                    .thenReturn(List.of(testAdminProfile));
            when(adminProfileMapper.toResponse(testAdminProfile))
                    .thenReturn(testAdminProfileResponse);

            // Act
            List<AdminProfileResponse> result = adminProfileService
                    .getAdminsByRole("Super Admin");

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getAdminRole()).isEqualTo("Super Admin");

            verify(adminProfileRepository, times(1)).findByAdminRole("Super Admin");
        }

        @Test
        @DisplayName("Should return empty list when no admins with role")
        void shouldReturnEmptyList_WhenNoAdminsWithRole() {
            // Arrange
            when(adminProfileRepository.findByAdminRole("Unknown Role"))
                    .thenReturn(List.of());

            // Act
            List<AdminProfileResponse> result = adminProfileService
                    .getAdminsByRole("Unknown Role");

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).isEmpty();
        }
    }

    // =====================================================
    // UPDATE ADMIN PROFILE TESTS
    // =====================================================

    @Nested
    @DisplayName("updateAdminProfile Tests")
    class UpdateAdminProfileTests {

        @Test
        @DisplayName("Should update admin profile successfully as owner")
        void shouldUpdateAdminProfile_SuccessfullyAsOwner() {
            // Arrange
            when(adminProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testAdminProfile));
            when(adminProfileRepository.save(any(AdminProfile.class)))
                    .thenReturn(testAdminProfile);
            when(adminProfileMapper.toResponse(testAdminProfile))
                    .thenReturn(testAdminProfileResponse);

            // Act
            AdminProfileResponse result = adminProfileService
                    .updateAdminProfile(1L, testUpdateRequest, 1L, false);

            // Assert
            assertThat(result).isNotNull();

            verify(adminProfileRepository, times(1)).save(testAdminProfile);
            verify(adminProfileMapper, times(1))
                    .updateEntityFromRequest(testUpdateRequest, testAdminProfile);
        }

        @Test
        @DisplayName("Should update admin profile successfully as system admin")
        void shouldUpdateAdminProfile_SuccessfullyAsSystemAdmin() {
            // Arrange
            when(adminProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testAdminProfile));
            when(adminProfileRepository.save(any(AdminProfile.class)))
                    .thenReturn(testAdminProfile);
            when(adminProfileMapper.toResponse(testAdminProfile))
                    .thenReturn(testAdminProfileResponse);

            // Act - different user but isSystemAdmin = true
            AdminProfileResponse result = adminProfileService
                    .updateAdminProfile(1L, testUpdateRequest, 2L, true);

            // Assert
            assertThat(result).isNotNull();

            verify(adminProfileRepository, times(1)).save(testAdminProfile);
        }

        @Test
        @DisplayName("Should throw ForbiddenException when user is not owner and not system admin")
        void shouldThrowForbiddenException_WhenNotOwnerAndNotSystemAdmin() {
            // Act & Assert
            assertThatThrownBy(() ->
                    adminProfileService.updateAdminProfile(
                            1L, testUpdateRequest, 2L, false))
                    .isInstanceOf(ForbiddenException.class)
                    .hasMessageContaining("not authorized");

            verify(adminProfileRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when profile not found")
        void shouldThrowResourceNotFoundException_WhenProfileNotFound() {
            // Arrange
            when(adminProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    adminProfileService.updateAdminProfile(
                            1L, testUpdateRequest, 1L, false))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("1");

            verify(adminProfileRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should update profile photo on User entity")
        void shouldUpdateProfilePhoto_OnUserEntity() {
            // Arrange
            testUpdateRequest.setProfilePhoto(
                    "https://storage.example.com/new-admin-photo.jpg");

            when(adminProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testAdminProfile));
            when(userRepository.save(any(User.class)))
                    .thenReturn(testUser);
            when(adminProfileRepository.save(any(AdminProfile.class)))
                    .thenReturn(testAdminProfile);
            when(adminProfileMapper.toResponse(testAdminProfile))
                    .thenReturn(testAdminProfileResponse);

            // Act
            adminProfileService.updateAdminProfile(1L, testUpdateRequest, 1L, false);

            // Assert
            verify(userRepository, times(1)).save(testUser);
            assertThat(testUser.getProfilePhoto())
                    .isEqualTo("https://storage.example.com/new-admin-photo.jpg");
        }
    }

    // =====================================================
    // ANALYTICS TESTS
    // =====================================================

    @Nested
    @DisplayName("Analytics Tests")
    class AnalyticsTests {

        @Test
        @DisplayName("Should return all distinct admin roles")
        void shouldReturnAllDistinctAdminRoles() {
            // Arrange
            List<String> roles = List.of(
                    "Super Admin",
                    "Content Moderator",
                    "User Manager"
            );

            when(adminProfileRepository.findAllDistinctRoles())
                    .thenReturn(roles);

            // Act
            List<String> result = adminProfileService.getAllAdminRoles();

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(3);
            assertThat(result).contains(
                    "Super Admin",
                    "Content Moderator",
                    "User Manager"
            );

            verify(adminProfileRepository, times(1)).findAllDistinctRoles();
        }

        @Test
        @DisplayName("Should return empty list when no roles exist")
        void shouldReturnEmptyList_WhenNoRolesExist() {
            // Arrange
            when(adminProfileRepository.findAllDistinctRoles())
                    .thenReturn(List.of());

            // Act
            List<String> result = adminProfileService.getAllAdminRoles();

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).isEmpty();
        }
    }
}