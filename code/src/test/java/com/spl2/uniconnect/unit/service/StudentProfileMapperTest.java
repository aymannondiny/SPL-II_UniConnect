package com.spl2.uniconnect.unit.service;

import com.spl2.uniconnect.domain.academic.DegreeLevel;
import com.spl2.uniconnect.domain.academic.Department;
import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.user.StudentProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.user.UpdateStudentProfileRequest;
import com.spl2.uniconnect.dto.response.user.StudentProfileResponse;
import com.spl2.uniconnect.mapper.StudentProfileMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("StudentProfileMapper Unit Tests")
class StudentProfileMapperTest {

    private StudentProfileMapper studentProfileMapper;
    private User testUser;
    private Department testDepartment;
    private Programme testProgramme;
    private DegreeLevel testDegreeLevel;
    private StudentProfile testStudentProfile;

    @BeforeEach
    void setUp() {
        studentProfileMapper = new StudentProfileMapper();

        testUser = User.builder()
                .userId(1L)
                .email("john.doe@university.edu")
                .passwordHash("hashedPassword")
                .role(UserRole.STUDENT)
                .fullName("John Doe")
                .profilePhoto("https://storage.example.com/john.jpg")
                .emailVerified(true)
                .createdAt(LocalDateTime.now())
                .build();

        testDepartment = Department.builder()
                .departmentId(1L)
                .departmentName("Computer Science")
                .departmentCode("CS")
                .build();

        testProgramme = Programme.builder()
                .programmeId(1L)
                .department(testDepartment)
                .programmeName("Software Engineering")
                .programmeCode("SE")
                .build();

        testDegreeLevel = DegreeLevel.builder()
                .degreeLevelId(1L)
                .degreeName("Undergraduate")
                .minYears(3)
                .maxYears(5)
                .build();

        testStudentProfile = StudentProfile.builder()
                .studentId(1L)
                .user(testUser)
                .programme(testProgramme)
                .degreeLevel(testDegreeLevel)
                .yearOfStudy(3)
                .expectedGraduationYear(2025)
                .bio("Passionate software developer")
                .lookingForTeammates(true)
                .openToMentorship(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
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
            StudentProfileResponse response = studentProfileMapper
                    .toResponse(testStudentProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getStudentId()).isEqualTo(1L);
            assertThat(response.getUserId()).isEqualTo(1L);
            assertThat(response.getFullName()).isEqualTo("John Doe");
            assertThat(response.getEmail()).isEqualTo("john.doe@university.edu");
            assertThat(response.getProfilePhoto())
                    .isEqualTo("https://storage.example.com/john.jpg");
            assertThat(response.getYearOfStudy()).isEqualTo(3);
            assertThat(response.getProgrammeId()).isEqualTo(1L);
            assertThat(response.getProgrammeName()).isEqualTo("Software Engineering");
            assertThat(response.getProgrammeCode()).isEqualTo("SE");
            assertThat(response.getDepartmentId()).isEqualTo(1L);
            assertThat(response.getDepartmentName()).isEqualTo("Computer Science");
            assertThat(response.getDegreeLevelId()).isEqualTo(1L);
            assertThat(response.getDegreeName()).isEqualTo("Undergraduate");
            assertThat(response.getBio()).isEqualTo("Passionate software developer");
            assertThat(response.getExpectedGraduationYear()).isEqualTo(2025);
            assertThat(response.getLookingForTeammates()).isTrue();
            assertThat(response.getOpenToMentorship()).isFalse();
            assertThat(response.getCreatedAt()).isNotNull();
            assertThat(response.getUpdatedAt()).isNotNull();
        }

        @Test
        @DisplayName("Should return null when student profile is null")
        void shouldReturnNull_WhenStudentProfileIsNull() {
            // Act
            StudentProfileResponse response = studentProfileMapper.toResponse(null);

            // Assert
            assertThat(response).isNull();
        }

        @Test
        @DisplayName("Should handle null programme correctly")
        void shouldHandleNullProgramme_Correctly() {
            // Arrange
            testStudentProfile.setProgramme(null);

            // Act
            StudentProfileResponse response = studentProfileMapper
                    .toResponse(testStudentProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getProgrammeId()).isNull();
            assertThat(response.getProgrammeName()).isNull();
            assertThat(response.getProgrammeCode()).isNull();
            assertThat(response.getDepartmentId()).isNull();
            assertThat(response.getDepartmentName()).isNull();
        }

        @Test
        @DisplayName("Should handle null degree level correctly")
        void shouldHandleNullDegreeLevel_Correctly() {
            // Arrange
            testStudentProfile.setDegreeLevel(null);

            // Act
            StudentProfileResponse response = studentProfileMapper
                    .toResponse(testStudentProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getDegreeLevelId()).isNull();
            assertThat(response.getDegreeName()).isNull();
        }

        @Test
        @DisplayName("Should handle null optional fields correctly")
        void shouldHandleNullOptionalFields_Correctly() {
            // Arrange
            testStudentProfile.setBio(null);
            testStudentProfile.setExpectedGraduationYear(null);

            // Act
            StudentProfileResponse response = studentProfileMapper
                    .toResponse(testStudentProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getBio()).isNull();
            assertThat(response.getExpectedGraduationYear()).isNull();
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
            UpdateStudentProfileRequest request = new UpdateStudentProfileRequest();
            request.setYearOfStudy(4);
            request.setProgrammeId(1L);
            request.setDegreeLevelId(1L);
            request.setBio("Updated bio - final year student");
            request.setExpectedGraduationYear(2025);
            request.setLookingForTeammates(false);
            request.setOpenToMentorship(true);

            // Act
            studentProfileMapper.updateEntityFromRequest(request, testStudentProfile);

            // Assert
            assertThat(testStudentProfile.getYearOfStudy()).isEqualTo(4);
            assertThat(testStudentProfile.getBio())
                    .isEqualTo("Updated bio - final year student");
            assertThat(testStudentProfile.getExpectedGraduationYear()).isEqualTo(2025);
            assertThat(testStudentProfile.getLookingForTeammates()).isFalse();
            assertThat(testStudentProfile.getOpenToMentorship()).isTrue();
        }

        @Test
        @DisplayName("Should not update fields when request values are null")
        void shouldNotUpdateFields_WhenRequestValuesAreNull() {
            // Arrange - empty request (all nulls)
            UpdateStudentProfileRequest request = new UpdateStudentProfileRequest();

            Integer originalYear = testStudentProfile.getYearOfStudy();
            String originalBio = testStudentProfile.getBio();
            Boolean originalTeammates = testStudentProfile.getLookingForTeammates();

            // Act
            studentProfileMapper.updateEntityFromRequest(request, testStudentProfile);

            // Assert - original values preserved
            assertThat(testStudentProfile.getYearOfStudy()).isEqualTo(originalYear);
            assertThat(testStudentProfile.getBio()).isEqualTo(originalBio);
            assertThat(testStudentProfile.getLookingForTeammates())
                    .isEqualTo(originalTeammates);
        }

        @Test
        @DisplayName("Should do nothing when request is null")
        void shouldDoNothing_WhenRequestIsNull() {
            // Arrange
            Integer originalYear = testStudentProfile.getYearOfStudy();

            // Act
            studentProfileMapper.updateEntityFromRequest(null, testStudentProfile);

            // Assert - nothing changed
            assertThat(testStudentProfile.getYearOfStudy()).isEqualTo(originalYear);
        }

        @Test
        @DisplayName("Should do nothing when entity is null")
        void shouldDoNothing_WhenEntityIsNull() {
            // Arrange
            UpdateStudentProfileRequest request = new UpdateStudentProfileRequest();
            request.setYearOfStudy(4);

            // Act & Assert - should not throw
            studentProfileMapper.updateEntityFromRequest(request, null);
        }

        @Test
        @DisplayName("Should update only partial fields when some are null")
        void shouldUpdateOnlyPartialFields_WhenSomeAreNull() {
            // Arrange - only update year and bio
            UpdateStudentProfileRequest request = new UpdateStudentProfileRequest();
            request.setYearOfStudy(4);
            request.setBio("Partial update");
            // programmeId, degreeLevelId, etc. are null

            Integer originalGradYear = testStudentProfile.getExpectedGraduationYear();
            Boolean originalTeammates = testStudentProfile.getLookingForTeammates();

            // Act
            studentProfileMapper.updateEntityFromRequest(request, testStudentProfile);

            // Assert
            assertThat(testStudentProfile.getYearOfStudy()).isEqualTo(4);
            assertThat(testStudentProfile.getBio()).isEqualTo("Partial update");
            // These should remain unchanged
            assertThat(testStudentProfile.getExpectedGraduationYear())
                    .isEqualTo(originalGradYear);
            assertThat(testStudentProfile.getLookingForTeammates())
                    .isEqualTo(originalTeammates);
        }
    }
}