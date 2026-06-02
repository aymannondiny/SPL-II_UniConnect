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

    // =====================================================
// GRAPH & DISCOVERY QUERIES
// =====================================================

    /**
     * Get all 1st-degree connection user IDs for a user
     * CRITICAL for graph-based teammate matching algorithm (FR-3.7)
     */
    @Query("SELECT CASE " +
            "WHEN c.user1.userId = :userId THEN c.user2.userId " +
            "ELSE c.user1.userId END " +
            "FROM Connection c WHERE " +
            "(c.user1.userId = :userId OR c.user2.userId = :userId) AND " +
            "c.status = 'ACCEPTED'")
    List<Long> findConnectedUserIds(@Param("userId") Long userId);

    /**
     * Find mutual connections between two users
     * Returns list of user IDs who are connected to BOTH users
     */
    @Query("SELECT DISTINCT CASE " +
            "WHEN c1.user1.userId = :user1Id THEN c1.user2.userId " +
            "ELSE c1.user1.userId END " +
            "FROM Connection c1, Connection c2 WHERE " +
            "c1.status = 'ACCEPTED' AND c2.status = 'ACCEPTED' AND " +
            // User1's connections
            "(c1.user1.userId = :user1Id OR c1.user2.userId = :user1Id) AND " +
            // User2's connections
            "(c2.user1.userId = :user2Id OR c2.user2.userId = :user2Id) AND " +
            // Same person connected to both
            "((c1.user1.userId = c2.user1.userId AND c1.user1.userId != :user1Id AND c1.user1.userId != :user2Id) OR " +
            " (c1.user1.userId = c2.user2.userId AND c1.user1.userId != :user1Id AND c1.user1.userId != :user2Id) OR " +
            " (c1.user2.userId = c2.user1.userId AND c1.user2.userId != :user1Id AND c1.user2.userId != :user2Id) OR " +
            " (c1.user2.userId = c2.user2.userId AND c1.user2.userId != :user1Id AND c1.user2.userId != :user2Id))")
    List<Long> findMutualConnectionIds(@Param("user1Id") Long user1Id,
                                       @Param("user2Id") Long user2Id);

    /**
     * Search connections by name
     */
    @Query("SELECT c FROM Connection c WHERE " +
            "(c.user1.userId = :userId OR c.user2.userId = :userId) AND " +
            "c.status = 'ACCEPTED' AND " +
            "(" +
            "  (c.user1.userId != :userId AND LOWER(c.user1.fullName) LIKE LOWER(CONCAT('%', :search, '%'))) OR " +
            "  (c.user2.userId != :userId AND LOWER(c.user2.fullName) LIKE LOWER(CONCAT('%', :search, '%')))" +
            ")")
    Page<Connection> searchConnections(@Param("userId") Long userId,
                                       @Param("search") String searchQuery,
                                       Pageable pageable);
}
