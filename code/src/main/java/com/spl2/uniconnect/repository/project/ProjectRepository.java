package com.spl2.uniconnect.repository.project;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.spl2.uniconnect.domain.project.Project;
import com.spl2.uniconnect.domain.project.ProjectStatus;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface ProjectRepository extends JpaRepository<Project, Long> {

    // =====================================================
    // BASIC QUERIES
    // =====================================================

    /**
     * Find project by ID with creator loaded
     */
    @Query("SELECT p FROM Project p LEFT JOIN FETCH p.creator WHERE p.projectId = :projectId")
    Optional<Project> findByIdWithCreator(@Param("projectId") Long projectId);

    /**
     * Find all projects by creator
     */
    Page<Project> findByCreatorUserId(Long creatorId, Pageable pageable);

    /**
     * Find all projects by status
     */
    Page<Project> findByStatus(ProjectStatus status, Pageable pageable);

    /**
     * Find all open projects
     */
    @Query("SELECT p FROM Project p WHERE p.status = 'Open' ORDER BY p.createdAt DESC")
    Page<Project> findAllOpenProjects(Pageable pageable);

    /**
     * Count open projects
     */
    @Query("SELECT COUNT(p) FROM Project p WHERE p.status = 'Open'")
    long countOpenProjects();

    // =====================================================
    // SEARCH & FILTER QUERIES
    // =====================================================

    /**
     * Full-text search on title and description
     */
    @Query(value = "SELECT p FROM Project p " +
            "WHERE (LOWER(p.title) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
            "LOWER(p.description) LIKE LOWER(CONCAT('%', :search, '%'))) " +
            "AND p.status = 'Open' " +
            "ORDER BY p.createdAt DESC",
            countQuery = "SELECT COUNT(p) FROM Project p " +
                    "WHERE (LOWER(p.title) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
                    "LOWER(p.description) LIKE LOWER(CONCAT('%', :search, '%'))) " +
                    "AND p.status = 'Open'")
    Page<Project> searchProjects(@Param("search") String searchQuery, Pageable pageable);

    /**
     * Find projects by course name
     */
    Page<Project> findByCourseName(String courseName, Pageable pageable);

    /**
     * Find projects with deadline approaching (within N days)
     */
    @Query("SELECT p FROM Project p WHERE p.applicationDeadline BETWEEN CURRENT_DATE AND :deadline AND p.status = 'Open'")
    Page<Project> findProjectsWithDeadlineApproaching(@Param("deadline") LocalDate deadline, Pageable pageable);

    /**
     * Find recent projects (created in last N days)
     */
    @Query("SELECT p FROM Project p WHERE p.createdAt >= :fromDate AND p.status = 'Open' ORDER BY p.createdAt DESC")
    Page<Project> findRecentProjects(@Param("fromDate") java.time.LocalDateTime fromDate, Pageable pageable);

    // =====================================================
    // TEAM SIZE QUERIES
    // =====================================================

    /**
     * Find projects that still need teammates
     */
    @Query("SELECT p FROM Project p " +
            "WHERE p.status = 'Open' " +
            "ORDER BY p.createdAt DESC")
    Page<Project> findProjectsNeedingTeammates(Pageable pageable);

    /**
     * Find projects where user is NOT a member
     */
    @Query("SELECT p FROM Project p WHERE " +
            "p.status = 'Open' AND " +
            "p.projectId NOT IN (" +
            "  SELECT pm.project.projectId FROM ProjectMember pm WHERE pm.user.userId = :userId" +
            ")")
    Page<Project> findProjectsUserNotMemberOf(@Param("userId") Long userId, Pageable pageable);

    // =====================================================
    // SKILL-BASED QUERIES
    // =====================================================

    /**
     * Find projects requiring a specific skill
     */
    @Query("SELECT DISTINCT p FROM Project p " +
            "JOIN ProjectSkill ps ON ps.project.projectId = p.projectId " +
            "WHERE ps.skill.skillName = :skillName AND p.status = 'Open'")
    Page<Project> findProjectsByRequiredSkill(@Param("skillName") String skillName, Pageable pageable);

    /**
     * Find projects where all required skills match user's skills
     */
    @Query("SELECT p FROM Project p WHERE " +
            "p.status = 'Open' AND " +
            "p.projectId NOT IN (" +
            "  SELECT pm.project.projectId FROM ProjectMember pm WHERE pm.user.userId = :userId" +
            ")")
    Page<Project> findProjectsMatchingUserSkills(@Param("userId") Long userId, Pageable pageable);

    // =====================================================
    // APPLICATION DEADLINE QUERIES
    // =====================================================

    /**
     * Find projects with applications still open
     */
    @Query("SELECT p FROM Project p WHERE " +
            "p.status = 'Open' AND " +
            "(p.applicationDeadline IS NULL OR p.applicationDeadline > CURRENT_DATE)")
    Page<Project> findProjectsWithOpenApplications(Pageable pageable);

    /**
     * Find expired projects (deadline passed)
     */
    @Query("SELECT p FROM Project p WHERE " +
            "p.applicationDeadline < CURRENT_DATE AND p.status = 'Open'")
    Page<Project> findExpiredProjects(Pageable pageable);

    // =====================================================
    // TEAM COMPOSITION QUERIES
    // =====================================================

    /**
     * Get list of all team member IDs for a project
     */
    @Query("SELECT pm.user.userId FROM ProjectMember pm WHERE pm.project.projectId = :projectId")
    List<Long> getTeamMemberIds(@Param("projectId") Long projectId);

    /**
     * Get current team size for a project
     */
    @Query("SELECT COUNT(pm) FROM ProjectMember pm WHERE pm.project.projectId = :projectId")
    long getTeamSize(@Param("projectId") Long projectId);

    /**
     * Check if user is member of project
     */
    @Query("SELECT CASE WHEN COUNT(pm) > 0 THEN true ELSE false END " +
            "FROM ProjectMember pm WHERE pm.project.projectId = :projectId AND pm.user.userId = :userId")
    boolean isUserProjectMember(@Param("projectId") Long projectId, @Param("userId") Long userId);

    // =====================================================
    // DISCOVERY QUERIES (For Recommendations)
    // =====================================================

    /**
     * Find projects by multiple criteria (for recommendations)
     */
    @Query("SELECT p FROM Project p WHERE " +
            "p.status = 'Open' AND " +
            "p.projectId NOT IN (" +
            "  SELECT pm.project.projectId FROM ProjectMember pm WHERE pm.user.userId = :userId" +
            ") " +
            "ORDER BY p.createdAt DESC")
    Page<Project> findAvailableProjectsForUser(@Param("userId") Long userId, Pageable pageable);

    /**
     * Find projects created by user's connections
     */
    @Query("SELECT p FROM Project p WHERE " +
            "p.creator.userId IN (" +
            "  SELECT CASE " +
            "    WHEN c.user1.userId = :userId THEN c.user2.userId " +
            "    ELSE c.user1.userId END " +
            "  FROM Connection c WHERE " +
            "  (c.user1.userId = :userId OR c.user2.userId = :userId) AND " +
            "  c.status = 'ACCEPTED'" +
            ") AND " +
            "p.status = 'Open' " +
            "ORDER BY p.createdAt DESC")
    Page<Project> findProjectsByConnections(@Param("userId") Long userId, Pageable pageable);
}