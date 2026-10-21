package com.uniconnect.project.repository;

import com.uniconnect.project.domain.ProjectMembership;
import java.util.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface ProjectMembershipRepository extends JpaRepository<ProjectMembership, Long> {
    long countByProjectProjectId(long projectId);
    boolean existsByProjectProjectIdAndMemberUserId(long projectId, long memberUserId);
    List<ProjectMembership> findByProjectProjectIdOrderByMembershipId(long projectId);
    @Query("select m.memberUserId from ProjectMembership m where m.project.projectId=:project")
    Set<Long> memberUserIds(@Param("project") long projectId);
    @Query("select m.project.projectId, count(m) from ProjectMembership m where m.project.projectId in :ids group by m.project.projectId")
    List<Object[]> counts(@Param("ids") Collection<Long> ids);
    @Query("select m.project.projectId from ProjectMembership m where m.project.projectId in :ids and m.memberUserId=:member")
    Set<Long> projectIdsForMember(@Param("ids") Collection<Long> ids, @Param("member") long memberUserId);
}
