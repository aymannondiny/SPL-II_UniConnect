package com.uniconnect.profile.repository;

import com.uniconnect.profile.domain.PersonalProfile;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PersonalProfileRepository extends JpaRepository<PersonalProfile, Long> {
    Optional<PersonalProfile> findByUserUserId(Long userId);
    boolean existsByProgrammeDegreeProgrammeDegreeId(Long degreeId);
}
