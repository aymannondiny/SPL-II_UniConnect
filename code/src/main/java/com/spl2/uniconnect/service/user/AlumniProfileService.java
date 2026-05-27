package com.spl2.uniconnect.service.user;

import com.spl2.uniconnect.domain.academic.DegreeLevel;
import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.user.AlumniProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.request.user.UpdateAlumniProfileRequest;
import com.spl2.uniconnect.dto.response.user.AlumniProfileResponse;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.AlumniProfileMapper;
import com.spl2.uniconnect.repository.academic.DegreeLevelRepository;
import com.spl2.uniconnect.repository.academic.ProgrammeRepository;
import com.spl2.uniconnect.repository.user.AlumniProfileRepository;
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
public class AlumniProfileService {

    private final AlumniProfileRepository alumniProfileRepository;
    private final UserRepository userRepository;
    private final ProgrammeRepository programmeRepository;
    private final DegreeLevelRepository degreeLevelRepository;
    private final AlumniProfileMapper alumniProfileMapper;

    // =====================================================
    // GET ALUMNI PROFILE
    // =====================================================

    /**
     * Get alumni profile by user ID
     * FR-2.6: View Profile
     */
    @Transactional(readOnly = true)
    public AlumniProfileResponse getAlumniProfileByUserId(Long userId) {
        log.info("Fetching alumni profile for userId: {}", userId);

        AlumniProfile alumniProfile = alumniProfileRepository
                .findByUserUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Alumni profile not found for userId: " + userId));

        return alumniProfileMapper.toResponse(alumniProfile);
    }

