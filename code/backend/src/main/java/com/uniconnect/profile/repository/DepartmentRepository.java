package com.uniconnect.profile.repository;

import com.uniconnect.profile.domain.Department;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface DepartmentRepository extends JpaRepository<Department, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select e from Department e where e.departmentId = :id")
    Optional<Department> lockById(@Param("id") Long id);
}
