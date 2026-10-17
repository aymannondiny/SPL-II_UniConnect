package com.uniconnect.profile.repository;

import com.uniconnect.profile.domain.ProgrammeDegree;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface ProgrammeDegreeRepository extends JpaRepository<ProgrammeDegree, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select e from ProgrammeDegree e where e.programmeDegreeId = :id")
    Optional<ProgrammeDegree> lockById(@Param("id") Long id);
}
