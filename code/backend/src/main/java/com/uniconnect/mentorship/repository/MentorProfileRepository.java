package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.MentorProfile;
import com.uniconnect.mentorship.domain.MentorStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface MentorProfileRepository extends JpaRepository<MentorProfile, Long> {

    Optional<MentorProfile> findByUserUserId(Long userId);

    boolean existsByUserUserId(Long userId);

    Page<MentorProfile> findByStatus(MentorStatus status, Pageable pageable);

    @Query("""
        SELECT DISTINCT m FROM MentorProfile m
        JOIN m.expertise e
        WHERE m.status = :status
        AND LOWER(e.topic) LIKE LOWER(CONCAT('%', :topic, '%'))
    """)
    Page<MentorProfile> findByStatusAndTopicContaining(
            @Param("status") MentorStatus status,
            @Param("topic") String topic,
            Pageable pageable
    );
}
