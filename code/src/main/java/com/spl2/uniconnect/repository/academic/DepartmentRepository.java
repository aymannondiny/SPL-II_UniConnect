package com.spl2.uniconnect.repository.academic;

import com.spl2.uniconnect.domain.academic.Department;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DepartmentRepository extends JpaRepository<Department, Long> {

    // =====================================================
    // BASIC LOOKUPS
    // =====================================================

    /**
     * Find department by code (e.g., "CSE")
     */
    Optional<Department> findByDepartmentCode(String departmentCode);

    /**
     * Find department by name
     */
    Optional<Department> findByDepartmentName(String departmentName);

    /**
     * Check if department code exists
     */
    boolean existsByDepartmentCode(String departmentCode);

    /**
     * Check if department name exists
     */
    boolean existsByDepartmentName(String departmentName);

    // =====================================================
    // SEARCH
    // =====================================================

    /**
     * Search departments by name (case-insensitive)
     */
    @Query("SELECT d FROM Department d WHERE " +
            "LOWER(d.departmentName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(d.departmentCode) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Department> searchByNameOrCode(@Param("query") String query);

    /**
     * Find all departments ordered by name
     */
    List<Department> findAllByOrderByDepartmentNameAsc();

    // =====================================================
    // ANALYTICS
    // =====================================================

    /**
     * Find departments that have programmes
     */
    @Query("SELECT DISTINCT d FROM Department d " +
            "WHERE EXISTS (SELECT p FROM Programme p WHERE p.department = d)")
    List<Department> findDepartmentsWithProgrammes();
}