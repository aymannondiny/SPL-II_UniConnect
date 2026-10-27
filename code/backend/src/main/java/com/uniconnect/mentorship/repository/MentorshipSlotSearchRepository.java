package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.MentorshipSlot;
import com.uniconnect.mentorship.domain.SlotMode;
import com.uniconnect.mentorship.domain.SlotStatus;
import com.uniconnect.shared.dto.PageResponse;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/** Filters derived lifecycle state before applying database pagination. */
@Repository
public class MentorshipSlotSearchRepository {
    private final EntityManager em;

    public MentorshipSlotSearchRepository(EntityManager em) { this.em = em; }

    public PageResponse<MentorshipSlot> search(String topic, SlotStatus status, SlotMode mode,
                                              LocalDateTime now, int page, int size) {
        Map<String, Object> parameters = new LinkedHashMap<>();
        StringBuilder where = new StringBuilder("""
                where u.accountStatus = com.uniconnect.shared.security.AccountStatus.ACTIVE
                  and u.anonymizedAt is null
                """);
        if (topic != null && !topic.isBlank()) {
            where.append(" and lower(s.topic) like :topic");
            parameters.put("topic", "%" + topic.strip().toLowerCase(java.util.Locale.ROOT) + "%");
        }
        if (mode != null) {
            where.append(" and s.mode = :mode");
            parameters.put("mode", mode);
        }
        parameters.put("cancelled", SlotStatus.CANCELLED);
        if (status == SlotStatus.CANCELLED) {
            where.append(" and s.status = :cancelled");
        } else {
            where.append(" and s.status <> :cancelled and ");
            if (status == SlotStatus.COMPLETED) where.append("not ");
            where.append("""
                    exists (select 1 from MentorshipOccurrence o where o.slot = s
                      and o.cancelledAt is null and o.endsAt > :now)
                    """);
            parameters.put("now", now);
            if (status == SlotStatus.CLOSED) {
                where.append(" and s.enrollmentOpen = false");
            } else if (status != SlotStatus.COMPLETED) {
                where.append(" and s.enrollmentOpen = true");
                if (status == SlotStatus.OPEN || status == SlotStatus.FULL) {
                    where.append(" and (select count(e) from MentorshipEnrollment e where e.slot = s")
                            .append(" and e.status = 'ACTIVE') ")
                            .append(status == SlotStatus.OPEN ? "<" : ">=").append(" s.capacity");
                }
            }
        }

        var rows = em.createQuery("select s from MentorshipSlot s join fetch s.mentorProfile m "
                + "join fetch m.user u " + where + " order by s.startDate, s.startTime, s.slotId", MentorshipSlot.class);
        var count = em.createQuery("select count(s) from MentorshipSlot s join s.mentorProfile m "
                + "join m.user u " + where, Long.class);
        parameters.forEach((key, value) -> {
            rows.setParameter(key, value);
            count.setParameter(key, value);
        });
        rows.setFirstResult((int) Math.min((long) page * size, Integer.MAX_VALUE)).setMaxResults(size);
        return new PageResponse<>(rows.getResultList(), page, size, count.getSingleResult());
    }
}
