package com.uniconnect.authentication.repository;

import com.uniconnect.authentication.domain.User;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Page;
import com.uniconnect.shared.security.AccountStatus;
import com.uniconnect.shared.security.PlatformRole;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from User u where u.userId = :id")
    Optional<User> findForUpdateById(@Param("id") Long id);

    @Lock(LockModeType.PESSIMISTIC_READ)
    @Query("select u from User u where u.userId = :id")
    Optional<User> findForReadById(@Param("id") Long id);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from User u where u.email = :email")
    Optional<User> findForUpdateByEmail(@Param("email") String email);

    boolean existsByEmail(String email);

    @Query("select u from User u where "
            + "(:term = '' or lower(coalesce(u.fullName, '')) like concat('%', :term, '%') "
            + "or lower(coalesce(u.email, '')) like concat('%', :term, '%')) "
            + "and (:role is null or u.platformRole = :role) "
            + "and (:status is null or u.accountStatus = :status)")
    Page<User> searchForAdministration(@Param("term") String term,
            @Param("role") PlatformRole role, @Param("status") AccountStatus status, Pageable pageable);

    @Query("select u from User u where u.platformRole = :role and u.accountStatus = :status " +
            "and u.anonymizedAt is null and (:term = '' or lower(coalesce(u.fullName, '')) like concat('%', :term, '%') " +
            "or lower(coalesce(u.email, '')) like concat('%', :term, '%'))")
    Page<User> searchEligibleClubAdministrators(@Param("term") String term,
            @Param("role") PlatformRole role, @Param("status") AccountStatus status, Pageable pageable);
}
