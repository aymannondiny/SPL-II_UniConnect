package com.spl2.uniconnect.repository.user;

import com.spl2.uniconnect.domain.user.StudentProfile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StudentProfileRepository extends JpaRepository<StudentProfile, Long> {

    // =====================================================
    // BASIC LOOKUPS
    // =====================================================

    // ✅ ADD THIS - Simple lookup by user ID
    Optional<StudentProfile> findByUserUserId(Long userId);

    // Find student profile with user details (avoid N+1)
    @Query("SELECT sp FROM StudentProfile sp " +
            "JOIN FETCH sp.user " +
            "WHERE sp.user.userId = :userId")
    Optional<StudentProfile> findByUserUserIdWithDetails(@Param("userId") Long userId);

    // Find students by programme
    Page<StudentProfile> findByProgrammeProgrammeId(
            Long programmeId,
            Pageable pageable
    );

    // Find students by degree level
    Page<StudentProfile> findByDegreeLevelDegreeLevelId(
            Long degreeLevelId,
            Pageable pageable
    );

    // Find students by programme AND degree level
    Page<StudentProfile> findByProgrammeProgrammeIdAndDegreeLevelDegreeLevelId(
            Long programmeId,
            Long degreeLevelId,
            Pageable pageable
    );

    // Find students by year of study
    Page<StudentProfile> findByYearOfStudy(int yearOfStudy, Pageable pageable);

    // =====================================================
    // TEAMMATE FINDER QUERIES
    // =====================================================

    // Find students looking for teammates
    Page<StudentProfile> findByLookingForTeammatesTrue(Pageable pageable);

    // Find students open to mentorship
    Page<StudentProfile> findByOpenToMentorshipTrue(Pageable pageable);

    // Find students looking for teammates in same programme
    Page<StudentProfile> findByProgrammeProgrammeIdAndLookingForTeammatesTrue(
            Long programmeId,
            Pageable pageable
    );

    // =====================================================
    // SEARCH QUERIES (✅ ADD THESE)
    // =====================================================

    // Search students by name or bio
    @Query("SELECT sp FROM StudentProfile sp " +
            "JOIN sp.user u " +
            "WHERE LOWER(u.fullName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(sp.bio) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<StudentProfile> searchByNameOrBio(
            @Param("query") String query,
            Pageable pageable
    );

    // Find students by programme and year of study
    Page<StudentProfile> findByProgrammeProgrammeIdAndYearOfStudy(
            Long programmeId,
            Integer yearOfStudy,
            Pageable pageable
    );

    // Find students by department (through programme)
    @Query("SELECT sp FROM StudentProfile sp " +
            "JOIN sp.programme p " +
            "WHERE p.department.departmentId = :departmentId")
    Page<StudentProfile> findByDepartmentId(
            @Param("departmentId") Long departmentId,
            Pageable pageable
    );

    // PostgreSQL full-text search
    @Query(value = "SELECT sp.* FROM student_profiles sp " +
            "JOIN users u ON sp.student_id = u.user_id " +
            "WHERE to_tsvector('english', u.full_name || ' ' || COALESCE(sp.bio, '')) " +
            "@@ plainto_tsquery('english', :query)",
            nativeQuery = true)
    List<StudentProfile> fullTextSearch(@Param("query") String query);

    // =====================================================
    // ADVANCED QUERIES
    // =====================================================

    // Find students by filters (all optional)
    @Query("SELECT sp FROM StudentProfile sp " +
            "JOIN FETCH sp.user " +
            "JOIN FETCH sp.programme " +
            "JOIN FETCH sp.degreeLevel " +
            "WHERE (:programmeId IS NULL OR sp.programme.programmeId = :programmeId) " +
            "AND (:degreeLevelId IS NULL OR sp.degreeLevel.degreeLevelId = :degreeLevelId) " +
            "AND (:yearOfStudy IS NULL OR sp.yearOfStudy = :yearOfStudy) " +
            "AND (:lookingForTeammates IS NULL OR sp.lookingForTeammates = :lookingForTeammates)")
    Page<StudentProfile> findByFilters(
            @Param("programmeId") Long programmeId,
            @Param("degreeLevelId") Long degreeLevelId,
            @Param("yearOfStudy") Integer yearOfStudy,
            @Param("lookingForTeammates") Boolean lookingForTeammates,
            Pageable pageable
    );

    // =====================================================
    // ANALYTICS (✅ ADD THESE)
    // =====================================================

    // Count students by year of study
    @Query("SELECT sp.yearOfStudy, COUNT(sp) FROM StudentProfile sp " +
            "GROUP BY sp.yearOfStudy ORDER BY sp.yearOfStudy ASC")
    List<Object[]> countByYearOfStudy();

    // Count students by programme
    long countByProgrammeProgrammeId(Long programmeId);

    // Count students by degree level
    long countByDegreeLevelDegreeLevelId(Long degreeLevelId);

    // Count students looking for teammates
    long countByLookingForTeammatesTrue();

    // Count students open to mentorship
    long countByOpenToMentorshipTrue();
}