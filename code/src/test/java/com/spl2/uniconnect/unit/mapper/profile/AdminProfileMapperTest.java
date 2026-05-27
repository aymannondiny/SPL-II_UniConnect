package com.spl2.uniconnect.unit.mapper.profile;

import com.spl2.uniconnect.domain.user.AdminProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.user.UpdateAdminProfileRequest;
import com.spl2.uniconnect.dto.response.user.AdminProfileResponse;
import com.spl2.uniconnect.mapper.AdminProfileMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("AdminProfileMapper Unit Tests")
class AdminProfileMapperTest {

    private AdminProfileMapper adminProfileMapper;
    private User testUser;
    private AdminProfile testAdminProfile;

    @BeforeEach
    void setUp() {
        adminProfileMapper = new AdminProfileMapper();

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

        testAdminProfile = AdminProfile.builder()
                .adminId(1L)
                .user(testUser)
                .adminRole("Super Admin")
                .build();
    }

    // =====================================================
    // toResponse TESTS
    // =====================================================

    @Nested
    @DisplayName("toResponse Tests")
    class ToResponseTests {

        @Test
        @DisplayName("Should map all fields correctly")
        void shouldMapAllFields_Correctly() {
            // Act
            AdminProfileResponse response = adminProfileMapper
                    .toResponse(testAdminProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getAdminId()).isEqualTo(1L);
            assertThat(response.getUserId()).isEqualTo(1L);
            assertThat(response.getFullName()).isEqualTo("Admin User");
            assertThat(response.getEmail()).isEqualTo("admin@university.edu");
            assertThat(response.getProfilePhoto())
                    .isEqualTo("https://storage.example.com/admin.jpg");
            assertThat(response.getAdminRole()).isEqualTo("Super Admin");
            assertThat(response.getCreatedAt()).isNotNull();
        }

        @Test
        @DisplayName("Should return null when admin profile is null")
        void shouldReturnNull_WhenAdminProfileIsNull() {
            // Act
            AdminProfileResponse response = adminProfileMapper.toResponse(null);

            // Assert
            assertThat(response).isNull();
        }

        @Test
        @DisplayName("Should map createdAt from User entity")
        void shouldMapCreatedAt_FromUserEntity() {
            // Arrange
            LocalDateTime specificTime = LocalDateTime.of(2024, 1, 15, 10, 30);
            testUser.setCreatedAt(specificTime);

            // Act
            AdminProfileResponse response = adminProfileMapper
                    .toResponse(testAdminProfile);

            // Assert
            assertThat(response.getCreatedAt()).isEqualTo(specificTime);
        }

        @Test
        @DisplayName("Should handle null profile photo correctly")
        void shouldHandleNullProfilePhoto_Correctly() {
            // Arrange
            testUser.setProfilePhoto(null);

            // Act
            AdminProfileResponse response = adminProfileMapper
                    .toResponse(testAdminProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getProfilePhoto()).isNull();
        }
    }

    // =====================================================
    // updateEntityFromRequest TESTS
    // =====================================================

    @Nested
    @DisplayName("updateEntityFromRequest Tests")
    class UpdateEntityFromRequestTests {

        @Test
        @DisplayName("Should update admin role when provided")
        void shouldUpdateAdminRole_WhenProvided() {
            // Arrange
            UpdateAdminProfileRequest request = new UpdateAdminProfileRequest();
            request.setAdminRole("Content Moderator");

            // Act
            adminProfileMapper.updateEntityFromRequest(request, testAdminProfile);

            // Assert
            assertThat(testAdminProfile.getAdminRole()).isEqualTo("Content Moderator");
        }

        @Test
        @DisplayName("Should not update admin role when null")
        void shouldNotUpdateAdminRole_WhenNull() {
            // Arrange
            UpdateAdminProfileRequest request = new UpdateAdminProfileRequest();
            // adminRole is null

            String originalRole = testAdminProfile.getAdminRole();

            // Act
            adminProfileMapper.updateEntityFromRequest(request, testAdminProfile);

            // Assert - original value preserved
            assertThat(testAdminProfile.getAdminRole()).isEqualTo(originalRole);
        }

        @Test
        @DisplayName("Should do nothing when request is null")
        void shouldDoNothing_WhenRequestIsNull() {
            // Arrange
            String originalRole = testAdminProfile.getAdminRole();

            // Act
            adminProfileMapper.updateEntityFromRequest(null, testAdminProfile);

            // Assert - nothing changed
            assertThat(testAdminProfile.getAdminRole()).isEqualTo(originalRole);
        }

        @Test
        @DisplayName("Should do nothing when entity is null")
        void shouldDoNothing_WhenEntityIsNull() {
            // Arrange
            UpdateAdminProfileRequest request = new UpdateAdminProfileRequest();
            request.setAdminRole("New Role");

            // Act & Assert - should not throw
            adminProfileMapper.updateEntityFromRequest(request, null);
        }

        @Test
        @DisplayName("Should not update profilePhoto on entity")
        void shouldNotUpdateProfilePhoto_OnEntity() {
            // Arrange - profilePhoto should be handled by service on User entity
            UpdateAdminProfileRequest request = new UpdateAdminProfileRequest();
            request.setProfilePhoto("https://storage.example.com/new-photo.jpg");

            // Admin profile has no profilePhoto field
            // Just verify it doesn't throw
            adminProfileMapper.updateEntityFromRequest(request, testAdminProfile);

            // Assert - only adminRole is on AdminProfile entity
            assertThat(testAdminProfile.getAdminRole()).isEqualTo("Super Admin");
        }
    }
}