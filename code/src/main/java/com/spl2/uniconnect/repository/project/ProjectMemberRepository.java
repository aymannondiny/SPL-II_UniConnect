package com.spl2.uniconnect.repository.project;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.spl2.uniconnect.domain.project.ProjectMember;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProjectMemberRepository extends JpaRepository<ProjectMember, Long> {

    // =====================================================
    // BASIC QUERIES
    // =====================================================

    /**
     * Find member with full details
     */
    @Query("SELECT pm FROM ProjectMember pm " +
            "LEFT JOIN FETCH pm.project p " +
            "LEFT JOIN FETCH pm.user u " +
            "WHERE pm.memberId = :memberId")
    Optional<ProjectMember> findByIdWithDetails(@Param("memberId") Long memberId);

    /**
     * Find member by project and user (unique constraint)
     */
    Optional<ProjectMember> findByProjectProjectIdAndUserUserId(Long projectId, Long userId);

    // =====================================================
    // MEMBERS OF PROJECT
    // =====================================================

    /**
     * Get all members of a project
     */
    @Query("SELECT pm FROM ProjectMember pm WHERE pm.project.projectId = :projectId ORDER BY pm.joinedAt ASC")
    Page<ProjectMember> findByProjectProjectId(@Param("projectId") Long projectId, Pageable pageable);

    /**
     * Get all members of a project (list, not paged)
     */
    @Query("SELECT pm FROM ProjectMember pm WHERE pm.project.projectId = :projectId ORDER BY pm.joinedAt ASC")
    List<ProjectMember> findAllMembersByProject(@Param("projectId") Long projectId);

    /**
     * Get project creator member (role = 'Creator')
     */
    @Query("SELECT pm FROM ProjectMember pm WHERE pm.project.projectId = :projectId AND pm.role = 'Creator'")
    Optional<ProjectMember> findProjectCreator(@Param("projectId") Long projectId);

    /**
     * Get team members excluding creator
     */
    @Query("SELECT pm FROM ProjectMember pm WHERE pm.project.projectId = :projectId AND pm.role != 'Creator' ORDER BY pm.joinedAt ASC")
    List<ProjectMember> findTeamMembersExcludingCreator(@Param("projectId") Long projectId);

    // =====================================================
    // PROJECTS OF USER
    // =====================================================

    /**
     * Get all projects user is member of
     */
    @Query("SELECT pm FROM ProjectMember pm WHERE pm.user.userId = :userId ORDER BY pm.joinedAt DESC")
    Page<ProjectMember> findByUserUserId(@Param("userId") Long userId, Pageable pageable);

    /**
     * Get all projects user created or is member of
     */
    @Query("SELECT pm FROM ProjectMember pm WHERE pm.user.userId = :userId ORDER BY pm.joinedAt DESC")
    List<ProjectMember> findAllProjectsByUser(@Param("userId") Long userId);

    /**
     * Get projects user is creator of
     */
    @Query("SELECT pm FROM ProjectMember pm WHERE pm.user.userId = :userId AND pm.role = 'Creator'")
    List<ProjectMember> findProjectsCreatedByUser(@Param("userId") Long userId);

    // =====================================================
    // COUNTING QUERIES
    // =====================================================

    /**
     * Count members in a project
     */
    long countByProjectProjectId(Long projectId);

    /**
     * Count projects a user is member of
     */
    long countByUserUserId(Long userId);

    /**
     * Check if user is member of project
     */
    @Query("SELECT CASE WHEN COUNT(pm) > 0 THEN true ELSE false END " +
            "FROM ProjectMember pm WHERE pm.project.projectId = :projectId AND pm.user.userId = :userId")
    boolean isUserProjectMember(@Param("projectId") Long projectId, @Param("userId") Long userId);

    /**
     * Check if user is creator of project
     */
    @Query("SELECT CASE WHEN COUNT(pm) > 0 THEN true ELSE false END " +
            "FROM ProjectMember pm WHERE pm.project.projectId = :projectId AND pm.user.userId = :userId AND pm.role = 'Creator'")
    boolean isUserProjectCreator(@Param("projectId") Long projectId, @Param("userId") Long userId);

    // =====================================================
    // ROLE QUERIES
    // =====================================================

    /**
     * Get member by role in project
     */
    @Query("SELECT pm FROM ProjectMember pm WHERE pm.project.projectId = :projectId AND pm.role = :role")
    List<ProjectMember> findByProjectAndRole(@Param("projectId") Long projectId, @Param("role") String role);

    /**
     * Get user IDs of all members in a project
     */
    @Query("SELECT pm.user.userId FROM ProjectMember pm WHERE pm.project.projectId = :projectId")
    List<Long> findAllMemberUserIds(@Param("projectId") Long projectId);
}