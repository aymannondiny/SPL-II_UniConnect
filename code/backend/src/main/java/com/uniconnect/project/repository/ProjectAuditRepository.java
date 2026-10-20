package com.uniconnect.project.repository;
import com.uniconnect.project.domain.ProjectAudit;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;
public interface ProjectAuditRepository extends JpaRepository<ProjectAudit, Long> {
    Page<ProjectAudit> findByProjectId(long projectId, Pageable pageable);
}
