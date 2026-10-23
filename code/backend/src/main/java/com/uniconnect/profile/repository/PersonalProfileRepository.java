package com.uniconnect.profile.repository;

import com.uniconnect.profile.domain.PersonalProfile;
import java.util.Optional;
import java.util.Collection;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PersonalProfileRepository extends JpaRepository<PersonalProfile, Long> {
    Optional<PersonalProfile> findByUserUserId(Long userId);
    boolean existsByProgrammeDegreeProgrammeDegreeId(Long degreeId);
    @Query("select p.user.userId from PersonalProfile p where p.programmeDegree.programme.department.departmentId=:department")
    List<Long> findUserIdsByDepartment(@Param("department") long departmentId);

    @Query("select p from PersonalProfile p join fetch p.programmeDegree d join fetch d.programme pr "
            + "join fetch pr.department where p.user.userId in :users")
    List<PersonalProfile> findAcademicProfiles(@Param("users") Collection<Long> userIds);

    @Query("select distinct p from PersonalProfile p join fetch p.user u "
            + "join fetch p.programmeDegree d join fetch d.programme pr join fetch pr.department "
            + "left join fetch p.skills left join fetch p.interests where type(p) = StudentProfile "
            + "and u.accountStatus = com.uniconnect.shared.security.AccountStatus.ACTIVE "
            + "and u.anonymizedAt is null and u.platformRole = com.uniconnect.shared.security.PlatformRole.STUDENT "
            + "and treat(p as StudentProfile).projectAvailability = true "
            + "and u.userId not in :excludedUsers "
            + "and (p.detailsVisibility = com.uniconnect.profile.domain.ProfileVisibility.ALL_MEMBERS "
            + "or u.userId in :visibleUsers) "
            + "and exists (select matchingSkill.skillId from PersonalProfile matchingProfile "
            + "join matchingProfile.skills matchingSkill where matchingProfile.profileId = p.profileId "
            + "and matchingSkill.name in :skillNames)")
    List<PersonalProfile> findAvailableProjectCandidates(@Param("excludedUsers") Collection<Long> excludedUsers,
            @Param("visibleUsers") Collection<Long> visibleUsers, @Param("skillNames") Collection<String> skillNames);
}
