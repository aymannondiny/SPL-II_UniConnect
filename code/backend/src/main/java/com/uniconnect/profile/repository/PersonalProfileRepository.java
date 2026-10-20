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
}
