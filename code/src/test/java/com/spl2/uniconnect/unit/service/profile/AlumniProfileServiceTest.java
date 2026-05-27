package com.spl2.uniconnect.unit.service.profile;

import com.spl2.uniconnect.domain.academic.DegreeLevel;
import com.spl2.uniconnect.domain.academic.Department;
import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.user.AlumniProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.user.UpdateAlumniProfileRequest;
import com.spl2.uniconnect.dto.response.user.AlumniProfileResponse;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.AlumniProfileMapper;
import com.spl2.uniconnect.repository.academic.DegreeLevelRepository;
import com.spl2.uniconnect.repository.academic.ProgrammeRepository;
import com.spl2.uniconnect.repository.user.AlumniProfileRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.service.user.AlumniProfileService;
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
@DisplayName("AlumniProfileService Unit Tests")
class AlumniProfileServiceTest {

    @Mock
    private AlumniProfileRepository alumniProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ProgrammeRepository programmeRepository;

    @Mock
    private DegreeLevelRepository degreeLevelRepository;

    @Mock
    private AlumniProfileMapper alumniProfileMapper;

    @InjectMocks
    private AlumniProfileService alumniProfileService;

    // =====================================================
    // TEST DATA
    // =====================================================

    private User testUser;
    private Department testDepartment;
    private Programme testProgramme;
    private DegreeLevel testDegreeLevel;
    private AlumniProfile testAlumniProfile;
    private AlumniProfileResponse testAlumniProfileResponse;
    private UpdateAlumniProfileRequest testUpdateRequest;

    @BeforeEach
    void setUp() {
        // Build test user
        testUser = User.builder()
                .userId(1L)
                .email("jane.smith@university.edu")
                .passwordHash("hashedPassword")
                .role(UserRole.ALUMNI)
                .fullName("Jane Smith")
                .profilePhoto("https://storage.example.com/jane.jpg")
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

        // Build test alumni profile
        testAlumniProfile = AlumniProfile.builder()
                .alumniId(1L)
                .user(testUser)
                .graduationYear(2020)
                .programme(testProgramme)
                .degreeLevel(testDegreeLevel)
                .currentCompany("Google")
                .currentPosition("Software Engineer")
                .industry("Technology")
                .careerBackground("5 years of experience in software development")
                .linkedinUrl("https://linkedin.com/in/janesmith")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        // Build test response
        testAlumniProfileResponse = AlumniProfileResponse.builder()
                .alumniId(1L)
                .userId(1L)
                .fullName("Jane Smith")
                .email("jane.smith@university.edu")
                .profilePhoto("https://storage.example.com/jane.jpg")
                .graduationYear(2020)
                .programmeId(1L)
                .programmeName("Software Engineering")
                .programmeCode("SE")
                .departmentId(1L)
                .departmentName("Computer Science")
                .degreeLevelId(1L)
                .degreeName("Undergraduate")
                .currentCompany("Google")
                .currentPosition("Software Engineer")
                .industry("Technology")
                .careerBackground("5 years of experience in software development")
                .linkedinUrl("https://linkedin.com/in/janesmith")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        // Build test update request
        testUpdateRequest = new UpdateAlumniProfileRequest();
        testUpdateRequest.setGraduationYear(2020);
        testUpdateRequest.setProgrammeId(1L);
        testUpdateRequest.setDegreeLevelId(1L);
        testUpdateRequest.setCurrentCompany("Microsoft");
        testUpdateRequest.setCurrentPosition("Senior Software Engineer");
        testUpdateRequest.setIndustry("Technology");
    }

    // =====================================================
    // GET ALUMNI PROFILE TESTS
    // =====================================================

    @Nested
    @DisplayName("getAlumniProfileByUserId Tests")
    class GetAlumniProfileByUserIdTests {

