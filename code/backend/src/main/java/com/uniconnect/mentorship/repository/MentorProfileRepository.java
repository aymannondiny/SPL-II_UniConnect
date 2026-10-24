package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.MentorProfile;
import com.uniconnect.mentorship.domain.MentorStatus;
import com.uniconnect.shared.security.AccountStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import jakarta.persistence.LockModeType;

import java.util.Optional;

public interface MentorProfileRepository extends JpaRepository<MentorProfile, Long> {

    Optional<MentorProfile> findByUserUserId(Long userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select m from MentorProfile m where m.user.userId = :userId")
    Optional<MentorProfile> findLockedByUserId(@Param("userId") Long userId);

    boolean existsByUserUserId(Long userId);

    @Query(value = """
        SELECT m FROM MentorProfile m
        WHERE m.status = :status
        AND m.user.accountStatus = :accountStatus
        AND m.user.anonymizedAt IS NULL
    """, countQuery = """
        SELECT count(m) FROM MentorProfile m
        WHERE m.status = :status
        AND m.user.accountStatus = :accountStatus
        AND m.user.anonymizedAt IS NULL
    """)
    Page<MentorProfile> findActiveByStatus(
            @Param("status") MentorStatus status,
            @Param("accountStatus") AccountStatus accountStatus,
            Pageable pageable
    );

    @Query(value = """
        SELECT DISTINCT m FROM MentorProfile m
        JOIN m.expertise e
        JOIN e.skill s
        WHERE m.status = :status
        AND m.user.accountStatus = :accountStatus
        AND m.user.anonymizedAt IS NULL
        AND LOWER(s.name) LIKE LOWER(CONCAT('%', :topic, '%'))
    """, countQuery = """
        SELECT count(DISTINCT m) FROM MentorProfile m
        JOIN m.expertise e
        JOIN e.skill s
        WHERE m.status = :status
        AND m.user.accountStatus = :accountStatus
        AND m.user.anonymizedAt IS NULL
        AND LOWER(s.name) LIKE LOWER(CONCAT('%', :topic, '%'))
    """)
    Page<MentorProfile> findActiveByStatusAndTopicContaining(
            @Param("status") MentorStatus status,
            @Param("accountStatus") AccountStatus accountStatus,
            @Param("topic") String topic,
            Pageable pageable
    );

    default Page<MentorProfile> findActiveByStatus(MentorStatus status, Pageable pageable) {
        return findActiveByStatus(status, AccountStatus.ACTIVE, pageable);
    }

    default Page<MentorProfile> findActiveByStatusAndTopicContaining(MentorStatus status, String topic, Pageable pageable) {
        return findActiveByStatusAndTopicContaining(status, AccountStatus.ACTIVE, topic, pageable);
    }
}
