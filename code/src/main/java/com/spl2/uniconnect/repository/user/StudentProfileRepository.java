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


     // Find student profile with user details (avoid N+1)

    @Query("SELECT sp FROM StudentProfile sp " +
            "JOIN FETCH sp.user " +
            "WHERE sp.user.userId = :userId")
    Optional<StudentProfile> findByIdWithUser(@Param("userId") Long userId);


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

   // Count students by programme
    long countByProgrammeProgrammeId(Long programmeId);

    // Count students by degree level
    long countByDegreeLevelDegreeLevelId(Long degreeLevelId);
}