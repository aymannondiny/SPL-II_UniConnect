package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.MentorshipSlot;
import com.uniconnect.mentorship.domain.SlotStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public interface MentorshipSlotRepository extends JpaRepository<MentorshipSlot, Long> {

    List<MentorshipSlot> findByMentorProfileMentorProfileIdOrderByStartDateAscStartTimeAsc(Long mentorProfileId);

    List<MentorshipSlot> findByMentorProfileUserUserIdOrderByStartDateAscStartTimeAsc(Long userId);

    @Query(value = """
        SELECT s FROM MentorshipSlot s
        WHERE s.status IN (:statuses)
        AND s.mentorProfile.user.accountStatus = com.uniconnect.shared.security.AccountStatus.ACTIVE
        AND s.mentorProfile.user.anonymizedAt IS NULL
    """, countQuery = """
        SELECT count(s) FROM MentorshipSlot s
        WHERE s.status IN (:statuses)
        AND s.mentorProfile.user.accountStatus = com.uniconnect.shared.security.AccountStatus.ACTIVE
        AND s.mentorProfile.user.anonymizedAt IS NULL
    """)
    Page<MentorshipSlot> findActiveSlotsByStatusIn(
            @Param("statuses") List<SlotStatus> statuses,
            Pageable pageable
    );

    @Query(value = """
        SELECT s FROM MentorshipSlot s
        WHERE s.status IN (:statuses)
        AND s.mentorProfile.user.accountStatus = com.uniconnect.shared.security.AccountStatus.ACTIVE
        AND s.mentorProfile.user.anonymizedAt IS NULL
        AND LOWER(s.topic) LIKE LOWER(CONCAT('%', :topic, '%'))
    """, countQuery = """
        SELECT count(s) FROM MentorshipSlot s
        WHERE s.status IN (:statuses)
        AND s.mentorProfile.user.accountStatus = com.uniconnect.shared.security.AccountStatus.ACTIVE
        AND s.mentorProfile.user.anonymizedAt IS NULL
        AND LOWER(s.topic) LIKE LOWER(CONCAT('%', :topic, '%'))
    """)
    Page<MentorshipSlot> findActiveSlotsByStatusInAndTopicContaining(
            @Param("statuses") List<SlotStatus> statuses,
            @Param("topic") String topic,
            Pageable pageable
    );

    @Query("""
        SELECT s FROM MentorshipSlot s
        WHERE s.mentorProfile.mentorProfileId = :mentorProfileId
        AND s.status NOT IN ('CANCELLED')
        AND s.startDate = :startDate
        AND s.startTime < :endTime
        AND s.endTime > :startTime
    """)
    List<MentorshipSlot> findConflictingSlots(
            @Param("mentorProfileId") Long mentorProfileId,
            @Param("startDate") LocalDate startDate,
            @Param("startTime") LocalTime startTime,
            @Param("endTime") LocalTime endTime
    );
}
