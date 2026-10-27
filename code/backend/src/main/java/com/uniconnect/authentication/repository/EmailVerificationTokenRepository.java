package com.uniconnect.authentication.repository;

import com.uniconnect.authentication.domain.EmailVerificationToken;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EmailVerificationTokenRepository extends JpaRepository<EmailVerificationToken, Long> {
    List<EmailVerificationToken> findByUserUserIdAndUsedAtIsNullAndRevokedAtIsNull(Long userId);
    Optional<EmailVerificationToken> findFirstByUserUserIdOrderByCreatedAtDescTokenIdDesc(Long userId);
    Optional<EmailVerificationToken> findFirstByUserUserIdAndUsedAtIsNullAndRevokedAtIsNullOrderByCreatedAtDescTokenIdDesc(Long userId);
    long countByUserUserIdAndCreatedAtAfter(Long userId, LocalDateTime cutoff);
}
