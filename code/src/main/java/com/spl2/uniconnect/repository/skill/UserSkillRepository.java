package com.spl2.uniconnect.repository.skill;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.spl2.uniconnect.domain.skill.UserSkill;

import java.util.List;

@Repository
public interface UserSkillRepository extends JpaRepository<UserSkill, Long> {

    /**
     * Get all skills for a user
     */
    List<UserSkill> findByUserUserId(Long userId);

    /**
     * Get skill names for a user
     */
    @Query("SELECT us.skill.skillName FROM UserSkill us WHERE us.user.userId = :userId")
    List<String> getSkillNamesByUser(@Param("userId") Long userId);

    /**
     * Check if user has a specific skill
     */
    @Query("SELECT CASE WHEN COUNT(us) > 0 THEN true ELSE false END " +
            "FROM UserSkill us WHERE us.user.userId = :userId AND us.skill.skillName = :skillName")
    boolean userHasSkill(@Param("userId") Long userId, @Param("skillName") String skillName);

    /**
     * Count skills for a user
     */
    long countByUserUserId(Long userId);
}