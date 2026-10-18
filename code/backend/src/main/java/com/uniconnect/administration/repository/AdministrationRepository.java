package com.uniconnect.administration.repository;

import com.uniconnect.administration.domain.*;
import jakarta.persistence.*;
import java.util.*;
import org.springframework.stereotype.Repository;

@Repository
public class AdministrationRepository {
    private final EntityManager em;
    public AdministrationRepository(EntityManager em) { this.em = em; }

    public <T> T insert(T entity) { em.persist(entity); em.flush(); return entity; }

    public Optional<ModerationAction> latestOpenSuspension(long targetUserId) {
        return em.createQuery("select a from ModerationAction a where a.targetUserId=:target "
                        + "and a.actionType=:type and a.reversedAt is null order by a.actionId desc", ModerationAction.class)
                .setParameter("target", targetUserId)
                .setParameter("type", ModerationActionType.SUSPEND_ACCOUNT)
                .setMaxResults(1).getResultStream().findFirst();
    }

    public List<AuditLog> audit(long targetUserId, int page, int size) {
        return em.createQuery("select l from AuditLog l join fetch l.moderationAction a "
                        + "where l.subjectType='USER' and l.subjectId=:target order by l.auditLogId desc", AuditLog.class)
                .setParameter("target", targetUserId).setFirstResult(page * size).setMaxResults(size).getResultList();
    }

    public long auditCount(long targetUserId) {
        return em.createQuery("select count(l) from AuditLog l where l.subjectType='USER' and l.subjectId=:target", Long.class)
                .setParameter("target", targetUserId).getSingleResult();
    }
}
