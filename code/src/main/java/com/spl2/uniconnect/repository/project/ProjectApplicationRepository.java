package com.spl2.uniconnect.repository.project;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.spl2.uniconnect.domain.project.ProjectApplication;
import com.spl2.uniconnect.domain.project.ApplicationStatus;

import java.util.Optional;

@Repository
public interface ProjectApplicationRepository extends JpaRepository<ProjectApplication, Long> {

    // =====================================================
    // BASIC QUERIES
    // =====================================================

    /**
     * Find application by project and applicant (unique constraint)
     */
    Optional<ProjectApplication> findByProjectProjectIdAndApplicantUserId(Long projectId, Long applicantId);

    /**
     * Find application with full details
     */
    @Query("SELECT pa FROM ProjectApplication pa " +
            "LEFT JOIN FETCH pa.project p " +
            "LEFT JOIN FETCH pa.applicant " +
            "WHERE pa.applicationId = :applicationId")
    Optional<ProjectApplication> findByIdWithDetails(@Param("applicationId") Long applicationId);

    // =====================================================
    // APPLICATIONS FOR PROJECT
    // =====================================================

    /**
     * Get all applications for a project
     */
    Page<ProjectApplication> findByProjectProjectId(Long projectId, Pageable pageable);

    /**
     * Get pending applications for a project
     */
    @Query("SELECT pa FROM ProjectApplication pa WHERE pa.project.projectId = :projectId AND pa.status = 'Pending'")
    Page<ProjectApplication> findPendingApplicationsByProject(@Param("projectId") Long projectId, Pageable pageable);

    /**
     * Get accepted applications for a project
     */
    @Query("SELECT pa FROM ProjectApplication pa WHERE pa.project.projectId = :projectId AND pa.status = 'Accepted'")
    Page<ProjectApplication> findAcceptedApplicationsByProject(@Param("projectId") Long projectId, Pageable pageable);

    /**
     * Get rejected applications for a project
     */
    @Query("SELECT pa FROM ProjectApplication pa WHERE pa.project.projectId = :projectId AND pa.status = 'Rejected'")
    Page<ProjectApplication> findRejectedApplicationsByProject(@Param("projectId") Long projectId, Pageable pageable);

    /**
     * Count applications by status for a project
     */
    @Query("SELECT COUNT(pa) FROM ProjectApplication pa WHERE pa.project.projectId = :projectId AND pa.status = :status")
    long countByProjectAndStatus(@Param("projectId") Long projectId, @Param("status") ApplicationStatus status);

    // =====================================================
    // APPLICATIONS BY APPLICANT
    // =====================================================

    /**
     * Get all applications by a user
     */
    Page<ProjectApplication> findByApplicantUserId(Long applicantId, Pageable pageable);

    /**
     * Get pending applications sent by user
     */
    @Query("SELECT pa FROM ProjectApplication pa WHERE pa.applicant.userId = :userId AND pa.status = 'Pending'")
    Page<ProjectApplication> findPendingApplicationsByApplicant(@Param("userId") Long userId, Pageable pageable);

    /**
     * Get accepted applications for user
     */
    @Query("SELECT pa FROM ProjectApplication pa WHERE pa.applicant.userId = :userId AND pa.status = 'Accepted'")
    Page<ProjectApplication> findAcceptedApplicationsByApplicant(@Param("userId") Long userId, Pageable pageable);

    // =====================================================
    // STATUS CHECKS
    // =====================================================

    /**
     * Check if user has already applied to project
     */
    @Query("SELECT CASE WHEN COUNT(pa) > 0 THEN true ELSE false END " +
            "FROM ProjectApplication pa WHERE pa.project.projectId = :projectId AND pa.applicant.userId = :userId")
    boolean hasUserAppliedToProject(@Param("projectId") Long projectId, @Param("userId") Long userId);

    /**
     * Check if application is accepted
     */
    @Query("SELECT CASE WHEN pa.status = 'Accepted' THEN true ELSE false END " +
            "FROM ProjectApplication pa WHERE pa.applicationId = :applicationId")
    boolean isApplicationAccepted(@Param("applicationId") Long applicationId);

    /**
     * Get application status
     */
    @Query("SELECT pa.status FROM ProjectApplication pa WHERE pa.applicationId = :applicationId")
    ApplicationStatus getApplicationStatus(@Param("applicationId") Long applicationId);

    // =====================================================
    // COUNTING QUERIES
    // =====================================================

    /**
     * Count total applications for a project
     */
    long countByProjectProjectId(Long projectId);

    /**
     * Count pending applications for a project
     */
    @Query("SELECT COUNT(pa) FROM ProjectApplication pa WHERE pa.project.projectId = :projectId AND pa.status = 'Pending'")
    long countPendingByProject(@Param("projectId") Long projectId);

    /**
     * Count applications by user
     */
    long countByApplicantUserId(Long userId);
}