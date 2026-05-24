package com.spl2.uniconnect.unit.service;

import com.spl2.uniconnect.domain.academic.Department;
import com.spl2.uniconnect.domain.user.ClubProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.user.UpdateClubProfileRequest;
import com.spl2.uniconnect.dto.response.user.ClubProfileResponse;
import com.spl2.uniconnect.exception.BadRequestException;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.ClubProfileMapper;
import com.spl2.uniconnect.repository.academic.DepartmentRepository;
import com.spl2.uniconnect.repository.user.ClubProfileRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.service.user.ClubProfileService;
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

import static javax.management.Query.times;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.anyString;
import static org.mockito.Mockito.anyLong;

@ExtendWith(MockitoExtension.class)
@DisplayName("ClubProfileService Unit Tests")
class ClubProfileServiceTest {

    @Mock
    private ClubProfileRepository clubProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private DepartmentRepository departmentRepository;

    @Mock
    private ClubProfileMapper clubProfileMapper;

    @InjectMocks
    private ClubProfileService clubProfileService;

    // =====================================================
    // TEST DATA
    // =====================================================

    private User testUser;
    private Department testDepartment;
    private ClubProfile testClubProfile;
    private ClubProfileResponse testClubProfileResponse;
    private UpdateClubProfileRequest testUpdateRequest;

