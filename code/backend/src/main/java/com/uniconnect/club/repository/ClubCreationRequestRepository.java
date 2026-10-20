package com.uniconnect.club.repository;

import com.uniconnect.club.domain.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import java.util.List;
import org.springframework.stereotype.Repository;

@Repository
public class ClubCreationRequestRepository {
    private final EntityManager em;
    public ClubCreationRequestRepository(EntityManager em) { this.em = em; }
    public <T> T insert(T entity) { em.persist(entity); em.flush(); return entity; }
    public ClubCreationRequest find(long id) { return em.find(ClubCreationRequest.class, id); }
    public ClubCreationRequest lock(long id) { return em.find(ClubCreationRequest.class, id, LockModeType.PESSIMISTIC_WRITE); }
    public List<ClubCreationRequest> owned(long userId) {
        return em.createQuery("select r from ClubCreationRequest r where r.requesterUserId=:user order by r.createdAt desc,r.requestId desc", ClubCreationRequest.class)
                .setParameter("user", userId).getResultList();
    }
    public List<ClubCreationRequest> review(ClubCreationRequestStatus status) {
        return status == null
                ? em.createQuery("select r from ClubCreationRequest r order by r.createdAt desc,r.requestId desc", ClubCreationRequest.class).getResultList()
                : em.createQuery("select r from ClubCreationRequest r where r.status=:status order by r.createdAt desc,r.requestId desc", ClubCreationRequest.class)
                        .setParameter("status", status).getResultList();
    }
}
