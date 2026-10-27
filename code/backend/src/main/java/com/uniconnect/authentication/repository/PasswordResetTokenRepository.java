package com.uniconnect.authentication.repository;

import com.uniconnect.authentication.domain.PasswordResetToken;
import java.util.List;
import java.util.Optional;
import java.time.LocalDateTime;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {
    Optional<PasswordResetToken> findFirstByUserUserIdOrderByCreatedAtDescTokenIdDesc(Long userId);

    Optional<PasswordResetToken> findFirstByUserUserIdAndUsedAtIsNullAndRevokedAtIsNullOrderByCreatedAtDescTokenIdDesc(Long userId);

    long countByUserUserIdAndCreatedAtAfter(Long userId, LocalDateTime since);
    List<PasswordResetToken> findByUserUserIdAndUsedAtIsNullAndRevokedAtIsNull(Long userId);
}
