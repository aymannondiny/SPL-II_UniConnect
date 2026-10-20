package com.uniconnect.project.repository;

import com.uniconnect.project.domain.Project;
import jakarta.persistence.LockModeType;
import java.util.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface ProjectRepository extends JpaRepository<Project, Long>, JpaSpecificationExecutor<Project> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Project p where p.projectId=:id")
    Optional<Project> lockById(@Param("id") long id);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Project p where p.creatorUserId=:creator order by p.projectId")
    List<Project> lockAllByCreator(@Param("creator") long creatorUserId);
}
