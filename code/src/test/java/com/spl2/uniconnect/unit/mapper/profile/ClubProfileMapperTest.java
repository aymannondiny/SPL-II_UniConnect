package com.spl2.uniconnect.unit.mapper.profile;

import com.spl2.uniconnect.domain.academic.Department;
import com.spl2.uniconnect.domain.user.ClubProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.user.UpdateClubProfileRequest;
import com.spl2.uniconnect.dto.response.user.ClubProfileResponse;
import com.spl2.uniconnect.mapper.ClubProfileMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("ClubProfileMapper Unit Tests")
class ClubProfileMapperTest {

    private ClubProfileMapper clubProfileMapper;
    private User testUser;
    private Department testDepartment;
    private ClubProfile testClubProfile;

    @BeforeEach
    void setUp() {
        clubProfileMapper = new ClubProfileMapper();

        testUser = User.builder()
                .userId(1L)
                .email("robotics@university.edu")
                .passwordHash("hashedPassword")
                .role(UserRole.CLUB_ADMIN)
                .fullName("Robotics Club")
                .profilePhoto("https://storage.university.edu/photos/robotics.png")
                .emailVerified(true)
                .createdAt(LocalDateTime.now())
                .build();

        testDepartment = Department.builder()
                .departmentId(1L)
                .departmentName("Engineering")
                .departmentCode("ENG")
                .build();

        testClubProfile = ClubProfile.builder()
                .clubId(1L)
                .user(testUser)
                .clubName("Robotics Club")
                .description("A club for robotics enthusiasts")
                .category("Tech")
                .department(testDepartment)
                .foundedYear(2020)
                .meetingSchedule("Every Monday 6PM")
                .contactEmail("robotics@university.edu")
                .websiteUrl("https://robotics.university.edu")
                .clubLogo("https://storage.university.edu/logos/robotics.png")
                .createdAt(LocalDateTime.now())
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
            ClubProfileResponse response = clubProfileMapper.toResponse(testClubProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getClubId()).isEqualTo(1L);
            assertThat(response.getUserId()).isEqualTo(1L);
            assertThat(response.getFullName()).isEqualTo("Robotics Club");
            assertThat(response.getProfilePhoto())
                    .isEqualTo("https://storage.university.edu/photos/robotics.png");
            assertThat(response.getClubName()).isEqualTo("Robotics Club");
            assertThat(response.getDescription())
                    .isEqualTo("A club for robotics enthusiasts");
            assertThat(response.getCategory()).isEqualTo("Tech");
            assertThat(response.getFoundedYear()).isEqualTo(2020);
            assertThat(response.getMeetingSchedule()).isEqualTo("Every Monday 6PM");
            assertThat(response.getContactEmail())
                    .isEqualTo("robotics@university.edu");
            assertThat(response.getWebsiteUrl())
                    .isEqualTo("https://robotics.university.edu");
            assertThat(response.getClubLogo())
                    .isEqualTo("https://storage.university.edu/logos/robotics.png");
            assertThat(response.getDepartmentId()).isEqualTo(1L);
            assertThat(response.getDepartmentName()).isEqualTo("Engineering");
            assertThat(response.getCreatedAt()).isNotNull();
        }

        @Test
        @DisplayName("Should return null when club profile is null")
        void shouldReturnNull_WhenClubProfileIsNull() {
            // Act
            ClubProfileResponse response = clubProfileMapper.toResponse(null);

            // Assert
            assertThat(response).isNull();
        }

        @Test
        @DisplayName("Should handle null department correctly")
        void shouldHandleNullDepartment_Correctly() {
            // Arrange
            testClubProfile.setDepartment(null);

            // Act
            ClubProfileResponse response = clubProfileMapper.toResponse(testClubProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getDepartmentId()).isNull();
            assertThat(response.getDepartmentName()).isNull();
        }

