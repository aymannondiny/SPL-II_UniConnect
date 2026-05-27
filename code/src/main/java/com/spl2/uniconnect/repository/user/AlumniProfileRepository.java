package com.spl2.uniconnect.repository.user;

import com.spl2.uniconnect.domain.user.AlumniProfile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AlumniProfileRepository extends JpaRepository<AlumniProfile, Long> {

    // =====================================================
    // BASIC LOOKUPS
    // =====================================================

    // Find alumni profile by user ID
    Optional<AlumniProfile> findByUserUserId(Long userId);

    // Find alumni profile with user details (avoid N+1)
    @Query("SELECT ap FROM AlumniProfile ap " +
            "JOIN FETCH ap.user " +
            "WHERE ap.user.userId = :userId")
    Optional<AlumniProfile> findByIdWithUser(@Param("userId") Long userId);

    // Find alumni by graduation year
    Page<AlumniProfile> findByGraduationYear(
            int graduationYear,
            Pageable pageable
    );

    // ✅ ADD THIS - Find alumni by graduation year range
    @Query("SELECT ap FROM AlumniProfile ap " +
            "WHERE ap.graduationYear BETWEEN :startYear AND :endYear")
    Page<AlumniProfile> findByGraduationYearBetween(
            @Param("startYear") Integer startYear,
            @Param("endYear") Integer endYear,
            Pageable pageable
    );

    // Find alumni by programme
    Page<AlumniProfile> findByProgrammeProgrammeId(
            Long programmeId,
            Pageable pageable
    );

    // Find alumni by industry (exact match)
    Page<AlumniProfile> findByIndustry(String industry, Pageable pageable);

    // ✅ ADD THIS - Find alumni by industry (contains, ignore case)
    Page<AlumniProfile> findByIndustryContainingIgnoreCase(
            String industry,
            Pageable pageable
    );

    // Find alumni by company (exact match, ignore case)
    Page<AlumniProfile> findByCurrentCompanyIgnoreCase(
            String company,
            Pageable pageable
    );

    // ✅ ADD THIS - Find alumni by company (contains, ignore case)
    Page<AlumniProfile> findByCurrentCompanyContainingIgnoreCase(
            String company,
            Pageable pageable
    );

    // =====================================================
    // SEARCH QUERIES
    // =====================================================

    // ✅ ADD THIS - Search alumni by name, company, position, or background
    @Query("SELECT ap FROM AlumniProfile ap " +
            "JOIN ap.user u " +
            "WHERE LOWER(u.fullName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(ap.currentCompany) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(ap.currentPosition) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(ap.careerBackground) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<AlumniProfile> searchAlumni(
            @Param("query") String query,
            Pageable pageable
    );

    // Search alumni by company or position
    @Query("SELECT ap FROM AlumniProfile ap " +
            "WHERE LOWER(ap.currentCompany) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(ap.currentPosition) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<AlumniProfile> searchByCompanyOrPosition(
            @Param("query") String query,
            Pageable pageable
    );

    // Find alumni by filters
    @Query("SELECT ap FROM AlumniProfile ap " +
            "WHERE (:graduationYear IS NULL OR ap.graduationYear = :graduationYear) " +
            "AND (:industry IS NULL OR LOWER(ap.industry) LIKE LOWER(CONCAT('%', :industry, '%'))) " +
            "AND (:company IS NULL OR LOWER(ap.currentCompany) LIKE LOWER(CONCAT('%', :company, '%')))")
    Page<AlumniProfile> findByFilters(
            @Param("graduationYear") Integer graduationYear,
            @Param("industry") String industry,
            @Param("company") String company,
            Pageable pageable
    );

    // ✅ ADD THIS - PostgreSQL full-text search
    @Query(value = "SELECT ap.* FROM alumni_profiles ap " +
            "JOIN users u ON ap.alumni_id = u.user_id " +
            "WHERE to_tsvector('english', u.full_name || ' ' || " +
            "COALESCE(ap.current_company, '') || ' ' || " +
            "COALESCE(ap.current_position, '') || ' ' || " +
            "COALESCE(ap.career_background, '')) " +
            "@@ plainto_tsquery('english', :query)",
            nativeQuery = true)
    List<AlumniProfile> fullTextSearch(@Param("query") String query);

    // =====================================================
    // ANALYTICS
    // =====================================================

    // Find all distinct industries
    @Query("SELECT DISTINCT ap.industry FROM AlumniProfile ap " +
            "WHERE ap.industry IS NOT NULL " +
            "ORDER BY ap.industry ASC")
    List<String> findAllDistinctIndustries();

    // Find all distinct companies
    @Query("SELECT DISTINCT ap.currentCompany FROM AlumniProfile ap " +
            "WHERE ap.currentCompany IS NOT NULL " +
            "ORDER BY ap.currentCompany ASC")
    List<String> findAllDistinctCompanies();

    // Count alumni by industry
    @Query("SELECT ap.industry, COUNT(ap) FROM AlumniProfile ap " +
            "WHERE ap.industry IS NOT NULL " +
            "GROUP BY ap.industry " +
            "ORDER BY COUNT(ap) DESC")
    List<Object[]> countByIndustry();

    // Count alumni by graduation year
    @Query("SELECT ap.graduationYear, COUNT(ap) FROM AlumniProfile ap " +
            "GROUP BY ap.graduationYear ORDER BY ap.graduationYear DESC")
    List<Object[]> countByGraduationYear();
}