package com.spl2.uniconnect.service.user;

import com.spl2.uniconnect.domain.academic.DegreeLevel;
import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.user.StudentProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.request.user.UpdateStudentProfileRequest;
import com.spl2.uniconnect.dto.response.user.StudentProfileResponse;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.StudentProfileMapper;
import com.spl2.uniconnect.repository.academic.DegreeLevelRepository;
import com.spl2.uniconnect.repository.academic.ProgrammeRepository;
import com.spl2.uniconnect.repository.user.StudentProfileRepository;
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
public class StudentProfileService {

    private final StudentProfileRepository studentProfileRepository;
    private final UserRepository userRepository;
    private final ProgrammeRepository programmeRepository;
    private final DegreeLevelRepository degreeLevelRepository;
    private final StudentProfileMapper studentProfileMapper;

    // =====================================================
    // GET STUDENT PROFILE
    // =====================================================

    /**
     * Get student profile by user ID
     * FR-2.6: View Profile
     */
    @Transactional(readOnly = true)
    public StudentProfileResponse getStudentProfileByUserId(Long userId) {
        log.info("Fetching student profile for userId: {}", userId);

        StudentProfile studentProfile = studentProfileRepository
                .findByUserUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Student profile not found for userId: " + userId));

        return studentProfileMapper.toResponse(studentProfile);
    }

    /**
     * Get student profile by student ID
     */
    @Transactional(readOnly = true)
    public StudentProfileResponse getStudentProfileByStudentId(Long studentId) {
        log.info("Fetching student profile for studentId: {}", studentId);

        StudentProfile studentProfile = studentProfileRepository
                .findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Student profile not found for studentId: " + studentId));

        return studentProfileMapper.toResponse(studentProfile);
    }

    // =====================================================
    // UPDATE STUDENT PROFILE
    // =====================================================

    /**
     * Update student profile
     * FR-2.5: Edit Profile
     */
    @Transactional
    public StudentProfileResponse updateStudentProfile(Long userId,
                                                       UpdateStudentProfileRequest request,
                                                       Long currentUserId) {
        log.info("Updating student profile for userId: {}", userId);

        // 1. Check authorization - only owner can update
        if (!userId.equals(currentUserId)) {
            throw new ForbiddenException(
                    "You are not authorized to update this profile");
        }

        // 2. Find existing student profile
        StudentProfile studentProfile = studentProfileRepository
                .findByUserUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Student profile not found for userId: " + userId));

        // 3. Handle programme update (if provided)
        if (request.getProgrammeId() != null) {
            Programme programme = programmeRepository
                    .findById(request.getProgrammeId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Programme not found with id: " + request.getProgrammeId()));
            studentProfile.setProgramme(programme);
        }

        // 4. Handle degree level update (if provided)
        if (request.getDegreeLevelId() != null) {
            DegreeLevel degreeLevel = degreeLevelRepository
                    .findById(request.getDegreeLevelId())
                    .orElseThrow(() -> new ResourceNotFoundException(
                            "Degree level not found with id: " + request.getDegreeLevelId()));
            studentProfile.setDegreeLevel(degreeLevel);
        }

        // 5. Handle profile photo update (stored on User entity)
        if (request.getProfilePhoto() != null) {
            User user = studentProfile.getUser();
            user.setProfilePhoto(request.getProfilePhoto());
            userRepository.save(user);
        }

        // 6. Update remaining fields
        studentProfileMapper.updateEntityFromRequest(request, studentProfile);

        // 7. Save and return
        StudentProfile savedProfile = studentProfileRepository.save(studentProfile);
        log.info("Student profile updated successfully for userId: {}", userId);

        return studentProfileMapper.toResponse(savedProfile);
    }

    // =====================================================
    // SEARCH & FILTER
    // =====================================================

    /**
     * Search students by name or bio
     */
    @Transactional(readOnly = true)
    public Page<StudentProfileResponse> searchStudents(String query, Pageable pageable) {
        log.info("Searching students with query: {}", query);

        return studentProfileRepository
                .searchByNameOrBio(query, pageable)
                .map(studentProfileMapper::toResponse);
    }

    /**
     * Get students by programme
     */
    @Transactional(readOnly = true)
    public Page<StudentProfileResponse> getStudentsByProgramme(Long programmeId,
                                                               Pageable pageable) {
        log.info("Fetching students for programmeId: {}", programmeId);

        // Check programme exists
        if (!programmeRepository.existsById(programmeId)) {
            throw new ResourceNotFoundException(
                    "Programme not found with id: " + programmeId);
        }

        return studentProfileRepository
                .findByProgrammeProgrammeId(programmeId, pageable)
                .map(studentProfileMapper::toResponse);
    }

    /**
     * Get students by year of study
     */
    @Transactional(readOnly = true)
    public Page<StudentProfileResponse> getStudentsByYear(Integer year, Pageable pageable) {
        log.info("Fetching students for year: {}", year);

        // Validate year
        if (year < 1 || year > 7) {
            throw new ResourceNotFoundException(
                    "Invalid year of study: " + year + ". Must be between 1 and 7");
        }

        return studentProfileRepository
                .findByYearOfStudy(year, pageable)
                .map(studentProfileMapper::toResponse);
    }

    /**
     * Get students looking for teammates
     */
    @Transactional(readOnly = true)
    public Page<StudentProfileResponse> getStudentsLookingForTeammates(Pageable pageable) {
        log.info("Fetching students looking for teammates");

        return studentProfileRepository
                .findByLookingForTeammatesTrue(pageable)
                .map(studentProfileMapper::toResponse);
    }

    /**
     * Get students open to mentorship
     */
    @Transactional(readOnly = true)
    public Page<StudentProfileResponse> getStudentsOpenToMentorship(Pageable pageable) {
        log.info("Fetching students open to mentorship");

        return studentProfileRepository
                .findByOpenToMentorshipTrue(pageable)
                .map(studentProfileMapper::toResponse);
    }

    /**
     * Get students by department
     */
    @Transactional(readOnly = true)
    public Page<StudentProfileResponse> getStudentsByDepartment(Long departmentId,
                                                                Pageable pageable) {
        log.info("Fetching students for departmentId: {}", departmentId);

        return studentProfileRepository
                .findByDepartmentId(departmentId, pageable)
                .map(studentProfileMapper::toResponse);
    }

    /**
     * Full text search students (PostgreSQL)
     */
    @Transactional(readOnly = true)
    public List<StudentProfileResponse> fullTextSearchStudents(String query) {
        log.info("Full text search students with query: {}", query);

        return studentProfileRepository
                .fullTextSearch(query)
                .stream()
                .map(studentProfileMapper::toResponse)
                .collect(Collectors.toList());
    }
}