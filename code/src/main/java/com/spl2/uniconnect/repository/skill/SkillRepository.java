package com.spl2.uniconnect.repository.skill;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.spl2.uniconnect.domain.skill.Skill;

import java.util.Optional;

@Repository
public interface SkillRepository extends JpaRepository<Skill, Long> {

    /**
     * Find skill by name
     */
    Optional<Skill> findBySkillName(String skillName);

    /**
     * Find skill by name (case-insensitive)
     */
    @Query("SELECT s FROM Skill s WHERE LOWER(s.skillName) = LOWER(:skillName)")
    Optional<Skill> findBySkillNameIgnoreCase(@Param("skillName") String skillName);

    /**
     * Check if skill exists
     */
    @Query("SELECT CASE WHEN COUNT(s) > 0 THEN true ELSE false END FROM Skill s WHERE LOWER(s.skillName) = LOWER(:skillName)")
    boolean existsBySkillNameIgnoreCase(@Param("skillName") String skillName);

    /**
     * Find skills by category
     */
    java.util.List<Skill> findByCategory(String category);
}