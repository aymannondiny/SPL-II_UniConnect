package com.uniconnect.club.repository;

import com.uniconnect.club.domain.*;
import jakarta.persistence.*;
import java.util.*;
import org.springframework.stereotype.Repository;

@Repository
public class ClubRepository {
    private final EntityManager em;
    public ClubRepository(EntityManager em) { this.em = em; }
    public <T> T insert(T entity) { em.persist(entity); em.flush(); return entity; }
    public void flush() { em.flush(); }
    public Club find(long id) { return em.find(Club.class, id); }
    public Club lock(long id) { return em.find(Club.class, id, LockModeType.PESSIMISTIC_WRITE); }
    public ClubRoleAssignment assignment(long id) { return em.find(ClubRoleAssignment.class, id); }
    public Optional<Long> assignmentClub(long id) {
        return em.createQuery("select a.clubId from ClubRoleAssignment a where a.assignmentId=:id", Long.class).setParameter("id", id).getResultStream().findFirst();
    }
    public boolean nameExists(String key) {
        return em.createQuery("select count(c) from Club c where c.nameKey=:key", Long.class).setParameter("key", key).getSingleResult() > 0;
    }
    public long countByStatus(ClubStatus status) {
        return em.createQuery("select count(c) from Club c where c.status=:status", Long.class)
                .setParameter("status", status).getSingleResult();
    }
    public Optional<ClubRoleAssignment> administrator(long club) {
        return em.createQuery("select a from ClubRoleAssignment a where a.administratorClubId=:club order by a.assignmentId", ClubRoleAssignment.class).setParameter("club", club).setMaxResults(1).getResultStream().findFirst();
    }
    public List<ClubRoleAssignment> administrators(long club) {
        return em.createQuery("select a from ClubRoleAssignment a where a.administratorClubId=:club order by a.userId", ClubRoleAssignment.class)
                .setParameter("club", club).getResultList();
    }
    public boolean hasOtherEligibleAdministrator(long club, long excludingUser) {
        Number count = (Number) em.createNativeQuery("select count(*) from club_role_assignments a join users u on u.user_id=a.user_id " +
                "where a.administrator_club_id=:club and a.user_id<>:user and a.revoked_at is null " +
                "and u.platform_role='STUDENT' and u.account_status='ACTIVE' and u.anonymized_at is null")
                .setParameter("club", club).setParameter("user", excludingUser).getSingleResult();
        return count.longValue() > 0;
    }
    public boolean administersAny(long user) {
        return em.createQuery("select count(a) from ClubRoleAssignment a where a.administratorUserId=:user", Long.class).setParameter("user", user).getSingleResult() > 0;
    }
    /** Scalar query deliberately bypasses managed assignment instances for concurrency rechecks. */
    public List<Long> administeredClubIds(long user) {
        return em.createQuery("select a.clubId from ClubRoleAssignment a where a.administratorUserId=:user order by a.clubId", Long.class)
                .setParameter("user", user).getResultList();
    }
    public Optional<ClubRoleAssignment> current(long club, long user) {
        return em.createQuery("select a from ClubRoleAssignment a where a.currentClubId=:club and a.currentUserId=:user", ClubRoleAssignment.class)
                .setParameter("club", club).setParameter("user", user).getResultStream().findFirst();
    }
    public List<ClubRoleAssignment> contexts(long user) {
        return em.createQuery("select a from ClubRoleAssignment a, Club c where a.clubId=c.clubId and a.userId=:user and a.revokedAt is null and c.status<>:removed and c.status<>:archived order by c.nameKey,c.clubId", ClubRoleAssignment.class)
                .setParameter("user", user).setParameter("removed", ClubStatus.REMOVED)
                .setParameter("archived", ClubStatus.ARCHIVED).getResultList();
    }
    public List<Club> directory(String search, int page, int size) {
        return em.createQuery("select c from Club c where c.status<>:removed and c.status<>:archived and (locate(:q,c.nameKey)>0 or locate(:q,lower(c.category))>0) order by c.nameKey,c.clubId", Club.class)
                .setParameter("removed", ClubStatus.REMOVED).setParameter("archived", ClubStatus.ARCHIVED)
                .setParameter("q", search).setFirstResult(page*size).setMaxResults(size).getResultList();
    }
    public List<Club> adminDirectory(String search, int page, int size) {
        return em.createQuery("select c from Club c where c.status<>:removed and (locate(:q,c.nameKey)>0 or locate(:q,lower(c.category))>0) order by c.nameKey,c.clubId", Club.class)
                .setParameter("removed", ClubStatus.REMOVED).setParameter("q", search)
                .setFirstResult(page*size).setMaxResults(size).getResultList();
    }
    public long adminDirectoryCount(String search) {
        return em.createQuery("select count(c) from Club c where c.status<>:removed and (locate(:q,c.nameKey)>0 or locate(:q,lower(c.category))>0)", Long.class)
                .setParameter("removed", ClubStatus.REMOVED).setParameter("q", search).getSingleResult();
    }
    public long directoryCount(String search) {
        return em.createQuery("select count(c) from Club c where c.status<>:removed and c.status<>:archived and (locate(:q,c.nameKey)>0 or locate(:q,lower(c.category))>0)", Long.class)
                .setParameter("removed", ClubStatus.REMOVED).setParameter("archived", ClubStatus.ARCHIVED)
                .setParameter("q", search).getSingleResult();
    }
    public List<ClubRoleAssignment> operators(long club, String filter, int page, int size) {
        return em.createQuery("select a from ClubRoleAssignment a where a.clubId=:club"+filter(filter)+" order by a.assignmentId desc", ClubRoleAssignment.class)
                .setParameter("club", club).setFirstResult(page*size).setMaxResults(size).getResultList();
    }
    public List<ClubRoleAssignment> currentOperators(long club) {
        return em.createQuery("select a from ClubRoleAssignment a where a.clubId=:club and a.revokedAt is null order by a.userId", ClubRoleAssignment.class)
                .setParameter("club", club).getResultList();
    }
    public long operatorCount(long club, String filter) {
        return em.createQuery("select count(a) from ClubRoleAssignment a where a.clubId=:club"+filter(filter), Long.class).setParameter("club", club).getSingleResult();
    }
    private String filter(String filter) { return switch(filter) { case "CURRENT" -> " and a.revokedAt is null"; case "REVOKED" -> " and a.revokedAt is not null"; default -> ""; }; }
    public List<ClubAudit> audit(long club, int page, int size) {
        return em.createQuery("select a from ClubAudit a where a.clubId=:club order by a.auditId desc", ClubAudit.class)
                .setParameter("club", club).setFirstResult(page*size).setMaxResults(size).getResultList();
    }
    public long auditCount(long club) { return em.createQuery("select count(a) from ClubAudit a where a.clubId=:club", Long.class).setParameter("club", club).getSingleResult(); }
    public ClubAudit audit(long id) { return em.find(ClubAudit.class,id); }
    public ClubAudit lockAudit(long id) { return em.find(ClubAudit.class,id,LockModeType.PESSIMISTIC_WRITE); }
    public ClubAudit lockLatestPublishingSuspension(long club) {
        return em.createQuery("select a from ClubAudit a where a.clubId=:club and a.action='CLUB_PUBLISHING_SUSPENDED' order by a.auditId desc",ClubAudit.class)
                .setParameter("club",club).setLockMode(LockModeType.PESSIMISTIC_WRITE).setMaxResults(1)
                .getResultStream().findFirst().orElse(null);
    }
    public ClubAudit latestLifecycleAudit(long club) {
        return em.createQuery("select a from ClubAudit a where a.clubId=:club and a.previousState is not null order by a.auditId desc", ClubAudit.class)
                .setParameter("club", club).setLockMode(LockModeType.PESSIMISTIC_WRITE)
                .setMaxResults(1).getResultStream().findFirst().orElse(null);
    }
    public boolean restoredAfter(long club,long auditId,String restorationAction) {
        return em.createQuery("select count(a) from ClubAudit a where a.clubId=:club and a.auditId>:audit and a.action=:action",Long.class)
                .setParameter("club",club).setParameter("audit",auditId).setParameter("action", restorationAction).getSingleResult()>0;
    }
}
