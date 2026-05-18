package com.spl2.uniconnect.repository.academic;

import com.spl2.uniconnect.domain.academic.Programme;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProgrammeRepository extends JpaRepository<Programme, Long> {

    // =====================================================
    // BASIC LOOKUPS
    // =====================================================

    // Find all programmes by department

    List<Programme> findByDepartmentDepartmentId(Long departmentId);


     // Find programme by code within a department

    Optional<Programme> findByDepartmentDepartmentIdAndProgrammeCode(
            Long departmentId,
            String programmeCode
    );


     // Check if programme code exists in department

    boolean existsByDepartmentDepartmentIdAndProgrammeCode(
            Long departmentId,
            String programmeCode
    );

    // Find programme by name within a department
    Optional<Programme> findByDepartmentDepartmentIdAndProgrammeName(
            Long departmentId,
            String programmeName
    );

    // =====================================================
    // SEARCH
    // =====================================================


     // Search programmes by name or code

    @Query("SELECT p FROM Programme p WHERE " +
            "LOWER(p.programmeName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(p.programmeCode) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Programme> searchByNameOrCode(@Param("query") String query);


     // Find all programmes ordered by name

    List<Programme> findAllByOrderByProgrammeNameAsc();


     // Find programmes by department ordered by name

    List<Programme> findByDepartmentDepartmentIdOrderByProgrammeNameAsc(
            Long departmentId
    );

    // =====================================================
    // WITH JOINS
    // =====================================================


     // Find programme with its department eagerly loaded

    @Query("SELECT p FROM Programme p " +
            "JOIN FETCH p.department " +
            "WHERE p.programmeId = :programmeId")
    Optional<Programme> findByIdWithDepartment(@Param("programmeId") Long programmeId);


     // Find all programmes with departments (avoid N+1)

    @Query("SELECT p FROM Programme p JOIN FETCH p.department")
    List<Programme> findAllWithDepartments();
}