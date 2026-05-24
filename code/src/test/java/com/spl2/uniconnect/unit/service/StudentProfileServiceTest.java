package com.spl2.uniconnect.unit.service;

import com.spl2.uniconnect.domain.academic.DegreeLevel;
import com.spl2.uniconnect.domain.academic.Department;
import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.user.StudentProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.user.UpdateStudentProfileRequest;
import com.spl2.uniconnect.dto.response.user.StudentProfileResponse;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.StudentProfileMapper;
import com.spl2.uniconnect.repository.academic.DegreeLevelRepository;
import com.spl2.uniconnect.repository.academic.ProgrammeRepository;
import com.spl2.uniconnect.repository.user.StudentProfileRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.service.user.StudentProfileService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

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
@DisplayName("StudentProfileService Unit Tests")
class StudentProfileServiceTest {

    @Mock
    private StudentProfileRepository studentProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ProgrammeRepository programmeRepository;

    @Mock
    private DegreeLevelRepository degreeLevelRepository;

    @Mock
    private StudentProfileMapper studentProfileMapper;

    @InjectMocks
    private StudentProfileService studentProfileService;

    // =====================================================
    // TEST DATA
    // =====================================================

    private User testUser;
    private Department testDepartment;
    private Programme testProgramme;
    private DegreeLevel testDegreeLevel;
    private StudentProfile testStudentProfile;
    private StudentProfileResponse testStudentProfileResponse;
    private UpdateStudentProfileRequest testUpdateRequest;

