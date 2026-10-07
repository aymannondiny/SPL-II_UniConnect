package com.uniconnect.authentication.repository;

import com.uniconnect.authentication.domain.PasswordResetToken;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {
    @Query("select t.user.userId from PasswordResetToken t where t.tokenHash = :hash")
    Optional<Long> findOwnerIdByTokenHash(@Param("hash") String hash);

    Optional<PasswordResetToken> findByTokenHash(String tokenHash);
    List<PasswordResetToken> findByUserUserIdAndUsedAtIsNullAndRevokedAtIsNull(Long userId);
}
