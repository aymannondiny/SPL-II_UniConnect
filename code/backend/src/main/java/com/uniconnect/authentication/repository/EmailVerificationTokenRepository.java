package com.uniconnect.authentication.repository;

import com.uniconnect.authentication.domain.EmailVerificationToken;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface EmailVerificationTokenRepository extends JpaRepository<EmailVerificationToken, Long> {
    @Query("select t.user.userId from EmailVerificationToken t where t.tokenHash = :hash")
    Optional<Long> findOwnerIdByTokenHash(@Param("hash") String hash);

    Optional<EmailVerificationToken> findByTokenHash(String tokenHash);
    List<EmailVerificationToken> findByUserUserIdAndUsedAtIsNullAndRevokedAtIsNull(Long userId);
}