    @BeforeEach
    void setUp() {
        // Build test user
        testUser = User.builder()
                .userId(1L)
                .email("john.doe@university.edu")
                .passwordHash("hashedPassword")
                .role(UserRole.STUDENT)
                .fullName("John Doe")
                .emailVerified(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        // Build test department
        testDepartment = Department.builder()
                .departmentId(1L)
                .departmentName("Computer Science")
                .departmentCode("CS")
                .description("Computer Science Department")
                .createdAt(LocalDateTime.now())
                .build();

        // Build test programme
        testProgramme = Programme.builder()
                .programmeId(1L)
                .department(testDepartment)
                .programmeName("Software Engineering")
                .programmeCode("SE")
                .description("Software Engineering Programme")
                .createdAt(LocalDateTime.now())
                .build();

        // Build test degree level
        testDegreeLevel = DegreeLevel.builder()
                .degreeLevelId(1L)
                .degreeName("Undergraduate")
                .minYears(3)
                .maxYears(5)
                .description("Bachelor's degree")
                .build();

        // Build test student profile
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

        // Build test response
        testStudentProfileResponse = StudentProfileResponse.builder()
                .studentId(1L)
                .userId(1L)
                .fullName("John Doe")
                .email("john.doe@university.edu")
                .yearOfStudy(3)
                .programmeId(1L)
                .programmeName("Software Engineering")
                .programmeCode("SE")
                .departmentId(1L)
                .departmentName("Computer Science")
                .degreeLevelId(1L)
                .degreeName("Undergraduate")
                .bio("Passionate software developer")
                .expectedGraduationYear(2025)
                .lookingForTeammates(true)
                .openToMentorship(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        // Build test update request
        testUpdateRequest = new UpdateStudentProfileRequest();
        testUpdateRequest.setYearOfStudy(4);
        testUpdateRequest.setProgrammeId(1L);
        testUpdateRequest.setDegreeLevelId(1L);
        testUpdateRequest.setBio("Updated bio - final year student");
        testUpdateRequest.setExpectedGraduationYear(2025);
    }

    // =====================================================
    // GET STUDENT PROFILE TESTS
    // =====================================================

    @Nested
    @DisplayName("getStudentProfileByUserId Tests")
    class GetStudentProfileByUserIdTests {

        @Test
        @DisplayName("Should return student profile when user ID exists")
        void shouldReturnStudentProfile_WhenUserIdExists() {
            // Arrange
            when(studentProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testStudentProfile));
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            StudentProfileResponse result = studentProfileService
                    .getStudentProfileByUserId(1L);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getStudentId()).isEqualTo(1L);
            assertThat(result.getFullName()).isEqualTo("John Doe");
            assertThat(result.getYearOfStudy()).isEqualTo(3);

            verify(studentProfileRepository, times(1)).findByUserUserId(1L);
            verify(studentProfileMapper, times(1)).toResponse(testStudentProfile);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when user ID not found")
        void shouldThrowResourceNotFoundException_WhenUserIdNotFound() {
            // Arrange
            when(studentProfileRepository.findByUserUserId(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    studentProfileService.getStudentProfileByUserId(999L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");

            verify(studentProfileMapper, never()).toResponse(any());
        }
    }

    @Nested
    @DisplayName("getStudentProfileByStudentId Tests")
    class GetStudentProfileByStudentIdTests {

        @Test
        @DisplayName("Should return student profile when student ID exists")
        void shouldReturnStudentProfile_WhenStudentIdExists() {
            // Arrange
            when(studentProfileRepository.findById(1L))
                    .thenReturn(Optional.of(testStudentProfile));
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            StudentProfileResponse result = studentProfileService
                    .getStudentProfileByStudentId(1L);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getStudentId()).isEqualTo(1L);

            verify(studentProfileRepository, times(1)).findById(1L);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when student ID not found")
        void shouldThrowResourceNotFoundException_WhenStudentIdNotFound() {
            // Arrange
            when(studentProfileRepository.findById(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    studentProfileService.getStudentProfileByStudentId(999L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");
        }
    }

    // =====================================================
    // UPDATE STUDENT PROFILE TESTS
    // =====================================================

    @Nested
    @DisplayName("updateStudentProfile Tests")
    class UpdateStudentProfileTests {

        @Test
        @DisplayName("Should update student profile successfully")
        void shouldUpdateStudentProfile_Successfully() {
            // Arrange
            when(studentProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testStudentProfile));
            when(programmeRepository.findById(1L))
                    .thenReturn(Optional.of(testProgramme));
            when(degreeLevelRepository.findById(1L))
                    .thenReturn(Optional.of(testDegreeLevel));
            when(studentProfileRepository.save(any(StudentProfile.class)))
                    .thenReturn(testStudentProfile);
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            StudentProfileResponse result = studentProfileService
                    .updateStudentProfile(1L, testUpdateRequest, 1L);

            // Assert
            assertThat(result).isNotNull();

            verify(studentProfileRepository, times(1)).save(testStudentProfile);
            verify(studentProfileMapper, times(1))
                    .updateEntityFromRequest(testUpdateRequest, testStudentProfile);
        }

        @Test
        @DisplayName("Should throw ForbiddenException when user is not owner")
        void shouldThrowForbiddenException_WhenUserIsNotOwner() {
            // Act & Assert
            assertThatThrownBy(() ->
                    studentProfileService.updateStudentProfile(1L, testUpdateRequest, 2L))
                    .isInstanceOf(ForbiddenException.class)
                    .hasMessageContaining("not authorized");

            verify(studentProfileRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when profile not found")
        void shouldThrowResourceNotFoundException_WhenProfileNotFound() {
            // Arrange
            when(studentProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    studentProfileService.updateStudentProfile(1L, testUpdateRequest, 1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("1");

            verify(studentProfileRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should update programme when programmeId provided")
        void shouldUpdateProgramme_WhenProgrammeIdProvided() {
            // Arrange
            Programme newProgramme = Programme.builder()
                    .programmeId(2L)
                    .programmeName("Data Science")
                    .build();

            testUpdateRequest.setProgrammeId(2L);

            when(studentProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testStudentProfile));
            when(programmeRepository.findById(2L))
                    .thenReturn(Optional.of(newProgramme));
            when(degreeLevelRepository.findById(1L))
                    .thenReturn(Optional.of(testDegreeLevel));
            when(studentProfileRepository.save(any(StudentProfile.class)))
                    .thenReturn(testStudentProfile);
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            studentProfileService.updateStudentProfile(1L, testUpdateRequest, 1L);

            // Assert
            verify(programmeRepository, times(1)).findById(2L);
            assertThat(testStudentProfile.getProgramme()).isEqualTo(newProgramme);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when programme not found")
        void shouldThrowResourceNotFoundException_WhenProgrammeNotFound() {
            // Arrange
            testUpdateRequest.setProgrammeId(999L);

            when(studentProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testStudentProfile));
            when(programmeRepository.findById(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    studentProfileService.updateStudentProfile(1L, testUpdateRequest, 1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");

            verify(studentProfileRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should update degree level when degreeLevelId provided")
        void shouldUpdateDegreeLevel_WhenDegreeLevelIdProvided() {
            // Arrange
            DegreeLevel newDegreeLevel = DegreeLevel.builder()
                    .degreeLevelId(2L)
                    .degreeName("Masters")
                    .build();

            testUpdateRequest.setDegreeLevelId(2L);

            when(studentProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testStudentProfile));
            when(programmeRepository.findById(1L))
                    .thenReturn(Optional.of(testProgramme));
            when(degreeLevelRepository.findById(2L))
                    .thenReturn(Optional.of(newDegreeLevel));
            when(studentProfileRepository.save(any(StudentProfile.class)))
                    .thenReturn(testStudentProfile);
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            studentProfileService.updateStudentProfile(1L, testUpdateRequest, 1L);

            // Assert
            verify(degreeLevelRepository, times(1)).findById(2L);
            assertThat(testStudentProfile.getDegreeLevel()).isEqualTo(newDegreeLevel);
        }

        @Test
        @DisplayName("Should update profile photo on User entity")
        void shouldUpdateProfilePhoto_OnUserEntity() {
            // Arrange
            testUpdateRequest.setProfilePhoto("https://storage.example.com/photo.jpg");

            when(studentProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testStudentProfile));
            when(programmeRepository.findById(1L))
                    .thenReturn(Optional.of(testProgramme));
            when(degreeLevelRepository.findById(1L))
                    .thenReturn(Optional.of(testDegreeLevel));
            when(userRepository.save(any(User.class)))
                    .thenReturn(testUser);
            when(studentProfileRepository.save(any(StudentProfile.class)))
                    .thenReturn(testStudentProfile);
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            studentProfileService.updateStudentProfile(1L, testUpdateRequest, 1L);

            // Assert
            verify(userRepository, times(1)).save(testUser);
            assertThat(testUser.getProfilePhoto())
                    .isEqualTo("https://storage.example.com/photo.jpg");
        }
    }

    // =====================================================
    // SEARCH & FILTER TESTS
    // =====================================================

    @Nested
    @DisplayName("Search & Filter Tests")
    class SearchTests {

        @Test
        @DisplayName("Should return paginated students when searching")
        void shouldReturnPaginatedStudents_WhenSearching() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<StudentProfile> studentPage = new PageImpl<>(
                    List.of(testStudentProfile), pageable, 1);

            when(studentProfileRepository.searchByNameOrBio("john", pageable))
                    .thenReturn(studentPage);
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            Page<StudentProfileResponse> result = studentProfileService
                    .searchStudents("john", pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getFullName())
                    .isEqualTo("John Doe");

            verify(studentProfileRepository, times(1))
                    .searchByNameOrBio("john", pageable);
        }

        @Test
        @DisplayName("Should return students by programme")
        void shouldReturnStudents_ByProgramme() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<StudentProfile> studentPage = new PageImpl<>(
                    List.of(testStudentProfile), pageable, 1);

            when(programmeRepository.existsById(1L)).thenReturn(true);
            when(studentProfileRepository.findByProgrammeProgrammeId(1L, pageable))
                    .thenReturn(studentPage);
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            Page<StudentProfileResponse> result = studentProfileService
                    .getStudentsByProgramme(1L, pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);

            verify(studentProfileRepository, times(1))
                    .findByProgrammeProgrammeId(1L, pageable);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException for invalid programme")
        void shouldThrowResourceNotFoundException_ForInvalidProgramme() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            when(programmeRepository.existsById(999L)).thenReturn(false);

            // Act & Assert
            assertThatThrownBy(() ->
                    studentProfileService.getStudentsByProgramme(999L, pageable))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");

            verify(studentProfileRepository, never())
                    .findByProgrammeProgrammeId(any(), any());
        }

        @Test
        @DisplayName("Should return students by year of study")
        void shouldReturnStudents_ByYear() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<StudentProfile> studentPage = new PageImpl<>(
                    List.of(testStudentProfile), pageable, 1);

            when(studentProfileRepository.findByYearOfStudy(3, pageable))
                    .thenReturn(studentPage);
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            Page<StudentProfileResponse> result = studentProfileService
                    .getStudentsByYear(3, pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getYearOfStudy()).isEqualTo(3);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException for invalid year")
        void shouldThrowResourceNotFoundException_ForInvalidYear() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);

            // Act & Assert
            assertThatThrownBy(() ->
                    studentProfileService.getStudentsByYear(10, pageable))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("10");
        }

        @Test
        @DisplayName("Should return students looking for teammates")
        void shouldReturnStudents_LookingForTeammates() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<StudentProfile> studentPage = new PageImpl<>(
                    List.of(testStudentProfile), pageable, 1);

            when(studentProfileRepository.findByLookingForTeammatesTrue(pageable))
                    .thenReturn(studentPage);
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            Page<StudentProfileResponse> result = studentProfileService
                    .getStudentsLookingForTeammates(pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getLookingForTeammates()).isTrue();
        }

        @Test
        @DisplayName("Should return students open to mentorship")
        void shouldReturnStudents_OpenToMentorship() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            testStudentProfile.setOpenToMentorship(true);

            Page<StudentProfile> studentPage = new PageImpl<>(
                    List.of(testStudentProfile), pageable, 1);

            when(studentProfileRepository.findByOpenToMentorshipTrue(pageable))
                    .thenReturn(studentPage);
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            Page<StudentProfileResponse> result = studentProfileService
                    .getStudentsOpenToMentorship(pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
        }

        @Test
        @DisplayName("Should return students by department")
        void shouldReturnStudents_ByDepartment() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<StudentProfile> studentPage = new PageImpl<>(
                    List.of(testStudentProfile), pageable, 1);

            when(studentProfileRepository.findByDepartmentId(1L, pageable))
                    .thenReturn(studentPage);
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            Page<StudentProfileResponse> result = studentProfileService
                    .getStudentsByDepartment(1L, pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
        }

        @Test
        @DisplayName("Should return students using full text search")
        void shouldReturnStudents_UsingFullTextSearch() {
            // Arrange
            when(studentProfileRepository.fullTextSearch("software"))
                    .thenReturn(List.of(testStudentProfile));
            when(studentProfileMapper.toResponse(testStudentProfile))
                    .thenReturn(testStudentProfileResponse);

            // Act
            List<StudentProfileResponse> result = studentProfileService
                    .fullTextSearchStudents("software");

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getFullName()).isEqualTo("John Doe");

            verify(studentProfileRepository, times(1)).fullTextSearch("software");
        }
    }
}