        @Test
        @DisplayName("Should return alumni profile when user ID exists")
        void shouldReturnAlumniProfile_WhenUserIdExists() {
            // Arrange
            when(alumniProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testAlumniProfile));
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            AlumniProfileResponse result = alumniProfileService
                    .getAlumniProfileByUserId(1L);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getAlumniId()).isEqualTo(1L);
            assertThat(result.getFullName()).isEqualTo("Jane Smith");
            assertThat(result.getGraduationYear()).isEqualTo(2020);

            verify(alumniProfileRepository, times(1)).findByUserUserId(1L);
            verify(alumniProfileMapper, times(1)).toResponse(testAlumniProfile);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when user ID not found")
        void shouldThrowResourceNotFoundException_WhenUserIdNotFound() {
            // Arrange
            when(alumniProfileRepository.findByUserUserId(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    alumniProfileService.getAlumniProfileByUserId(999L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");

            verify(alumniProfileMapper, never()).toResponse(any());
        }
    }

    @Nested
    @DisplayName("getAlumniProfileByAlumniId Tests")
    class GetAlumniProfileByAlumniIdTests {

        @Test
        @DisplayName("Should return alumni profile when alumni ID exists")
        void shouldReturnAlumniProfile_WhenAlumniIdExists() {
            // Arrange
            when(alumniProfileRepository.findById(1L))
                    .thenReturn(Optional.of(testAlumniProfile));
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            AlumniProfileResponse result = alumniProfileService
                    .getAlumniProfileByAlumniId(1L);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getAlumniId()).isEqualTo(1L);

            verify(alumniProfileRepository, times(1)).findById(1L);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when alumni ID not found")
        void shouldThrowResourceNotFoundException_WhenAlumniIdNotFound() {
            // Arrange
            when(alumniProfileRepository.findById(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    alumniProfileService.getAlumniProfileByAlumniId(999L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");
        }
    }

    // =====================================================
    // UPDATE ALUMNI PROFILE TESTS
    // =====================================================

    @Nested
    @DisplayName("updateAlumniProfile Tests")
    class UpdateAlumniProfileTests {

        @Test
        @DisplayName("Should update alumni profile successfully")
        void shouldUpdateAlumniProfile_Successfully() {
            // Arrange
            when(alumniProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testAlumniProfile));
            when(programmeRepository.findById(1L))
                    .thenReturn(Optional.of(testProgramme));
            when(degreeLevelRepository.findById(1L))
                    .thenReturn(Optional.of(testDegreeLevel));
            when(alumniProfileRepository.save(any(AlumniProfile.class)))
                    .thenReturn(testAlumniProfile);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            AlumniProfileResponse result = alumniProfileService
                    .updateAlumniProfile(1L, testUpdateRequest, 1L);

            // Assert
            assertThat(result).isNotNull();

            verify(alumniProfileRepository, times(1)).save(testAlumniProfile);
            verify(alumniProfileMapper, times(1))
                    .updateEntityFromRequest(testUpdateRequest, testAlumniProfile);
        }

        @Test
        @DisplayName("Should throw ForbiddenException when user is not owner")
        void shouldThrowForbiddenException_WhenUserIsNotOwner() {
            // Act & Assert
            assertThatThrownBy(() ->
                    alumniProfileService.updateAlumniProfile(1L, testUpdateRequest, 2L))
                    .isInstanceOf(ForbiddenException.class)
                    .hasMessageContaining("not authorized");

            verify(alumniProfileRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when profile not found")
        void shouldThrowResourceNotFoundException_WhenProfileNotFound() {
            // Arrange
            when(alumniProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    alumniProfileService.updateAlumniProfile(1L, testUpdateRequest, 1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("1");

            verify(alumniProfileRepository, never()).save(any());
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

            when(alumniProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testAlumniProfile));
            when(programmeRepository.findById(2L))
                    .thenReturn(Optional.of(newProgramme));
            when(degreeLevelRepository.findById(1L))
                    .thenReturn(Optional.of(testDegreeLevel));
            when(alumniProfileRepository.save(any(AlumniProfile.class)))
                    .thenReturn(testAlumniProfile);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            alumniProfileService.updateAlumniProfile(1L, testUpdateRequest, 1L);

            // Assert
            verify(programmeRepository, times(1)).findById(2L);
            assertThat(testAlumniProfile.getProgramme()).isEqualTo(newProgramme);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when programme not found")
        void shouldThrowResourceNotFoundException_WhenProgrammeNotFound() {
            // Arrange
            testUpdateRequest.setProgrammeId(999L);

            when(alumniProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testAlumniProfile));
            when(programmeRepository.findById(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    alumniProfileService.updateAlumniProfile(1L, testUpdateRequest, 1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");

            verify(alumniProfileRepository, never()).save(any());
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

            when(alumniProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testAlumniProfile));
            when(programmeRepository.findById(1L))
                    .thenReturn(Optional.of(testProgramme));
            when(degreeLevelRepository.findById(2L))
                    .thenReturn(Optional.of(newDegreeLevel));
            when(alumniProfileRepository.save(any(AlumniProfile.class)))
                    .thenReturn(testAlumniProfile);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            alumniProfileService.updateAlumniProfile(1L, testUpdateRequest, 1L);

            // Assert
            verify(degreeLevelRepository, times(1)).findById(2L);
            assertThat(testAlumniProfile.getDegreeLevel()).isEqualTo(newDegreeLevel);
        }

        @Test
        @DisplayName("Should update profile photo on User entity")
        void shouldUpdateProfilePhoto_OnUserEntity() {
            // Arrange
            testUpdateRequest.setProfilePhoto("https://storage.example.com/new-photo.jpg");

            when(alumniProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testAlumniProfile));
            when(programmeRepository.findById(1L))
                    .thenReturn(Optional.of(testProgramme));
            when(degreeLevelRepository.findById(1L))
                    .thenReturn(Optional.of(testDegreeLevel));
            when(userRepository.save(any(User.class)))
                    .thenReturn(testUser);
            when(alumniProfileRepository.save(any(AlumniProfile.class)))
                    .thenReturn(testAlumniProfile);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            alumniProfileService.updateAlumniProfile(1L, testUpdateRequest, 1L);

            // Assert
            verify(userRepository, times(1)).save(testUser);
            assertThat(testUser.getProfilePhoto())
                    .isEqualTo("https://storage.example.com/new-photo.jpg");
        }
    }

    // =====================================================
    // SEARCH & FILTER TESTS
    // =====================================================

    @Nested
    @DisplayName("Search & Filter Tests")
    class SearchTests {

        @Test
        @DisplayName("Should return paginated alumni when searching")
        void shouldReturnPaginatedAlumni_WhenSearching() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<AlumniProfile> alumniPage = new PageImpl<>(
                    List.of(testAlumniProfile), pageable, 1);

            when(alumniProfileRepository.searchAlumni("software", pageable))
                    .thenReturn(alumniPage);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            Page<AlumniProfileResponse> result = alumniProfileService
                    .searchAlumni("software", pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getFullName())
                    .isEqualTo("Jane Smith");

            verify(alumniProfileRepository, times(1))
                    .searchAlumni("software", pageable);
        }

        @Test
        @DisplayName("Should return alumni by graduation year")
        void shouldReturnAlumni_ByGraduationYear() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<AlumniProfile> alumniPage = new PageImpl<>(
                    List.of(testAlumniProfile), pageable, 1);

            when(alumniProfileRepository.findByGraduationYear(2020, pageable))
                    .thenReturn(alumniPage);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            Page<AlumniProfileResponse> result = alumniProfileService
                    .getAlumniByGraduationYear(2020, pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getGraduationYear()).isEqualTo(2020);
        }

        @Test
        @DisplayName("Should return alumni by year range")
        void shouldReturnAlumni_ByYearRange() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<AlumniProfile> alumniPage = new PageImpl<>(
                    List.of(testAlumniProfile), pageable, 1);

            when(alumniProfileRepository.findByGraduationYearBetween(2018, 2022, pageable))
                    .thenReturn(alumniPage);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            Page<AlumniProfileResponse> result = alumniProfileService
                    .getAlumniByYearRange(2018, 2022, pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
        }

        @Test
        @DisplayName("Should return alumni by programme")
        void shouldReturnAlumni_ByProgramme() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<AlumniProfile> alumniPage = new PageImpl<>(
                    List.of(testAlumniProfile), pageable, 1);

            when(programmeRepository.existsById(1L)).thenReturn(true);
            when(alumniProfileRepository.findByProgrammeProgrammeId(1L, pageable))
                    .thenReturn(alumniPage);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            Page<AlumniProfileResponse> result = alumniProfileService
                    .getAlumniByProgramme(1L, pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);

            verify(alumniProfileRepository, times(1))
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
                    alumniProfileService.getAlumniByProgramme(999L, pageable))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");

            verify(alumniProfileRepository, never())
                    .findByProgrammeProgrammeId(any(), any());
        }

        @Test
        @DisplayName("Should return alumni by company")
        void shouldReturnAlumni_ByCompany() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<AlumniProfile> alumniPage = new PageImpl<>(
                    List.of(testAlumniProfile), pageable, 1);

            when(alumniProfileRepository
                    .findByCurrentCompanyContainingIgnoreCase("Google", pageable))
                    .thenReturn(alumniPage);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            Page<AlumniProfileResponse> result = alumniProfileService
                    .getAlumniByCompany("Google", pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getCurrentCompany()).isEqualTo("Google");
        }

        @Test
        @DisplayName("Should return alumni by industry")
        void shouldReturnAlumni_ByIndustry() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<AlumniProfile> alumniPage = new PageImpl<>(
                    List.of(testAlumniProfile), pageable, 1);

            when(alumniProfileRepository
                    .findByIndustryContainingIgnoreCase("Technology", pageable))
                    .thenReturn(alumniPage);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            Page<AlumniProfileResponse> result = alumniProfileService
                    .getAlumniByIndustry("Technology", pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getIndustry()).isEqualTo("Technology");
        }

        @Test
        @DisplayName("Should return alumni by filters")
        void shouldReturnAlumni_ByFilters() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<AlumniProfile> alumniPage = new PageImpl<>(
                    List.of(testAlumniProfile), pageable, 1);

            when(alumniProfileRepository.findByFilters(2020, "Technology", "Google", pageable))
                    .thenReturn(alumniPage);
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            Page<AlumniProfileResponse> result = alumniProfileService
                    .getAlumniByFilters(2020, "Technology", "Google", pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
        }

        @Test
        @DisplayName("Should return alumni using full text search")
        void shouldReturnAlumni_UsingFullTextSearch() {
            // Arrange
            when(alumniProfileRepository.fullTextSearch("software engineer"))
                    .thenReturn(List.of(testAlumniProfile));
            when(alumniProfileMapper.toResponse(testAlumniProfile))
                    .thenReturn(testAlumniProfileResponse);

            // Act
            List<AlumniProfileResponse> result = alumniProfileService
                    .fullTextSearchAlumni("software engineer");

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getFullName()).isEqualTo("Jane Smith");

            verify(alumniProfileRepository, times(1)).fullTextSearch("software engineer");
        }

        @Test
        @DisplayName("Should return all distinct industries")
        void shouldReturnAllDistinctIndustries() {
            // Arrange
            List<String> industries = List.of("Technology", "Finance", "Healthcare");

            when(alumniProfileRepository.findAllDistinctIndustries())
                    .thenReturn(industries);

            // Act
            List<String> result = alumniProfileService.getAllIndustries();

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(3);
            assertThat(result).contains("Technology", "Finance", "Healthcare");
        }

        @Test
        @DisplayName("Should return all distinct companies")
        void shouldReturnAllDistinctCompanies() {
            // Arrange
            List<String> companies = List.of("Google", "Microsoft", "Amazon");

            when(alumniProfileRepository.findAllDistinctCompanies())
                    .thenReturn(companies);

            // Act
            List<String> result = alumniProfileService.getAllCompanies();

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(3);
            assertThat(result).contains("Google", "Microsoft", "Amazon");
        }
    }
}