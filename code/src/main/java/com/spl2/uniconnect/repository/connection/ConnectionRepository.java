package com.spl2.uniconnect.repository.connection;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.spl2.uniconnect.domain.connection.Connection;
import com.spl2.uniconnect.domain.connection.ConnectionStatus;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConnectionRepository extends JpaRepository<Connection, Long> {

    /**
     * Find connection between two users (order-independent)
     * Works because user1 < user2 is enforced in service
     */
    @Query("SELECT c FROM Connection c WHERE " +
            "(c.user1.userId = :userId1 AND c.user2.userId = :userId2) OR " +
            "(c.user1.userId = :userId2 AND c.user2.userId = :userId1)")
    Optional<Connection> findConnectionBetweenUsers(
            @Param("userId1") Long userId1,
            @Param("userId2") Long userId2
    );

    /**
     * Find connection between two users with specific status
     */
    @Query("SELECT c FROM Connection c WHERE " +
            "((c.user1.userId = :userId1 AND c.user2.userId = :userId2) OR " +
            "(c.user1.userId = :userId2 AND c.user2.userId = :userId1)) AND " +
            "c.status = :status")
    Optional<Connection> findConnectionBetweenUsersWithStatus(
            @Param("userId1") Long userId1,
            @Param("userId2") Long userId2,
            @Param("status") ConnectionStatus status
    );

    /**
     * Get all accepted connections for a user
     */
    @Query("SELECT c FROM Connection c WHERE " +
            "(c.user1.userId = :userId OR c.user2.userId = :userId) AND " +
            "c.status = 'ACCEPTED' " +
            "ORDER BY c.acceptedAt DESC")
    Page<Connection> findAcceptedConnectionsByUserId(
            @Param("userId") Long userId,
            Pageable pageable
    );

    /**
     * Get pending requests WHERE current user is the RECEIVER
     * (someone sent them a request)
     */
    @Query("SELECT c FROM Connection c WHERE " +
            "(c.user1.userId = :userId OR c.user2.userId = :userId) AND " +
            "c.requestedBy.userId != :userId AND " +
            "c.status = 'PENDING' " +
            "ORDER BY c.requestedAt DESC")
    Page<Connection> findPendingRequestsReceived(
            @Param("userId") Long userId,
            Pageable pageable
    );

    /**
     * Get pending requests WHERE current user is the SENDER
     * (they sent the request)
     */
    @Query("SELECT c FROM Connection c WHERE " +
            "c.requestedBy.userId = :userId AND " +
            "c.status = 'PENDING' " +
            "ORDER BY c.requestedAt DESC")
    Page<Connection> findPendingRequestsSent(
            @Param("userId") Long userId,
            Pageable pageable
    );

    /**
     * Count accepted connections
     */
    @Query("SELECT COUNT(c) FROM Connection c WHERE " +
            "(c.user1.userId = :userId OR c.user2.userId = :userId) AND " +
            "c.status = 'ACCEPTED'")
    long countConnectionsByUserId(@Param("userId") Long userId);

    /**
     * Count pending requests received
     */
    @Query("SELECT COUNT(c) FROM Connection c WHERE " +
            "(c.user1.userId = :userId OR c.user2.userId = :userId) AND " +
            "c.requestedBy.userId != :userId AND " +
            "c.status = 'PENDING'")
    long countPendingRequestsReceived(@Param("userId") Long userId);

    /**
     * Count pending requests sent
     */
    @Query("SELECT COUNT(c) FROM Connection c WHERE " +
            "c.requestedBy.userId = :userId AND " +
            "c.status = 'PENDING'")
    long countPendingRequestsSent(@Param("userId") Long userId);

    /**
     * Check if users are connected (accepted)
     */
    @Query("SELECT CASE WHEN COUNT(c) > 0 THEN true ELSE false END FROM Connection c WHERE " +
            "((c.user1.userId = :userId1 AND c.user2.userId = :userId2) OR " +
            "(c.user1.userId = :userId2 AND c.user2.userId = :userId1)) AND " +
            "c.status = 'ACCEPTED'")
    boolean areUsersConnected(
            @Param("userId1") Long userId1,
            @Param("userId2") Long userId2
    );
}
