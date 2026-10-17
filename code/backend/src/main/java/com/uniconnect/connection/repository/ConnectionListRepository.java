package com.uniconnect.connection.repository;

import com.uniconnect.connection.domain.*;
import com.uniconnect.connection.dto.*;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.security.SessionPrincipal;
import jakarta.persistence.EntityManager;
import java.util.*;
import org.springframework.stereotype.Repository;

@Repository
public class ConnectionListRepository {
    private final EntityManager em;
    public ConnectionListRepository(EntityManager em) { this.em = em; }
    public PageResponse<ConnectionListItem> list(SessionPrincipal actor, ConnectionStatus status, String direction,
            String name, String sort, int page, int size) {
        String display = "case when u.anonymizedAt is null and u.accountStatus = com.uniconnect.shared.security.AccountStatus.ACTIVE then u.fullName else 'Unavailable member' end";
        String from = " from Connection c, User u where (c.requesterId = :actor or c.receiverId = :actor)"
                + " and u.userId = case when c.requesterId = :actor then c.receiverId else c.requesterId end and c.status = :status";
        if (direction.equals("INCOMING")) from += " and c.receiverId = :actor";
        if (direction.equals("OUTGOING")) from += " and c.requesterId = :actor";
        boolean hasName = name != null && !name.isBlank();
        if (hasName) from += " and locate(:name, lower(" + display + ")) > 0";
        var query = em.createQuery("select c, " + display + from + (sort.equals("NAME") ? " order by lower(" + display + "), c.connectionId desc" : " order by c.connectionId desc"), Object[].class);
        var count = em.createQuery("select count(c)" + from, Long.class);
        for (var q : List.of(query, count)) {
            q.setParameter("actor", actor.userId()); q.setParameter("status", status);
            if (hasName) q.setParameter("name", name.strip().toLowerCase(Locale.ROOT));
        }
        var items = query.setFirstResult(page * size).setMaxResults(size).getResultList().stream().map(row -> {
            Connection c = (Connection) row[0];
            Long other = c.getRequesterId().equals(actor.userId()) ? c.getReceiverId() : c.getRequesterId();
            return new ConnectionListItem(ConnectionResponse.from(c), other, (String) row[1]);
        }).toList();
        return new PageResponse<>(items, page, size, count.getSingleResult());
    }
}
