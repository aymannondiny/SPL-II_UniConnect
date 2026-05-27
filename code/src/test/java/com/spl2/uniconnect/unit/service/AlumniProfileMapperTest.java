package com.spl2.uniconnect.unit.service;

import com.spl2.uniconnect.domain.academic.DegreeLevel;
import com.spl2.uniconnect.domain.academic.Department;
import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.user.AlumniProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.user.UpdateAlumniProfileRequest;
import com.spl2.uniconnect.dto.response.user.AlumniProfileResponse;
import com.spl2.uniconnect.mapper.AlumniProfileMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("AlumniProfileMapper Unit Tests")
class AlumniProfileMapperTest {

    private AlumniProfileMapper alumniProfileMapper;
    private User testUser;
    private Department testDepartment;
    private Programme testProgramme;
    private DegreeLevel testDegreeLevel;
    private AlumniProfile testAlumniProfile;

    @BeforeEach
    void setUp() {
        alumniProfileMapper = new AlumniProfileMapper();

        testUser = User.builder()
                .userId(1L)
                .email("jane.smith@university.edu")
                .passwordHash("hashedPassword")
                .role(UserRole.ALUMNI)
                .fullName("Jane Smith")
                .profilePhoto("https://storage.example.com/jane.jpg")
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

        testAlumniProfile = AlumniProfile.builder()
                .alumniId(1L)
                .user(testUser)
                .graduationYear(2020)
                .programme(testProgramme)
                .degreeLevel(testDegreeLevel)
                .currentCompany("Google")
                .currentPosition("Software Engineer")
                .industry("Technology")
                .careerBackground("5 years of experience")
                .linkedinUrl("https://linkedin.com/in/janesmith")
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
            AlumniProfileResponse response = alumniProfileMapper
                    .toResponse(testAlumniProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getAlumniId()).isEqualTo(1L);
            assertThat(response.getUserId()).isEqualTo(1L);
            assertThat(response.getFullName()).isEqualTo("Jane Smith");
            assertThat(response.getEmail()).isEqualTo("jane.smith@university.edu");
            assertThat(response.getProfilePhoto())
                    .isEqualTo("https://storage.example.com/jane.jpg");
            assertThat(response.getGraduationYear()).isEqualTo(2020);
            assertThat(response.getProgrammeId()).isEqualTo(1L);
            assertThat(response.getProgrammeName()).isEqualTo("Software Engineering");
            assertThat(response.getProgrammeCode()).isEqualTo("SE");
            assertThat(response.getDepartmentId()).isEqualTo(1L);
            assertThat(response.getDepartmentName()).isEqualTo("Computer Science");
            assertThat(response.getDegreeLevelId()).isEqualTo(1L);
            assertThat(response.getDegreeName()).isEqualTo("Undergraduate");
            assertThat(response.getCurrentCompany()).isEqualTo("Google");
            assertThat(response.getCurrentPosition()).isEqualTo("Software Engineer");
            assertThat(response.getIndustry()).isEqualTo("Technology");
            assertThat(response.getCareerBackground()).isEqualTo("5 years of experience");
            assertThat(response.getLinkedinUrl())
                    .isEqualTo("https://linkedin.com/in/janesmith");
            assertThat(response.getCreatedAt()).isNotNull();
            assertThat(response.getUpdatedAt()).isNotNull();
        }

        @Test
        @DisplayName("Should return null when alumni profile is null")
        void shouldReturnNull_WhenAlumniProfileIsNull() {
            // Act
            AlumniProfileResponse response = alumniProfileMapper.toResponse(null);

            // Assert
            assertThat(response).isNull();
        }

        @Test
        @DisplayName("Should handle null programme correctly")
        void shouldHandleNullProgramme_Correctly() {
            // Arrange
            testAlumniProfile.setProgramme(null);

            // Act
            AlumniProfileResponse response = alumniProfileMapper
                    .toResponse(testAlumniProfile);

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
            testAlumniProfile.setDegreeLevel(null);

            // Act
            AlumniProfileResponse response = alumniProfileMapper
                    .toResponse(testAlumniProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getDegreeLevelId()).isNull();
            assertThat(response.getDegreeName()).isNull();
        }

