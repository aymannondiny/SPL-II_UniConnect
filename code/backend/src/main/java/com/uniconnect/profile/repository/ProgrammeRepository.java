package com.uniconnect.profile.repository;

import com.uniconnect.profile.domain.Programme;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface ProgrammeRepository extends JpaRepository<Programme, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select e from Programme e where e.programmeId = :id")
    Optional<Programme> lockById(@Param("id") Long id);
}