    @BeforeEach
    void setUp() {
        // Build test user
        testUser = User.builder()
                .userId(1L)
                .email("robotics@university.edu")
                .passwordHash("hashedPassword")
                .role(UserRole.CLUB_ADMIN)
                .fullName("Robotics Club")
                .emailVerified(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        // Build test department
        testDepartment = Department.builder()
                .departmentId(1L)
                .departmentName("Engineering")
                .departmentCode("ENG")
                .description("Engineering Department")
                .createdAt(LocalDateTime.now())
                .build();

        // Build test club profile
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

        // Build test response
        testClubProfileResponse = ClubProfileResponse.builder()
                .clubId(1L)
                .userId(1L)
                .fullName("Robotics Club")
                .clubName("Robotics Club")
                .description("A club for robotics enthusiasts")
                .category("Tech")
                .departmentId(1L)
                .departmentName("Engineering")
                .foundedYear(2020)
                .meetingSchedule("Every Monday 6PM")
                .contactEmail("robotics@university.edu")
                .websiteUrl("https://robotics.university.edu")
                .clubLogo("https://storage.university.edu/logos/robotics.png")
                .createdAt(LocalDateTime.now())
                .build();

        // Build test update request
        testUpdateRequest = new UpdateClubProfileRequest();
        testUpdateRequest.setClubName("Robotics Club Updated");
        testUpdateRequest.setDescription("An updated description for robotics enthusiasts");
        testUpdateRequest.setCategory("Tech");
    }

    // =====================================================
    // GET CLUB PROFILE BY USER ID TESTS
    // =====================================================

    @Nested
    @DisplayName("getClubProfileByUserId Tests")
    class GetClubProfileByUserIdTests {

        @Test
        @DisplayName("Should return club profile when user ID exists")
        void shouldReturnClubProfile_WhenUserIdExists() {
            // Arrange
            when(clubProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testClubProfile));
            when(clubProfileMapper.toResponse(testClubProfile))
                    .thenReturn(testClubProfileResponse);

            // Act
            ClubProfileResponse result = clubProfileService
                    .getClubProfileByUserId(1L);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getClubId()).isEqualTo(1L);
            assertThat(result.getClubName()).isEqualTo("Robotics Club");
            assertThat(result.getCategory()).isEqualTo("Tech");

            // Verify interactions
            verify(clubProfileRepository, times(1)).findByUserUserId(1L);
            verify(clubProfileMapper, times(1)).toResponse(testClubProfile);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when user ID not found")
        void shouldThrowResourceNotFoundException_WhenUserIdNotFound() {
            // Arrange
            when(clubProfileRepository.findByUserUserId(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    clubProfileService.getClubProfileByUserId(999L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");

            // Verify no mapper call
            verify(clubProfileMapper, never()).toResponse(any());
        }
    }

    // =====================================================
    // GET CLUB PROFILE BY CLUB ID TESTS
    // =====================================================

    @Nested
    @DisplayName("getClubProfileByClubId Tests")
    class GetClubProfileByClubIdTests {

        @Test
        @DisplayName("Should return club profile when club ID exists")
        void shouldReturnClubProfile_WhenClubIdExists() {
            // Arrange
            when(clubProfileRepository.findById(1L))
                    .thenReturn(Optional.of(testClubProfile));
            when(clubProfileMapper.toResponse(testClubProfile))
                    .thenReturn(testClubProfileResponse);

            // Act
            ClubProfileResponse result = clubProfileService
                    .getClubProfileByClubId(1L);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getClubId()).isEqualTo(1L);

            verify(clubProfileRepository, times(1)).findById(1L);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when club ID not found")
        void shouldThrowResourceNotFoundException_WhenClubIdNotFound() {
            // Arrange
            when(clubProfileRepository.findById(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    clubProfileService.getClubProfileByClubId(999L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");
        }
    }

    // =====================================================
    // UPDATE CLUB PROFILE TESTS
    // =====================================================

    @Nested
    @DisplayName("updateClubProfile Tests")
    class UpdateClubProfileTests {

        @Test
        @DisplayName("Should update club profile successfully")
        void shouldUpdateClubProfile_Successfully() {
            // Arrange
            when(clubProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testClubProfile));
            when(clubProfileRepository.existsByClubNameAndClubIdNot(
                    anyString(), anyLong()))
                    .thenReturn(false);
            when(clubProfileRepository.save(any(ClubProfile.class)))
                    .thenReturn(testClubProfile);
            when(clubProfileMapper.toResponse(testClubProfile))
                    .thenReturn(testClubProfileResponse);

            // Act
            ClubProfileResponse result = clubProfileService
                    .updateClubProfile(1L, testUpdateRequest, 1L);

            // Assert
            assertThat(result).isNotNull();

            // Verify save was called
            verify(clubProfileRepository, times(1)).save(testClubProfile);
            verify(clubProfileMapper, times(1))
                    .updateEntityFromRequest(testUpdateRequest, testClubProfile);
        }

        @Test
        @DisplayName("Should throw ForbiddenException when user is not owner")
        void shouldThrowForbiddenException_WhenUserIsNotOwner() {
            // Act & Assert
            assertThatThrownBy(() ->
                    clubProfileService.updateClubProfile(1L, testUpdateRequest, 2L))
                    .isInstanceOf(ForbiddenException.class)
                    .hasMessageContaining("not authorized");

            // Verify no repository calls
            verify(clubProfileRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when profile not found")
        void shouldThrowResourceNotFoundException_WhenProfileNotFound() {
            // Arrange
            when(clubProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    clubProfileService.updateClubProfile(1L, testUpdateRequest, 1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("1");

            verify(clubProfileRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should throw BadRequestException when club name already exists")
        void shouldThrowBadRequestException_WhenClubNameAlreadyExists() {
            // Arrange
            when(clubProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testClubProfile));
            when(clubProfileRepository.existsByClubNameAndClubIdNot(
                    "Robotics Club Updated", 1L))
                    .thenReturn(true);

            // Act & Assert
            assertThatThrownBy(() ->
                    clubProfileService.updateClubProfile(1L, testUpdateRequest, 1L))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("Robotics Club Updated");

            verify(clubProfileRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should update department when departmentId provided")
        void shouldUpdateDepartment_WhenDepartmentIdProvided() {
            // Arrange
            testUpdateRequest.setDepartmentId(2L);

            Department newDepartment = Department.builder()
                    .departmentId(2L)
                    .departmentName("Computer Science")
                    .departmentCode("CS")
                    .build();

            when(clubProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testClubProfile));
            when(clubProfileRepository.existsByClubNameAndClubIdNot(
                    anyString(), anyLong()))
                    .thenReturn(false);
            when(departmentRepository.findById(2L))
                    .thenReturn(Optional.of(newDepartment));
            when(clubProfileRepository.save(any(ClubProfile.class)))
                    .thenReturn(testClubProfile);
            when(clubProfileMapper.toResponse(testClubProfile))
                    .thenReturn(testClubProfileResponse);

            // Act
            clubProfileService.updateClubProfile(1L, testUpdateRequest, 1L);

            // Assert department was set
            verify(departmentRepository, times(1)).findById(2L);
            assertThat(testClubProfile.getDepartment()).isEqualTo(newDepartment);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when department not found")
        void shouldThrowResourceNotFoundException_WhenDepartmentNotFound() {
            // Arrange
            testUpdateRequest.setDepartmentId(999L);

            when(clubProfileRepository.findByUserUserId(1L))
                    .thenReturn(Optional.of(testClubProfile));
            when(clubProfileRepository.existsByClubNameAndClubIdNot(
                    anyString(), anyLong()))
                    .thenReturn(false);
            when(departmentRepository.findById(999L))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThatThrownBy(() ->
                    clubProfileService.updateClubProfile(1L, testUpdateRequest, 1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");

            verify(clubProfileRepository, never()).save(any());
        }
    }

    // =====================================================
    // SEARCH TESTS
    // =====================================================

    @Nested
    @DisplayName("Search & Filter Tests")
    class SearchTests {

        @Test
        @DisplayName("Should return paginated clubs when searching")
        void shouldReturnPaginatedClubs_WhenSearching() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<ClubProfile> clubPage = new PageImpl<>(
                    List.of(testClubProfile), pageable, 1);

            when(clubProfileRepository.searchByNameOrDescription("robot", pageable))
                    .thenReturn(clubPage);
            when(clubProfileMapper.toResponse(testClubProfile))
                    .thenReturn(testClubProfileResponse);

            // Act
            Page<ClubProfileResponse> result = clubProfileService
                    .searchClubs("robot", pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getClubName())
                    .isEqualTo("Robotics Club");

            verify(clubProfileRepository, times(1))
                    .searchByNameOrDescription("robot", pageable);
        }

        @Test
        @DisplayName("Should return clubs by valid category")
        void shouldReturnClubs_ByValidCategory() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);
            Page<ClubProfile> clubPage = new PageImpl<>(
                    List.of(testClubProfile), pageable, 1);

            when(clubProfileRepository.findByCategory("Tech", pageable))
                    .thenReturn(clubPage);
            when(clubProfileMapper.toResponse(testClubProfile))
                    .thenReturn(testClubProfileResponse);

            // Act
            Page<ClubProfileResponse> result = clubProfileService
                    .getClubsByCategory("Tech", pageable);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);

            verify(clubProfileRepository, times(1))
                    .findByCategory("Tech", pageable);
        }

        @Test
        @DisplayName("Should throw BadRequestException for invalid category")
        void shouldThrowBadRequestException_ForInvalidCategory() {
            // Arrange
            Pageable pageable = PageRequest.of(0, 10);

            // Act & Assert
            assertThatThrownBy(() ->
                    clubProfileService.getClubsByCategory("InvalidCategory", pageable))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("InvalidCategory");

            verify(clubProfileRepository, never()).findByCategory(any(), any());
        }

        @Test
        @DisplayName("Should return clubs by department")
        void shouldReturnClubs_ByDepartment() {
            // Arrange
            when(departmentRepository.existsById(1L)).thenReturn(true);
            when(clubProfileRepository.findByDepartmentDepartmentId(1L))
                    .thenReturn(List.of(testClubProfile));
            when(clubProfileMapper.toResponse(testClubProfile))
                    .thenReturn(testClubProfileResponse);

            // Act
            List<ClubProfileResponse> result = clubProfileService
                    .getClubsByDepartment(1L);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getDepartmentId()).isEqualTo(1L);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException for invalid department")
        void shouldThrowResourceNotFoundException_ForInvalidDepartment() {
            // Arrange
            when(departmentRepository.existsById(999L)).thenReturn(false);

            // Act & Assert
            assertThatThrownBy(() ->
                    clubProfileService.getClubsByDepartment(999L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("999");
        }

        @Test
        @DisplayName("Should return open clubs with no department")
        void shouldReturnOpenClubs_WithNoDepartment() {
            // Arrange
            ClubProfile openClub = ClubProfile.builder()
                    .clubId(2L)
                    .user(testUser)
                    .clubName("Open Tech Club")
                    .description("A club open to everyone")
                    .category("Tech")
                    .department(null) // No department
                    .createdAt(LocalDateTime.now())
                    .build();

            ClubProfileResponse openClubResponse = ClubProfileResponse.builder()
                    .clubId(2L)
                    .clubName("Open Tech Club")
                    .departmentId(null)
                    .build();

            when(clubProfileRepository.findByDepartmentIsNull())
                    .thenReturn(List.of(openClub));
            when(clubProfileMapper.toResponse(openClub))
                    .thenReturn(openClubResponse);

            // Act
            List<ClubProfileResponse> result = clubProfileService.getOpenClubs();

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getDepartmentId()).isNull();
        }

        @Test
        @DisplayName("Should return all distinct categories")
        void shouldReturnAllDistinctCategories() {
            // Arrange
            List<String> categories = List.of(
                    "Academic", "Arts", "Cultural",
                    "Service", "Sports", "Tech", "Other"
            );

            when(clubProfileRepository.findAllDistinctCategories())
                    .thenReturn(categories);

            // Act
            List<String> result = clubProfileService.getAllCategories();

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(7);
            assertThat(result).contains("Tech", "Sports", "Academic");
        }

        @Test
        @DisplayName("Should return clubs using full text search")
        void shouldReturnClubs_UsingFullTextSearch() {
            // Arrange
            when(clubProfileRepository.fullTextSearch("robotics"))
                    .thenReturn(List.of(testClubProfile));
            when(clubProfileMapper.toResponse(testClubProfile))
                    .thenReturn(testClubProfileResponse);

            // Act
            List<ClubProfileResponse> result = clubProfileService
                    .fullTextSearchClubs("robotics");

            // Assert
            assertThat(result).isNotNull();
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getClubName()).isEqualTo("Robotics Club");

            verify(clubProfileRepository, times(1)).fullTextSearch("robotics");
        }
    }
}