package com.spl2.uniconnect.repository.user;

import com.spl2.uniconnect.domain.user.TokenType;
import com.spl2.uniconnect.domain.user.VerificationToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface VerificationTokenRepository extends JpaRepository<VerificationToken, Long> {

    // =====================================================
    // BASIC LOOKUPS
    // =====================================================
    Optional<VerificationToken> findByToken(String token);
    Optional<VerificationToken> findByUserUserIdAndTokenType(
            Long userId,
            TokenType tokenType
    );
    boolean existsByToken(String token);

    // =====================================================
    // VALIDATION QUERIES
    // =====================================================
    @Query("SELECT vt FROM VerificationToken vt WHERE " +
            "vt.token = :token AND " +
            "vt.expiresAt > :now")
    Optional<VerificationToken> findValidToken(
            @Param("token") String token,
            @Param("now") LocalDateTime now
    );
    @Query("SELECT vt FROM VerificationToken vt WHERE " +
            "vt.user.userId = :userId AND " +
            "vt.tokenType = :tokenType AND " +
            "vt.expiresAt > :now")
    Optional<VerificationToken> findValidTokenByUserAndType(
            @Param("userId") Long userId,
            @Param("tokenType") TokenType tokenType,
            @Param("now") LocalDateTime now
    );

    // =====================================================
    // CLEANUP QUERIES
    // =====================================================
    @Modifying
    @Query("DELETE FROM VerificationToken vt WHERE vt.expiresAt < :now")
    int deleteAllExpiredTokens(@Param("now") LocalDateTime now);
    @Modifying
    @Query("DELETE FROM VerificationToken vt WHERE " +
            "vt.user.userId = :userId AND " +
            "vt.tokenType = :tokenType")
    void deleteByUserIdAndTokenType(
            @Param("userId") Long userId,
            @Param("tokenType") TokenType tokenType
    );
}