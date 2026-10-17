package com.uniconnect.authentication.repository;

import com.uniconnect.authentication.domain.AuthenticatedSession;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface AuthenticatedSessionRepository extends JpaRepository<AuthenticatedSession, UUID> {
    @Query("select s from AuthenticatedSession s join fetch s.user where s.accessTokenHash = :hash")
    Optional<AuthenticatedSession> findByAccessHash(@Param("hash") String hash);

    @Query("select s.user.userId from AuthenticatedSession s where s.refreshTokenHash = :hash")
    Optional<Long> findOwnerByRefreshHash(@Param("hash") String hash);

    @Query("select s from AuthenticatedSession s where s.refreshTokenHash = :hash")
    Optional<AuthenticatedSession> findByRefreshHash(@Param("hash") String hash);

    @Modifying
    @Query("update AuthenticatedSession s set s.revokedAt = :now, s.revocationReason = :reason "
            + "where s.user.userId = :userId and s.revokedAt is null")
    int revokeAll(@Param("userId") Long userId, @Param("now") LocalDateTime now,
            @Param("reason") String reason);
}
