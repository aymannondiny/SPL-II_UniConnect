package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.EnrollmentStatus;
import com.uniconnect.mentorship.domain.MentorshipEnrollment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MentorshipEnrollmentRepository extends JpaRepository<MentorshipEnrollment, Long> {

    Optional<MentorshipEnrollment> findBySlotSlotIdAndMenteeUserId(Long slotId, Long menteeId);

    List<MentorshipEnrollment> findBySlotSlotIdAndStatus(Long slotId, EnrollmentStatus status);

    List<MentorshipEnrollment> findByMenteeUserIdAndStatusOrderByJoinedAtDesc(Long menteeId, EnrollmentStatus status);

    boolean existsBySlotSlotIdAndMenteeUserIdAndStatus(Long slotId, Long menteeId, EnrollmentStatus status);

    @Query("SELECT count(e) FROM MentorshipEnrollment e WHERE e.slot.slotId = :slotId AND e.status = 'ACTIVE'")
    long countActiveBySlotId(@Param("slotId") Long slotId);
}
