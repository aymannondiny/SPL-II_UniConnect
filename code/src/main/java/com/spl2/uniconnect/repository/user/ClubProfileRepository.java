package com.spl2.uniconnect.repository.user;

import com.spl2.uniconnect.domain.user.ClubProfile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClubProfileRepository extends JpaRepository<ClubProfile, Long> {

    // =====================================================
    // BASIC LOOKUPS
    // =====================================================

    // Find club by name
    Optional<ClubProfile> findByClubName(String clubName);

    // Check if club name exists
    boolean existsByClubName(String clubName);

    // Find clubs by category
    Page<ClubProfile> findByCategory(String category, Pageable pageable);

    // Find clubs by department
    List<ClubProfile> findByDepartmentDepartmentId(Long departmentId);

    // Find clubs not tied to any department (open clubs)
    List<ClubProfile> findByDepartmentIsNull();

    // =====================================================
    // SEARCH QUERIES
    // =====================================================

    // Search clubs by name or description
    @Query("SELECT cp FROM ClubProfile cp " +
            "WHERE LOWER(cp.clubName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(cp.description) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<ClubProfile> searchByNameOrDescription(
            @Param("query") String query,
            Pageable pageable
    );

    // Find clubs by category and department
    Page<ClubProfile> findByCategoryAndDepartmentDepartmentId(
            String category,
            Long departmentId,
            Pageable pageable
    );

    // PostgreSQL full-text search for clubs
    @Query(value = "SELECT * FROM club_profiles cp " +
            "JOIN users u ON cp.club_id = u.user_id " +
            "WHERE to_tsvector('english', u.full_name || ' ' || cp.description) " +
            "@@ plainto_tsquery('english', :query)",
            nativeQuery = true)
    List<ClubProfile> fullTextSearch(@Param("query") String query);

    // =====================================================
    // ANALYTICS
    // =====================================================

    // Find all distinct categories
    @Query("SELECT DISTINCT cp.category FROM ClubProfile cp ORDER BY cp.category ASC")
    List<String> findAllDistinctCategories();

    // Count clubs by category
    @Query("SELECT cp.category, COUNT(cp) FROM ClubProfile cp " +
            "GROUP BY cp.category ORDER BY COUNT(cp) DESC")
    List<Object[]> countByCategory();
}