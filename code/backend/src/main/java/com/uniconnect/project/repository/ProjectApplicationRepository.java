package com.uniconnect.project.repository;

import com.uniconnect.project.domain.*;
import jakarta.persistence.LockModeType;
import java.util.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface ProjectApplicationRepository extends JpaRepository<ProjectApplication, Long> {
    boolean existsByProjectProjectIdAndApplicantUserId(long projectId, long applicantUserId);
    Optional<ProjectApplication> findByProjectProjectIdAndApplicantUserId(long projectId, long applicantUserId);
    List<ProjectApplication> findByProjectProjectIdInAndApplicantUserId(Collection<Long> projectIds,
            long applicantUserId);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from ProjectApplication a where a.applicationId=:id")
    Optional<ProjectApplication> lockById(@Param("id") long id);
    Page<ProjectApplication> findByProjectProjectId(long projectId, Pageable pageable);
    @Query("select a.applicantUserId from ProjectApplication a where a.project.projectId=:project")
    Set<Long> applicantUserIds(@Param("project") long projectId);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from ProjectApplication a where a.project.projectId=:project and a.status=:status order by a.applicationId")
    List<ProjectApplication> lockByProjectAndStatus(@Param("project") long projectId,
            @Param("status") ProjectApplicationStatus status);
}
