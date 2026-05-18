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

    // Find alumni by programme
    Page<AlumniProfile> findByProgrammeProgrammeId(
            Long programmeId,
            Pageable pageable
    );

    // Find alumni by industry
    Page<AlumniProfile> findByIndustry(String industry, Pageable pageable);

    // Find alumni by company
    Page<AlumniProfile> findByCurrentCompanyIgnoreCase(
            String company,
            Pageable pageable
    );

    // =====================================================
    // SEARCH QUERIES
    // =====================================================

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
            "JOIN FETCH ap.user " +
            "WHERE (:industry IS NULL OR ap.industry = :industry) " +
            "AND (:programmeId IS NULL OR ap.programme.programmeId = :programmeId) " +
            "AND (:graduationYear IS NULL OR ap.graduationYear = :graduationYear)")
    Page<AlumniProfile> findByFilters(
            @Param("industry") String industry,
            @Param("programmeId") Long programmeId,
            @Param("graduationYear") Integer graduationYear,
            Pageable pageable
    );

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
}