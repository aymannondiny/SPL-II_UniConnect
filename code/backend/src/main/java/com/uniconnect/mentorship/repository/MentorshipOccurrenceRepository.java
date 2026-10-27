package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.MentorshipOccurrence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface MentorshipOccurrenceRepository extends JpaRepository<MentorshipOccurrence, Long> {
    List<MentorshipOccurrence> findBySlotSlotIdOrderByStartsAtAsc(Long slotId);

    List<MentorshipOccurrence> findBySlotSlotIdInOrderByStartsAtAsc(List<Long> slotIds);

    interface Timing {
        Long getSlotId();
        LocalDateTime getLastEnd();
        LocalDateTime getOngoingStart();
        LocalDateTime getNextStart();
    }

    @Query("""
        select o.slot.slotId as slotId, max(o.endsAt) as lastEnd,
          min(case when o.startsAt <= :now and o.endsAt > :now then o.startsAt else null end) as ongoingStart,
          min(case when o.startsAt > :now then o.startsAt else null end) as nextStart
        from MentorshipOccurrence o
        where o.slot.slotId in :slotIds and o.cancelledAt is null
        group by o.slot.slotId
        """)
    List<Timing> summarizeBySlotIds(@Param("slotIds") List<Long> slotIds, @Param("now") LocalDateTime now);

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
