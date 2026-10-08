package com.uniconnect.connection.repository;

import com.uniconnect.connection.domain.Connection;
import java.util.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface ConnectionRepository extends JpaRepository<Connection, Long> {
    interface Participants { Long getRequesterId(); Long getReceiverId(); }
    @Query("select c.requesterId as requesterId, c.receiverId as receiverId from Connection c where c.connectionId = :id")
    Optional<Participants> participants(@Param("id") long id);
    Optional<Connection> findByOpenLowAndOpenHigh(Long low, Long high);
    @Query("select case when c.requesterId = :user then c.receiverId else c.requesterId end from Connection c where (c.requesterId = :user or c.receiverId = :user) and c.status = com.uniconnect.connection.domain.ConnectionStatus.ACCEPTED")
    List<Long> acceptedPeers(@Param("user") long user);
    @Query("select c from Connection c where (c.requesterId = :user or c.receiverId = :user) and c.openLow is not null")
    List<Connection> openForUser(@Param("user") long user);
}