    /**
     * Get alumni profile by alumni ID
     */
    @Transactional(readOnly = true)
    public AlumniProfileResponse getAlumniProfileByAlumniId(Long alumniId) {
        log.info("Fetching alumni profile for alumniId: {}", alumniId);

        AlumniProfile alumniProfile = alumniProfileRepository
                .findById(alumniId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Alumni profile not found for alumniId: " + alumniId));

        return alumniProfileMapper.toResponse(alumniProfile);
    }

    // =====================================================
    // UPDATE ALUMNI PROFILE
    // =====================================================

    /**
     * Update alumni profile
     * FR-2.5: Edit Profile
     */
    @Transactional
    public AlumniProfileResponse updateAlumniProfile(Long userId,
                                                     UpdateAlumniProfileRequest request,
                                                     Long currentUserId) {
        log.info("Updating alumni profile for userId: {}", userId);

        // 1. Check authorization - only owner can update
        if (!userId.equals(currentUserId)) {
            throw new ForbiddenException(
                    "You are not authorized to update this profile");
        }

        // 2. Find existing alumni profile
        AlumniProfile alumniProfile = alumniProfileRepository
                .findByUserUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Alumni profile not found for userId: " + userId));

        // 3. Handle programme update (if provided)
        if (request.getProgrammeId() != null) {
            Programme programme = programmeRepository
                    .findById(request.getProgrammeId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Programme not found with id: " + request.getProgrammeId()));
            alumniProfile.setProgramme(programme);
        }

        // 4. Handle degree level update (if provided)
        if (request.getDegreeLevelId() != null) {
            DegreeLevel degreeLevel = degreeLevelRepository
                    .findById(request.getDegreeLevelId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Degree level not found with id: " + request.getDegreeLevelId()));
            alumniProfile.setDegreeLevel(degreeLevel);
        }

        // 5. Handle profile photo update (stored on User entity)
        if (request.getProfilePhoto() != null) {
            User user = alumniProfile.getUser();
            user.setProfilePhoto(request.getProfilePhoto());
            userRepository.save(user);
        }

        // 6. Update remaining fields
        alumniProfileMapper.updateEntityFromRequest(request, alumniProfile);

        // 7. Save and return
        AlumniProfile savedProfile = alumniProfileRepository.save(alumniProfile);
        log.info("Alumni profile updated successfully for userId: {}", userId);

        return alumniProfileMapper.toResponse(savedProfile);
    }

    // =====================================================
    // SEARCH & FILTER
    // =====================================================

    /**
     * Search alumni by name, company, position, or background
     */
    @Transactional(readOnly = true)
    public Page<AlumniProfileResponse> searchAlumni(String query, Pageable pageable) {
        log.info("Searching alumni with query: {}", query);

        return alumniProfileRepository
                .searchAlumni(query, pageable)
                .map(alumniProfileMapper::toResponse);
    }

    /**
     * Get alumni by graduation year
     */
    @Transactional(readOnly = true)
    public Page<AlumniProfileResponse> getAlumniByGraduationYear(Integer year,
                                                                 Pageable pageable) {
        log.info("Fetching alumni for graduation year: {}", year);

        return alumniProfileRepository
                .findByGraduationYear(year, pageable)
                .map(alumniProfileMapper::toResponse);
    }

    /**
     * Get alumni by graduation year range
     */
    @Transactional(readOnly = true)
    public Page<AlumniProfileResponse> getAlumniByYearRange(Integer startYear,
                                                            Integer endYear,
                                                            Pageable pageable) {
        log.info("Fetching alumni between {} and {}", startYear, endYear);

        return alumniProfileRepository
                .findByGraduationYearBetween(startYear, endYear, pageable)
                .map(alumniProfileMapper::toResponse);
    }

    /**
     * Get alumni by programme
     */
    @Transactional(readOnly = true)
    public Page<AlumniProfileResponse> getAlumniByProgramme(Long programmeId,
                                                            Pageable pageable) {
        log.info("Fetching alumni with programmeId: {}", programmeId);

        // Check programme exists
        if (!programmeRepository.existsById(programmeId)) {
            throw new ResourceNotFoundException(
                    "Programme not found with id: " + programmeId);
        }

        return alumniProfileRepository
                .findByProgrammeProgrammeId(programmeId, pageable)
                .map(alumniProfileMapper::toResponse);
    }

    /**
     * Get alumni by company
     */
    @Transactional(readOnly = true)
    public Page<AlumniProfileResponse> getAlumniByCompany(String company,
                                                          Pageable pageable) {
        log.info("Fetching alumni working at: {}", company);

        return alumniProfileRepository
                .findByCurrentCompanyContainingIgnoreCase(company, pageable)
                .map(alumniProfileMapper::toResponse);
    }

    /**
     * Get alumni by industry
     */
    @Transactional(readOnly = true)
    public Page<AlumniProfileResponse> getAlumniByIndustry(String industry,
                                                           Pageable pageable) {
        log.info("Fetching alumni in industry: {}", industry);

        return alumniProfileRepository
                .findByIndustryContainingIgnoreCase(industry, pageable)
                .map(alumniProfileMapper::toResponse);
    }

    /**
     * Get alumni by filters (all optional)
     */
    @Transactional(readOnly = true)
    public Page<AlumniProfileResponse> getAlumniByFilters(Integer graduationYear,
                                                          String industry,
                                                          String company,
                                                          Pageable pageable) {
        log.info("Fetching alumni with filters - year: {}, industry: {}, company: {}",
                graduationYear, industry, company);

        return alumniProfileRepository
                .findByFilters(graduationYear, industry, company, pageable)
                .map(alumniProfileMapper::toResponse);
    }

    /**
     * Full text search alumni (PostgreSQL)
     */
    @Transactional(readOnly = true)
    public List<AlumniProfileResponse> fullTextSearchAlumni(String query) {
        log.info("Full text search alumni with query: {}", query);

        return alumniProfileRepository
                .fullTextSearch(query)
                .stream()
                .map(alumniProfileMapper::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get all distinct industries
     */
    @Transactional(readOnly = true)
    public List<String> getAllIndustries() {
        log.info("Fetching all distinct industries");

        return alumniProfileRepository.findAllDistinctIndustries();
    }

    /**
     * Get all distinct companies
     */
    @Transactional(readOnly = true)
    public List<String> getAllCompanies() {
        log.info("Fetching all distinct companies");

        return alumniProfileRepository.findAllDistinctCompanies();
    }
}