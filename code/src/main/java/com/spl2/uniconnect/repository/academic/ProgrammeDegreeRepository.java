package com.spl2.uniconnect.repository.academic;

import com.spl2.uniconnect.domain.academic.ProgrammeDegree;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProgrammeDegreeRepository extends JpaRepository<ProgrammeDegree, Long> {

    // =====================================================
    // BASIC LOOKUPS
    // =====================================================


     // Find by programme and degree level combination
    Optional<ProgrammeDegree> findByProgrammeProgrammeIdAndDegreeLevelDegreeLevelId(
            Long programmeId,
            Long degreeLevelId
    );


     // Check if combination exists

    boolean existsByProgrammeProgrammeIdAndDegreeLevelDegreeLevelId(
            Long programmeId,
            Long degreeLevelId
    );


     // Find all degree levels for a programme

    List<ProgrammeDegree> findByProgrammeProgrammeId(Long programmeId);


     // Find all programmes for a degree level
    List<ProgrammeDegree> findByDegreeLevelDegreeLevelId(Long degreeLevelId);

    // =====================================================
    // WITH JOINS (avoid N+1)
    // =====================================================


     // Find all programme-degree combos with full details

    @Query("SELECT pd FROM ProgrammeDegree pd " +
            "JOIN FETCH pd.programme p " +
            "JOIN FETCH p.department " +
            "JOIN FETCH pd.degreeLevel " +
            "WHERE p.department.departmentId = :departmentId")
    List<ProgrammeDegree> findByDepartmentWithDetails(
            @Param("departmentId") Long departmentId
    );


     // Find programme-degree with full details by ID

    @Query("SELECT pd FROM ProgrammeDegree pd " +
            "JOIN FETCH pd.programme " +
            "JOIN FETCH pd.degreeLevel " +
            "WHERE pd.programmeDegreeId = :id")
    Optional<ProgrammeDegree> findByIdWithDetails(
            @Param("id") Long id
    );


     // Find all combos for a programme with degree details

    @Query("SELECT pd FROM ProgrammeDegree pd " +
            "JOIN FETCH pd.degreeLevel " +
            "WHERE pd.programme.programmeId = :programmeId")
    List<ProgrammeDegree> findByProgrammeIdWithDegreeDetails(
            @Param("programmeId") Long programmeId
    );
}