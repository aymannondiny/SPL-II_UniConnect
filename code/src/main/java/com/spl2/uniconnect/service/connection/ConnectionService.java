package com.spl2.uniconnect.service.connection;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.spl2.uniconnect.domain.connection.Connection;
import com.spl2.uniconnect.domain.connection.ConnectionStatus;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.request.connection.ConnectionRequest;
import com.spl2.uniconnect.dto.response.connection.ConnectionResponse;
import com.spl2.uniconnect.dto.response.connection.ConnectionStatsResponse;
import com.spl2.uniconnect.exception.BadRequestException;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.ConnectionMapper;
import com.spl2.uniconnect.repository.connection.ConnectionRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.notification.NotificationService;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ConnectionService {

    private final ConnectionRepository connectionRepository;
    private final UserRepository userRepository;
    private final ConnectionMapper connectionMapper;
    private final NotificationService notificationService;

    /**
     * Send a connection request
     */
    public ConnectionResponse sendConnectionRequest(ConnectionRequest request) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        Long receiverId = request.getReceiverId();

        // Validation: Cannot send request to yourself
        if (currentUserId.equals(receiverId)) {
            throw new BadRequestException("You cannot send a connection request to yourself");
        }

        // Check if receiver exists
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + receiverId));

        User requester = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Current user not found"));

        // Check if connection already exists
        Optional<Connection> existingConnection = connectionRepository
                .findConnectionBetweenUsers(currentUserId, receiverId);

        if (existingConnection.isPresent()) {
            Connection conn = existingConnection.get();
            switch (conn.getStatus()) {
                case PENDING:
                    throw new BadRequestException("A connection request already exists");
                case ACCEPTED:
                    throw new BadRequestException("You are already connected with this user");
                case REJECTED:
                    // Allow resending after rejection
                    conn.setStatus(ConnectionStatus.PENDING);
                    conn.setRequestedBy(requester);
                    conn.setRequestMessage(request.getMessage()); // ✅ Update message
                    conn.setAcceptedAt(null);
                    Connection updated = connectionRepository.save(conn);

                    // Send notification
                    notificationService.sendConnectionRequestNotification(requester, receiver);

                    log.info("Connection request resent from user {} to user {}", currentUserId, receiverId);
                    return connectionMapper.toResponse(updated, currentUserId);
                default:
                    break;
            }
        }

        // ✅ FIX: Properly order users based on ID
        Long smallerId = Math.min(currentUserId, receiverId);
        Long largerId = Math.max(currentUserId, receiverId);

        User user1 = smallerId.equals(currentUserId) ? requester : receiver;
        User user2 = largerId.equals(currentUserId) ? requester : receiver;

        // ✅ Create new connection with correctly ordered users
        Connection connection = Connection.builder()
                .user1(user1)  // ✅ Always smaller ID
                .user2(user2)  // ✅ Always larger ID
                .requestedBy(requester)
                .status(ConnectionStatus.PENDING)
                .requestMessage(request.getMessage())
                .build();

        Connection saved = connectionRepository.save(connection);

        // Send notification to receiver
        notificationService.sendConnectionRequestNotification(requester, receiver);

        log.info("Connection request sent from user {} to user {}", currentUserId, receiverId);

        return connectionMapper.toResponse(saved, currentUserId);
    }

    /**
     * Accept a connection request
     */
    public ConnectionResponse acceptConnectionRequest(Long connectionId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Connection connection = connectionRepository.findById(connectionId)
                .orElseThrow(() -> new ResourceNotFoundException("Connection request not found"));

        // Validation: Only the receiver can accept
        if (connection.isRequestedBy(currentUserId)) {
            throw new ForbiddenException("You cannot accept your own connection request");
        }

        if (!connection.involvesUser(userRepository.getReferenceById(currentUserId))) {
            throw new ForbiddenException("You are not authorized to accept this request");
        }

        // Validation: Can only accept pending requests
        if (connection.getStatus() != ConnectionStatus.PENDING) {
            throw new BadRequestException("This request cannot be accepted (current status: " + connection.getStatus() + ")");
        }

        // ✅ Use helper method
        connection.accept();

        Connection updated = connectionRepository.save(connection);

        // ✅ FIX: Current user is the acceptor, get the requester
        User acceptor = userRepository.getReferenceById(currentUserId);
        User requester = connection.getRequestedBy();
        notificationService.sendConnectionAcceptedNotification(acceptor, requester);

        log.info("Connection request {} accepted by user {}", connectionId, currentUserId);

        return connectionMapper.toResponse(updated, currentUserId);
    }

    /**
     * Reject a connection request
     */
    public void rejectConnectionRequest(Long connectionId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Connection connection = connectionRepository.findById(connectionId)
                .orElseThrow(() -> new ResourceNotFoundException("Connection request not found"));

        // ✅ Validation: Only the receiver can reject (requester should use cancel)
        if (connection.isRequestedBy(currentUserId)) {
            throw new ForbiddenException("You cannot reject your own connection request. Use cancel instead.");
        }

        if (!connection.involvesUser(userRepository.getReferenceById(currentUserId))) {
            throw new ForbiddenException("You are not authorized to reject this request");
        }

        // Validation: Can only reject pending requests
        if (connection.getStatus() != ConnectionStatus.PENDING) {
            throw new BadRequestException("This request cannot be rejected");
        }

        connection.setStatus(ConnectionStatus.REJECTED);
        connectionRepository.save(connection);

        // ✅ ADDED: Notify the requester about rejection
        User receiver = userRepository.getReferenceById(currentUserId);
        User requester = connection.getRequestedBy();
        notificationService.sendConnectionRejectedNotification(receiver, requester);

        log.info("Connection request {} rejected by user {}", connectionId, currentUserId);
    }

    /**
     * Cancel a sent connection request
     */
    public void cancelConnectionRequest(Long connectionId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Connection connection = connectionRepository.findById(connectionId)
                .orElseThrow(() -> new ResourceNotFoundException("Connection request not found"));

        // Validation: Only the requester can cancel
        if (!connection.isRequestedBy(currentUserId)) {
            throw new ForbiddenException("You are not authorized to cancel this request");
        }

        // Validation: Can only cancel pending requests
        if (connection.getStatus() != ConnectionStatus.PENDING) {
            throw new BadRequestException("This request cannot be cancelled");
        }

        connectionRepository.delete(connection);

        log.info("Connection request {} cancelled by user {}", connectionId, currentUserId);
    }

    /**
     * Remove an existing connection
     */
    public void removeConnection(Long userId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Connection connection = connectionRepository
                .findConnectionBetweenUsersWithStatus(currentUserId, userId, ConnectionStatus.ACCEPTED)
                .orElseThrow(() -> new ResourceNotFoundException("No active connection found with this user"));

        connectionRepository.delete(connection);

        log.info("Connection removed between user {} and user {}", currentUserId, userId);
    }

    /**
     * Get all connections (friends) for current user
     */
    @Transactional(readOnly = true)
    public Page<ConnectionResponse> getMyConnections(Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Page<Connection> connections = connectionRepository
                .findAcceptedConnectionsByUserId(currentUserId, pageable);

        return connections.map(conn -> connectionMapper.toResponse(conn, currentUserId));
    }

    /**
     * Get pending requests received by current user
     */
    @Transactional(readOnly = true)
    public Page<ConnectionResponse> getPendingRequestsReceived(Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Page<Connection> requests = connectionRepository
                .findPendingRequestsReceived(currentUserId, pageable);

        return requests.map(conn -> connectionMapper.toResponse(conn, currentUserId));
    }

    /**
     * Get pending requests sent by current user
     */
    @Transactional(readOnly = true)
    public Page<ConnectionResponse> getPendingRequestsSent(Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Page<Connection> requests = connectionRepository
                .findPendingRequestsSent(currentUserId, pageable);

        return requests.map(conn -> connectionMapper.toResponse(conn, currentUserId));
    }

    /**
     * Get connection statistics for current user
     */
    @Transactional(readOnly = true)
    public ConnectionStatsResponse getConnectionStats() {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        long totalConnections = connectionRepository.countConnectionsByUserId(currentUserId);
        long pendingReceived = connectionRepository.countPendingRequestsReceived(currentUserId);
        long pendingSent = connectionRepository.countPendingRequestsSent(currentUserId);

        return ConnectionStatsResponse.builder()
                .totalConnections(totalConnections)
                .pendingRequestsReceived(pendingReceived)
                .pendingRequestsSent(pendingSent)
                .build();
    }

    /**
     * Check connection status between current user and another user
     */
    @Transactional(readOnly = true)
    public ConnectionStatus getConnectionStatus(Long userId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (currentUserId.equals(userId)) {
            return null; // Same user
        }

        Optional<Connection> connection = connectionRepository
                .findConnectionBetweenUsers(currentUserId, userId);

        return connection.map(Connection::getStatus).orElse(null);
    }

    /**
     * Check if two users are connected
     */
    @Transactional(readOnly = true)
    public boolean areUsersConnected(Long userId1, Long userId2) {
        return connectionRepository.areUsersConnected(userId1, userId2);
    }

    // =====================================================