        @Test
        @DisplayName("Should handle null optional fields correctly")
        void shouldHandleNullOptionalFields_Correctly() {
            // Arrange
            testClubProfile.setFoundedYear(null);
            testClubProfile.setMeetingSchedule(null);
            testClubProfile.setContactEmail(null);
            testClubProfile.setWebsiteUrl(null);
            testClubProfile.setClubLogo(null);

            // Act
            ClubProfileResponse response = clubProfileMapper.toResponse(testClubProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getFoundedYear()).isNull();
            assertThat(response.getMeetingSchedule()).isNull();
            assertThat(response.getContactEmail()).isNull();
            assertThat(response.getWebsiteUrl()).isNull();
            assertThat(response.getClubLogo()).isNull();
        }
    }

    // =====================================================
    // updateEntityFromRequest TESTS
    // =====================================================

    @Nested
    @DisplayName("updateEntityFromRequest Tests")
    class UpdateEntityFromRequestTests {

        @Test
        @DisplayName("Should update all provided fields")
        void shouldUpdateAllProvidedFields() {
            // Arrange
            UpdateClubProfileRequest request = new UpdateClubProfileRequest();
            request.setClubName("Updated Club Name");
            request.setDescription("Updated description for the club");
            request.setCategory("Sports");
            request.setFoundedYear(2021);
            request.setMeetingSchedule("Every Friday 5PM");
            request.setContactEmail("updated@university.edu");
            request.setWebsiteUrl("https://updated.university.edu");
            request.setClubLogo("https://storage.university.edu/logos/updated.png");

            // Act
            clubProfileMapper.updateEntityFromRequest(request, testClubProfile);

            // Assert
            assertThat(testClubProfile.getClubName()).isEqualTo("Updated Club Name");
            assertThat(testClubProfile.getDescription())
                    .isEqualTo("Updated description for the club");
            assertThat(testClubProfile.getCategory()).isEqualTo("Sports");
            assertThat(testClubProfile.getFoundedYear()).isEqualTo(2021);
            assertThat(testClubProfile.getMeetingSchedule())
                    .isEqualTo("Every Friday 5PM");
            assertThat(testClubProfile.getContactEmail())
                    .isEqualTo("updated@university.edu");
            assertThat(testClubProfile.getWebsiteUrl())
                    .isEqualTo("https://updated.university.edu");
            assertThat(testClubProfile.getClubLogo())
                    .isEqualTo("https://storage.university.edu/logos/updated.png");
        }

        @Test
        @DisplayName("Should not update fields when request values are null")
        void shouldNotUpdateFields_WhenRequestValuesAreNull() {
            // Arrange - empty request (all nulls)
            UpdateClubProfileRequest request = new UpdateClubProfileRequest();

            String originalName = testClubProfile.getClubName();
            String originalDescription = testClubProfile.getDescription();
            String originalCategory = testClubProfile.getCategory();

            // Act
            clubProfileMapper.updateEntityFromRequest(request, testClubProfile);

            // Assert - original values preserved
            assertThat(testClubProfile.getClubName()).isEqualTo(originalName);
            assertThat(testClubProfile.getDescription()).isEqualTo(originalDescription);
            assertThat(testClubProfile.getCategory()).isEqualTo(originalCategory);
        }

        @Test
        @DisplayName("Should do nothing when request is null")
        void shouldDoNothing_WhenRequestIsNull() {
            // Arrange
            String originalName = testClubProfile.getClubName();

            // Act
            clubProfileMapper.updateEntityFromRequest(null, testClubProfile);

            // Assert - nothing changed
            assertThat(testClubProfile.getClubName()).isEqualTo(originalName);
        }

        @Test
        @DisplayName("Should do nothing when entity is null")
        void shouldDoNothing_WhenEntityIsNull() {
            // Arrange
            UpdateClubProfileRequest request = new UpdateClubProfileRequest();
            request.setClubName("New Name");

            // Act & Assert - should not throw
            clubProfileMapper.updateEntityFromRequest(request, null);
        }

        @Test
        @DisplayName("Should update only partial fields when some are null")
        void shouldUpdateOnlyPartialFields_WhenSomeAreNull() {
            // Arrange - only update name and category
            UpdateClubProfileRequest request = new UpdateClubProfileRequest();
            request.setClubName("Partial Update Club");
            request.setCategory("Arts");
            // description, foundedYear, etc. are null

            String originalDescription = testClubProfile.getDescription();
            Integer originalFoundedYear = testClubProfile.getFoundedYear();

            // Act
            clubProfileMapper.updateEntityFromRequest(request, testClubProfile);

            // Assert
            assertThat(testClubProfile.getClubName()).isEqualTo("Partial Update Club");
            assertThat(testClubProfile.getCategory()).isEqualTo("Arts");
            // These should remain unchanged
            assertThat(testClubProfile.getDescription()).isEqualTo(originalDescription);
            assertThat(testClubProfile.getFoundedYear()).isEqualTo(originalFoundedYear);
        }
    }
}