package com.spl2.uniconnect.repository.project;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.spl2.uniconnect.domain.project.ProjectTag;

import java.util.List;

@Repository
public interface ProjectTagRepository extends JpaRepository<ProjectTag, Long> {

    /**
     * Find all tags for a project
     */
    @Query("SELECT pt.tag.tagName FROM ProjectTag pt WHERE pt.project.projectId = :projectId")
    List<String> findTagsByProject(@Param("projectId") Long projectId);

    /**
     * Find all project tags
     */
    List<ProjectTag> findByProjectProjectId(Long projectId);
}