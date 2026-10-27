package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.EnrollmentStatus;
import com.uniconnect.mentorship.domain.MentorshipEnrollment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MentorshipEnrollmentRepository extends JpaRepository<MentorshipEnrollment, Long> {

    Optional<MentorshipEnrollment> findFirstBySlotSlotIdAndMenteeUserIdOrderByJoinedAtDesc(Long slotId, Long menteeId);

    Optional<MentorshipEnrollment> findBySlotSlotIdAndMenteeUserIdAndStatus(Long slotId, Long menteeId, EnrollmentStatus status);

    List<MentorshipEnrollment> findBySlotSlotIdAndStatus(Long slotId, EnrollmentStatus status);

    @EntityGraph(attributePaths = {"slot", "slot.mentorProfile", "slot.mentorProfile.user"})
    List<MentorshipEnrollment> findByMenteeUserIdAndStatusOrderByJoinedAtDesc(Long menteeId, EnrollmentStatus status);

    List<MentorshipEnrollment> findByMenteeUserIdOrderByJoinedAtDescEnrollmentIdDesc(Long menteeId);

    boolean existsBySlotSlotIdAndMenteeUserIdAndStatus(Long slotId, Long menteeId, EnrollmentStatus status);

    @Query("SELECT count(e) FROM MentorshipEnrollment e WHERE e.slot.slotId = :slotId AND e.status = 'ACTIVE'")
    long countActiveBySlotId(@Param("slotId") Long slotId);

    interface ActiveCount {
        Long getSlotId();
        Long getTotal();
    }

    @Query("""
        select e.slot.slotId as slotId, count(e) as total from MentorshipEnrollment e
        where e.slot.slotId in :slotIds and e.status = 'ACTIVE'
        group by e.slot.slotId
        """)
    List<ActiveCount> countActiveBySlotIds(@Param("slotIds") List<Long> slotIds);

    @Query("""
        select distinct e.slot.slotId from MentorshipEnrollment e
        where e.slot.slotId in :slotIds and e.mentee.userId = :viewerId and e.status = 'ACTIVE'
        """)
    List<Long> findActiveSlotIds(@Param("slotIds") List<Long> slotIds, @Param("viewerId") Long viewerId);
}