        @Test
        @DisplayName("Should handle null optional fields correctly")
        void shouldHandleNullOptionalFields_Correctly() {
            // Arrange
            testAlumniProfile.setCurrentCompany(null);
            testAlumniProfile.setCurrentPosition(null);
            testAlumniProfile.setIndustry(null);
            testAlumniProfile.setCareerBackground(null);
            testAlumniProfile.setLinkedinUrl(null);

            // Act
            AlumniProfileResponse response = alumniProfileMapper
                    .toResponse(testAlumniProfile);

            // Assert
            assertThat(response).isNotNull();
            assertThat(response.getCurrentCompany()).isNull();
            assertThat(response.getCurrentPosition()).isNull();
            assertThat(response.getIndustry()).isNull();
            assertThat(response.getCareerBackground()).isNull();
            assertThat(response.getLinkedinUrl()).isNull();
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
            UpdateAlumniProfileRequest request = new UpdateAlumniProfileRequest();
            request.setGraduationYear(2021);
            request.setProgrammeId(1L);
            request.setDegreeLevelId(1L);
            request.setCurrentCompany("Microsoft");
            request.setCurrentPosition("Senior Engineer");
            request.setIndustry("Software");
            request.setCareerBackground("Updated career background");
            request.setLinkedinUrl("https://linkedin.com/in/updated");

            // Act
            alumniProfileMapper.updateEntityFromRequest(request, testAlumniProfile);

            // Assert
            assertThat(testAlumniProfile.getGraduationYear()).isEqualTo(2021);
            assertThat(testAlumniProfile.getCurrentCompany()).isEqualTo("Microsoft");
            assertThat(testAlumniProfile.getCurrentPosition()).isEqualTo("Senior Engineer");
            assertThat(testAlumniProfile.getIndustry()).isEqualTo("Software");
            assertThat(testAlumniProfile.getCareerBackground())
                    .isEqualTo("Updated career background");
            assertThat(testAlumniProfile.getLinkedinUrl())
                    .isEqualTo("https://linkedin.com/in/updated");
        }

        @Test
        @DisplayName("Should not update fields when request values are null")
        void shouldNotUpdateFields_WhenRequestValuesAreNull() {
            // Arrange - empty request (all nulls)
            UpdateAlumniProfileRequest request = new UpdateAlumniProfileRequest();

            Integer originalYear = testAlumniProfile.getGraduationYear();
            String originalCompany = testAlumniProfile.getCurrentCompany();
            String originalIndustry = testAlumniProfile.getIndustry();

            // Act
            alumniProfileMapper.updateEntityFromRequest(request, testAlumniProfile);

            // Assert - original values preserved
            assertThat(testAlumniProfile.getGraduationYear()).isEqualTo(originalYear);
            assertThat(testAlumniProfile.getCurrentCompany()).isEqualTo(originalCompany);
            assertThat(testAlumniProfile.getIndustry()).isEqualTo(originalIndustry);
        }

        @Test
        @DisplayName("Should do nothing when request is null")
        void shouldDoNothing_WhenRequestIsNull() {
            // Arrange
            Integer originalYear = testAlumniProfile.getGraduationYear();

            // Act
            alumniProfileMapper.updateEntityFromRequest(null, testAlumniProfile);

            // Assert - nothing changed
            assertThat(testAlumniProfile.getGraduationYear()).isEqualTo(originalYear);
        }

        @Test
        @DisplayName("Should do nothing when entity is null")
        void shouldDoNothing_WhenEntityIsNull() {
            // Arrange
            UpdateAlumniProfileRequest request = new UpdateAlumniProfileRequest();
            request.setGraduationYear(2021);

            // Act & Assert - should not throw
            alumniProfileMapper.updateEntityFromRequest(request, null);
        }

        @Test
        @DisplayName("Should update only partial fields when some are null")
        void shouldUpdateOnlyPartialFields_WhenSomeAreNull() {
            // Arrange - only update year and company
            UpdateAlumniProfileRequest request = new UpdateAlumniProfileRequest();
            request.setGraduationYear(2021);
            request.setCurrentCompany("Facebook");
            // other fields are null

            String originalPosition = testAlumniProfile.getCurrentPosition();
            String originalIndustry = testAlumniProfile.getIndustry();

            // Act
            alumniProfileMapper.updateEntityFromRequest(request, testAlumniProfile);

            // Assert
            assertThat(testAlumniProfile.getGraduationYear()).isEqualTo(2021);
            assertThat(testAlumniProfile.getCurrentCompany()).isEqualTo("Facebook");
            // These should remain unchanged
            assertThat(testAlumniProfile.getCurrentPosition()).isEqualTo(originalPosition);
            assertThat(testAlumniProfile.getIndustry()).isEqualTo(originalIndustry);
        }
    }
}