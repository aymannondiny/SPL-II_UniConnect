package com.uniconnect.club.publication.repository;

import com.uniconnect.club.domain.ClubStatus;
import com.uniconnect.club.publication.domain.*;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.*;
import org.springframework.stereotype.Repository;

@Repository
public class PublicationRepository {
    private final EntityManager em;
    public PublicationRepository(EntityManager em) { this.em = em; }
    public <T> T insert(T entity) { em.persist(entity); em.flush(); return entity; }
    public Announcement announcement(long id) { return em.find(Announcement.class, id); }
    public ClubEvent event(long id) { return em.find(ClubEvent.class, id); }
    public PublicationAudit audit(long id) { return em.find(PublicationAudit.class,id); }
    public record Slice<T>(List<T> items, long total) {}

    public Slice<Announcement> announcements(Long club, String category, AnnouncementPriority priority,
            LocalDateTime from, LocalDateTime before, Long ownerAssignment, boolean management,
            AnnouncementStatus status, LocalDateTime now, int page, int size) {
        var params = new LinkedHashMap<String, Object>();
        StringBuilder where = new StringBuilder(" from Announcement a, Club c where a.clubId=c.clubId");
        add(where, params, "c.status<>:removedClub", "removedClub", ClubStatus.REMOVED);
        if (club != null) add(where, params, "a.clubId=:club", "club", club);
        if (category != null) add(where, params, "lower(c.category)=:category", "category", category);
        if (priority != null) add(where, params, "a.priority=:priority", "priority", priority);
        if (from != null) add(where, params, "a.publishedAt>=:fromDate", "fromDate", from);
        if (before != null) add(where, params, "a.publishedAt<:beforeDate", "beforeDate", before);
        if (ownerAssignment != null) add(where, params, "a.authorAssignmentId=:owner", "owner", ownerAssignment);
        var requested = management ? status : AnnouncementStatus.PUBLISHED;
        if (requested != null) {
            if (requested == AnnouncementStatus.PUBLISHED || requested == AnnouncementStatus.EXPIRED) {
                add(where, params, "a.status=:status", "status", AnnouncementStatus.PUBLISHED);
                add(where, params, requested == AnnouncementStatus.PUBLISHED
                        ? "(a.expiresAt is null or a.expiresAt>:now)" : "a.expiresAt<=:now", "now", now);
            } else add(where, params, "a.status=:status", "status", requested);
        }
        return page(Announcement.class, "a", where.toString(), params,
                management ? "a.createdAt desc,a.announcementId desc" : "a.publishedAt desc,a.announcementId desc", page, size);
    }
    public Slice<ClubEvent> events(Long club, String category, Long ownerAssignment, boolean management,
            EventStatus status, EventTiming timing, boolean history, LocalDateTime now, int page, int size) {
        var params = new LinkedHashMap<String, Object>();
        var where = new StringBuilder(" from ClubEvent e, Club c where e.clubId=c.clubId");
        add(where, params, "c.status<>:removedClub", "removedClub", ClubStatus.REMOVED);
        if (club != null) add(where, params, "e.clubId=:club", "club", club);
        if (category != null) add(where, params, "lower(c.category)=:category", "category", category);
        if (ownerAssignment != null) add(where, params, "e.authorAssignmentId=:owner", "owner", ownerAssignment);
        var requested = management ? status : EventStatus.PUBLISHED;
        if (requested != null) add(where, params, "e.status=:status", "status", requested);
        if (!management) add(where, params, history ? "e.endsAt<:now" : "e.endsAt>=:now", "now", now);
        if (timing != null) add(where, params, switch (timing) {
            case UPCOMING -> "e.startsAt>:now";
            case ACTIVE -> "e.startsAt<=:now and e.endsAt>=:now";
            case PAST -> "e.endsAt<:now";
        }, "now", now);
        String order = management ? "e.eventId desc" : history ? "e.endsAt desc,e.eventId desc" : "e.startsAt,e.eventId";
        return page(ClubEvent.class, "e", where.toString(), params, order, page, size);
    }
    public Slice<PublicationAudit> audit(long club, int page, int size) {
        return page(PublicationAudit.class, "a", " from PublicationAudit a where a.clubId=:club", Map.of("club", club), "a.auditId desc", page, size);
    }
    private void add(StringBuilder where, Map<String, Object> params, String predicate, String name, Object value) {
        where.append(" and (").append(predicate).append(")"); params.put(name, value);
    }
    private <T> Slice<T> page(Class<T> type, String alias, String where, Map<String, Object> params, String order, int page, int size) {
        var query = em.createQuery("select " + alias + where + " order by " + order, type);
        var count = em.createQuery("select count(" + alias + ")" + where, Long.class);
        params.forEach((key, value) -> { query.setParameter(key, value); count.setParameter(key, value); });
        return new Slice<>(query.setFirstResult(page * size).setMaxResults(size).getResultList(), count.getSingleResult());
    }
}
