package com.spl2.uniconnect.repository.project;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.spl2.uniconnect.domain.project.ProjectSkill;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProjectSkillRepository extends JpaRepository<ProjectSkill, Long> {

    // =====================================================
    // BASIC QUERIES
    // =====================================================

    /**
     * Find all skills for a project
     */
    List<ProjectSkill> findByProjectProjectId(Long projectId);

    /**
     * Find required skills for a project
     */
    @Query("SELECT ps FROM ProjectSkill ps WHERE ps.project.projectId = :projectId AND ps.isRequired = true")
    List<ProjectSkill> findRequiredSkillsByProject(@Param("projectId") Long projectId);

    /**
     * Find optional skills for a project
     */
    @Query("SELECT ps FROM ProjectSkill ps WHERE ps.project.projectId = :projectId AND ps.isRequired = false")
    List<ProjectSkill> findOptionalSkillsByProject(@Param("projectId") Long projectId);

    /**
     * Find skill in project
     */
    Optional<ProjectSkill> findByProjectProjectIdAndSkillSkillId(Long projectId, Long skillId);

    // =====================================================
    // SKILL NAME QUERIES
    // =====================================================

    /**
     * Get skill names for a project
     */
    @Query("SELECT ps.skill.skillName FROM ProjectSkill ps WHERE ps.project.projectId = :projectId")
    List<String> getSkillNamesByProject(@Param("projectId") Long projectId);

    /**
     * Get required skill names for a project
     */
    @Query("SELECT ps.skill.skillName FROM ProjectSkill ps WHERE ps.project.projectId = :projectId AND ps.isRequired = true")
    List<String> getRequiredSkillNames(@Param("projectId") Long projectId);

    /**
     * Get optional skill names for a project
     */
    @Query("SELECT ps.skill.skillName FROM ProjectSkill ps WHERE ps.project.projectId = :projectId AND ps.isRequired = false")
    List<String> getOptionalSkillNames(@Param("projectId") Long projectId);

    // =====================================================
    // COUNTING QUERIES
    // =====================================================

    /**
     * Count total skills for a project
     */
    long countByProjectProjectId(Long projectId);

    /**
     * Count required skills
     */
    @Query("SELECT COUNT(ps) FROM ProjectSkill ps WHERE ps.project.projectId = :projectId AND ps.isRequired = true")
    long countRequiredSkills(@Param("projectId") Long projectId);

    /**
     * Count optional skills
     */
    @Query("SELECT COUNT(ps) FROM ProjectSkill ps WHERE ps.project.projectId = :projectId AND ps.isRequired = false")
    long countOptionalSkills(@Param("projectId") Long projectId);

    // =====================================================
    // PROJECTS BY SKILL
    // =====================================================

    /**
     * Find projects requiring a specific skill
     */
    @Query("SELECT ps FROM ProjectSkill ps WHERE ps.skill.skillId = :skillId AND ps.isRequired = true")
    List<ProjectSkill> findProjectsRequiringSkill(@Param("skillId") Long skillId);

    /**
     * Check if skill is required in project
     */
    @Query("SELECT CASE WHEN COUNT(ps) > 0 THEN true ELSE false END " +
            "FROM ProjectSkill ps WHERE ps.project.projectId = :projectId AND ps.skill.skillId = :skillId AND ps.isRequired = true")
    boolean isSkillRequiredInProject(@Param("projectId") Long projectId, @Param("skillId") Long skillId);
}