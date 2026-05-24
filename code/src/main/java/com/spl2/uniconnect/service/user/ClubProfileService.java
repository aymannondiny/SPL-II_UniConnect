package com.spl2.uniconnect.service.user;

import com.spl2.uniconnect.domain.academic.Department;
import com.spl2.uniconnect.domain.user.ClubProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.request.user.UpdateClubProfileRequest;
import com.spl2.uniconnect.dto.response.user.ClubProfileResponse;
import com.spl2.uniconnect.exception.BadRequestException;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.ClubProfileMapper;
import com.spl2.uniconnect.repository.academic.DepartmentRepository;
import com.spl2.uniconnect.repository.user.ClubProfileRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ClubProfileService {

    private final ClubProfileRepository clubProfileRepository;
    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final ClubProfileMapper clubProfileMapper;

    // =====================================================
    // GET CLUB PROFILE
    // =====================================================

    /**
     * Get club profile by user ID
     * FR-2.6: View Profile
     */
    @Transactional(readOnly = true)
    public ClubProfileResponse getClubProfileByUserId(Long userId) {
        log.info("Fetching club profile for userId: {}", userId);

        ClubProfile clubProfile = clubProfileRepository.findByUserUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Club profile not found for userId: " + userId));

        return clubProfileMapper.toResponse(clubProfile);
    }

    /**
     * Get club profile by club ID
     */
    @Transactional(readOnly = true)
    public ClubProfileResponse getClubProfileByClubId(Long clubId) {
        log.info("Fetching club profile for clubId: {}", clubId);

        ClubProfile clubProfile = clubProfileRepository.findById(clubId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Club profile not found for clubId: " + clubId));

        return clubProfileMapper.toResponse(clubProfile);
    }

    // =====================================================
    // UPDATE CLUB PROFILE
    // =====================================================

    /**
     * Update club profile
     * FR-2.5: Edit Profile
     */
    @Transactional
    public ClubProfileResponse updateClubProfile(Long userId,
                                                 UpdateClubProfileRequest request,
                                                 Long currentUserId) {
        log.info("Updating club profile for userId: {}", userId);

        // 1. Check authorization - only owner can update
        if (!userId.equals(currentUserId)) {
            throw new ForbiddenException("You are not authorized to update this profile");
        }

        // 2. Find existing club profile
        ClubProfile clubProfile = clubProfileRepository.findByUserUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Club profile not found for userId: " + userId));

        // 3. Check club name uniqueness (if name is being changed)
        if (request.getClubName() != null &&
                !request.getClubName().equalsIgnoreCase(clubProfile.getClubName())) {
            if (clubProfileRepository.existsByClubNameAndClubIdNot(
                    request.getClubName(), clubProfile.getClubId())) {
                throw new BadRequestException(
                        "Club name already exists: " + request.getClubName());
            }
        }

        // 4. Handle department update (if provided)
        if (request.getDepartmentId() != null) {
            Department department = departmentRepository
                    .findById(request.getDepartmentId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Department not found with id: " + request.getDepartmentId()));
            clubProfile.setDepartment(department);
        }

        // 5. Update fields from request
        clubProfileMapper.updateEntityFromRequest(request, clubProfile);

        // 6. Save and return
        ClubProfile savedProfile = clubProfileRepository.save(clubProfile);
        log.info("Club profile updated successfully for userId: {}", userId);

        return clubProfileMapper.toResponse(savedProfile);
    }

    // =====================================================
    // SEARCH & FILTER
    // =====================================================

    /**
     * Search clubs by name or description
     */
    @Transactional(readOnly = true)
    public Page<ClubProfileResponse> searchClubs(String query, Pageable pageable) {
        log.info("Searching clubs with query: {}", query);

        return clubProfileRepository
                .searchByNameOrDescription(query, pageable)
                .map(clubProfileMapper::toResponse);
    }

    /**
     * Get clubs by category
     */
    @Transactional(readOnly = true)
    public Page<ClubProfileResponse> getClubsByCategory(String category,
                                                        Pageable pageable) {
        log.info("Fetching clubs by category: {}", category);

        // Validate category
        validateCategory(category);

        return clubProfileRepository
                .findByCategory(category, pageable)
                .map(clubProfileMapper::toResponse);
    }

    /**
     * Get clubs by department
     */
    @Transactional(readOnly = true)
    public List<ClubProfileResponse> getClubsByDepartment(Long departmentId) {
        log.info("Fetching clubs for departmentId: {}", departmentId);

        // Check department exists
        if (!departmentRepository.existsById(departmentId)) {
            throw new ResourceNotFoundException(
                    "Department not found with id: " + departmentId);
        }

        return clubProfileRepository
                .findByDepartmentDepartmentId(departmentId)
                .stream()
                .map(clubProfileMapper::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Full text search clubs (PostgreSQL)
     */
    @Transactional(readOnly = true)
    public List<ClubProfileResponse> fullTextSearchClubs(String query) {
        log.info("Full text search clubs with query: {}", query);

        return clubProfileRepository
                .fullTextSearch(query)
                .stream()
                .map(clubProfileMapper::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get all distinct categories
     */
    @Transactional(readOnly = true)
    public List<String> getAllCategories() {
        return clubProfileRepository.findAllDistinctCategories();
    }

    /**
     * Get clubs with no department (open clubs)
     */
    @Transactional(readOnly = true)
    public List<ClubProfileResponse> getOpenClubs() {
        log.info("Fetching open clubs (no department)");

        return clubProfileRepository
                .findByDepartmentIsNull()
                .stream()
                .map(clubProfileMapper::toResponse)
                .collect(Collectors.toList());
    }

    // =====================================================
    // PRIVATE HELPER METHODS
    // =====================================================

    private void validateCategory(String category) {
        List<String> validCategories = List.of(
                "Academic", "Sports", "Cultural",
                "Tech", "Arts", "Service", "Other"
        );
        if (!validCategories.contains(category)) {
            throw new BadRequestException(
                    "Invalid category: " + category +
                            ". Must be one of: " + validCategories);
        }
    }
}



//Big Picture - How Everything Connects
//
//
//HTTP Request
//    ↓
//Controller (receives request)
//    ↓
//ClubProfileService (THIS CLASS - does the logic)
//    │
//    ├── clubProfileRepository → Database queries
//    ├── departmentRepository  → Department checks
//    ├── userRepository        → User lookups
//    └── clubProfileMapper     → Entity ↔ DTO conversion
//    ↓
//Returns ClubProfileResponse
//    ↓
//Controller sends JSON back to client



//Key Concepts to Remember
//
//
//1. @Transactional       → Wraps in database transaction
//2. readOnly = true      → Optimization for read-only operations
//3. orElseThrow()        → Handle missing data gracefully
//4. Page vs List         → Page = pagination, List = all results
//5. .stream().map()      → Transform collections
//6. Authorization first  → Always check WHO before WHAT
//7. Validate input       → Always validate before processing