// GRAPH & DISCOVERY METHODS (for teammate matching)
// =====================================================

    /**
     * Get all 1st-degree connection user IDs
     * Used for graph-based algorithms (teammate matching, proximity calculation)
     */
    @Transactional(readOnly = true)
    public List<Long> getConnectionIds(Long userId) {
        return connectionRepository.findConnectedUserIds(userId);
    }

    /**
     * Get connection IDs for current user (convenience method)
     */
    @Transactional(readOnly = true)
    public List<Long> getMyConnectionIds() {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        return getConnectionIds(currentUserId);
    }

    /**
     * Find mutual connections between current user and another user
     */
    @Transactional(readOnly = true)
    public List<Long> getMutualConnectionIds(Long otherUserId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (currentUserId.equals(otherUserId)) {
            return List.of(); // No mutual connections with yourself
        }

        return connectionRepository.findMutualConnectionIds(currentUserId, otherUserId);
    }

    /**
     * Count mutual connections
     */
    @Transactional(readOnly = true)
    public long countMutualConnections(Long otherUserId) {
        return getMutualConnectionIds(otherUserId).size();
    }

    /**
     * Search within user's connections
     */
    @Transactional(readOnly = true)
    public Page<ConnectionResponse> searchConnections(String searchQuery, Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (searchQuery == null || searchQuery.trim().isEmpty()) {
            return getMyConnections(pageable);
        }

        Page<Connection> connections = connectionRepository
                .searchConnections(currentUserId, searchQuery.trim(), pageable);

        return connections.map(conn -> connectionMapper.toResponse(conn, currentUserId));
    }
}