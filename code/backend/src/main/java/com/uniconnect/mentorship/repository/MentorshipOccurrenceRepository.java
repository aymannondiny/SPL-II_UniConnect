package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.MentorshipOccurrence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface MentorshipOccurrenceRepository extends JpaRepository<MentorshipOccurrence, Long> {
    List<MentorshipOccurrence> findBySlotSlotIdOrderByStartsAtAsc(Long slotId);

    @Query("""
        select o from MentorshipOccurrence o
        where o.slot.mentorProfile.mentorProfileId = :mentorId
          and o.cancelledAt is null
          and o.startsAt < :endsAt and o.endsAt > :startsAt
          and (:excludedSlotId is null or o.slot.slotId <> :excludedSlotId)
        """)
    List<MentorshipOccurrence> findHostedConflicts(
            @Param("mentorId") Long mentorId,
            @Param("startsAt") LocalDateTime startsAt,
            @Param("endsAt") LocalDateTime endsAt,
            @Param("excludedSlotId") Long excludedSlotId);

    @Query("""
        select case when count(o) > 0 then true else false end from MentorshipOccurrence o
        where o.slot.slotId = :slotId and o.cancelledAt is null and o.startsAt > :now
        """)
    boolean hasFuture(@Param("slotId") Long slotId, @Param("now") LocalDateTime now);
}
