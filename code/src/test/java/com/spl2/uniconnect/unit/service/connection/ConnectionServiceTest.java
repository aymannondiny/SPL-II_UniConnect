package com.spl2.uniconnect.unit.service.connection;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import com.spl2.uniconnect.domain.connection.Connection;
import com.spl2.uniconnect.domain.connection.ConnectionStatus;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
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
import com.spl2.uniconnect.service.connection.ConnectionService;
import com.spl2.uniconnect.service.notification.NotificationService;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ConnectionServiceTest {

    @Mock
    private ConnectionRepository connectionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ConnectionMapper connectionMapper;

    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private ConnectionService connectionService;

    private User user1;
    private User user2;
    private User user3;
    private Connection connection;
    private ConnectionRequest connectionRequest;

    @BeforeEach
    void setUp() {
        // Setup User 1 (ID: 1)
        user1 = User.builder()
                .userId(1L)
                .fullName("Alice Student")
                .email("alice@iut-dhaka.edu")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();

        // Setup User 2 (ID: 2)
        user2 = User.builder()
                .userId(2L)
                .fullName("Bob Alumni")
                .email("bob@iut-dhaka.edu")
                .role(UserRole.ALUMNI)
                .emailVerified(true)
                .build();

        // Setup User 3 (ID: 3)
        user3 = User.builder()
                .userId(3L)
                .fullName("Charlie Club")
                .email("charlie@iut-dhaka.edu")
                .role(UserRole.CLUB_ADMIN)
                .emailVerified(true)
                .build();

        // Setup Connection (user1=1, user2=2, so correctly ordered: 1 < 2)
        connection = Connection.builder()
                .connectionId(1L)
                .user1(user1)  // ✅ Smaller ID
                .user2(user2)  // ✅ Larger ID
                .requestedBy(user1)
                .status(ConnectionStatus.PENDING)
                .requestMessage("Let's connect!")
                .requestedAt(LocalDateTime.now())
                .build();

        // Setup Connection Request
        connectionRequest = new ConnectionRequest(2L, "Let's connect!");
    }

    // =====================================================
    // TEST: Send Connection Request - Success
    // =====================================================

    @Test
    void sendConnectionRequest_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(userRepository.findById(1L)).thenReturn(Optional.of(user1));
            when(userRepository.findById(2L)).thenReturn(Optional.of(user2));
            when(connectionRepository.findConnectionBetweenUsers(1L, 2L))
                    .thenReturn(Optional.empty());
            when(connectionRepository.save(any(Connection.class)))
                    .thenReturn(connection);
            when(connectionMapper.toResponse(connection, 1L))
                    .thenReturn(new ConnectionResponse());

            // Act
            ConnectionResponse response = connectionService.sendConnectionRequest(connectionRequest);

            // Assert
            assertNotNull(response);
            verify(connectionRepository).save(argThat(conn ->
                    conn.getUser1().getUserId() == 1L &&  // ✅ Smaller ID first
                            conn.getUser2().getUserId() == 2L &&  // ✅ Larger ID second
                            conn.getStatus() == ConnectionStatus.PENDING
            ));
            verify(notificationService).sendConnectionRequestNotification(user1, user2);
        }
    }

    // =====================================================
    // TEST: Send Connection Request - Ordering Test
    // =====================================================

    @Test
    void sendConnectionRequest_UserOrderingCorrect_LargerIdSendsToSmallerId() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange: User 2 sends request to User 1 (reversed order)
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            ConnectionRequest request = new ConnectionRequest(1L, "Hi Alice");

            when(userRepository.findById(2L)).thenReturn(Optional.of(user2));
            when(userRepository.findById(1L)).thenReturn(Optional.of(user1));
            when(connectionRepository.findConnectionBetweenUsers(2L, 1L))
                    .thenReturn(Optional.empty());

            // Setup expected connection with correct ordering
            Connection expectedConnection = Connection.builder()
                    .connectionId(1L)
                    .user1(user1)  // ✅ Still user1 because 1 < 2
                    .user2(user2)  // ✅ Still user2 because 2 > 1
                    .requestedBy(user2)  // ✅ But requester is user2
                    .status(ConnectionStatus.PENDING)
                    .build();

            when(connectionRepository.save(any(Connection.class)))
                    .thenReturn(expectedConnection);
            when(connectionMapper.toResponse(expectedConnection, 2L))
                    .thenReturn(new ConnectionResponse());

            // Act
            ConnectionResponse response = connectionService.sendConnectionRequest(request);

            // Assert
            assertNotNull(response);
            // Verify that user1 < user2 ALWAYS, regardless of who sends request
            verify(connectionRepository).save(argThat(conn ->
                    conn.getUser1().getUserId() == 1L &&  // ✅ Always smaller
                            conn.getUser2().getUserId() == 2L     // ✅ Always larger
            ));
        }
    }

    // =====================================================
    // TEST: Send Connection Request - To Self
    // =====================================================

    @Test
    void sendConnectionRequest_ToSelf_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            ConnectionRequest selfRequest = new ConnectionRequest(1L, "Self request");

            // Act & Assert
            assertThrows(BadRequestException.class, () ->
                            connectionService.sendConnectionRequest(selfRequest),
                    "Should throw BadRequestException for self-connection"
            );

            // Verify no save was attempted
            verify(connectionRepository, never()).save(any(Connection.class));
        }
    }

    // =====================================================
    // TEST: Send Connection Request - User Not Found
    // =====================================================

    @Test
    void sendConnectionRequest_UserNotFound_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

//            when(userRepository.findById(1L)).thenReturn(Optional.of(user1));
            when(userRepository.findById(2L)).thenReturn(Optional.empty());  // ✅ Receiver not found

            // Act & Assert
            assertThrows(ResourceNotFoundException.class, () ->
                            connectionService.sendConnectionRequest(connectionRequest),
                    "Should throw ResourceNotFoundException when receiver not found"
            );

            verify(connectionRepository, never()).save(any(Connection.class));
        }
    }

    // =====================================================
    // TEST: Send Connection Request - Already Connected
    // =====================================================

    @Test
    void sendConnectionRequest_AlreadyConnected_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            Connection acceptedConnection = Connection.builder()
                    .connectionId(1L)
                    .user1(user1)
                    .user2(user2)
                    .status(ConnectionStatus.ACCEPTED)
                    .build();

            when(userRepository.findById(1L)).thenReturn(Optional.of(user1));
            when(userRepository.findById(2L)).thenReturn(Optional.of(user2));
            when(connectionRepository.findConnectionBetweenUsers(1L, 2L))
                    .thenReturn(Optional.of(acceptedConnection));

            // Act & Assert
            assertThrows(BadRequestException.class, () ->
                            connectionService.sendConnectionRequest(connectionRequest),
                    "Should throw BadRequestException when already connected"
            );
        }
    }

    // =====================================================
    // TEST: Send Connection Request - Resend After Rejection
    // =====================================================

    @Test
    void sendConnectionRequest_ResendAfterRejection_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            Connection rejectedConnection = Connection.builder()
                    .connectionId(1L)
                    .user1(user1)
                    .user2(user2)
                    .requestedBy(user1)
                    .status(ConnectionStatus.REJECTED)  // ✅ Previously rejected
                    .build();

            when(userRepository.findById(1L)).thenReturn(Optional.of(user1));
            when(userRepository.findById(2L)).thenReturn(Optional.of(user2));
            when(connectionRepository.findConnectionBetweenUsers(1L, 2L))
                    .thenReturn(Optional.of(rejectedConnection));
            when(connectionRepository.save(any(Connection.class)))
                    .thenReturn(rejectedConnection);
            when(connectionMapper.toResponse(rejectedConnection, 1L))
                    .thenReturn(new ConnectionResponse());

            // Act
            ConnectionResponse response = connectionService.sendConnectionRequest(connectionRequest);

            // Assert
            assertNotNull(response);
            assertEquals(ConnectionStatus.PENDING, rejectedConnection.getStatus());
            verify(notificationService).sendConnectionRequestNotification(user1, user2);
        }
    }

    // =====================================================
    // TEST: Accept Connection Request - Success
    // =====================================================

    @Test
    void acceptConnectionRequest_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange: User2 (receiver) accepts request from User1
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));
            when(userRepository.getReferenceById(2L)).thenReturn(user2);
            when(connectionRepository.save(any(Connection.class))).thenReturn(connection);
            when(connectionMapper.toResponse(any(Connection.class), eq(2L)))
                    .thenReturn(new ConnectionResponse());

            // Act
            ConnectionResponse response = connectionService.acceptConnectionRequest(1L);

            // Assert
            assertNotNull(response);
            assertEquals(ConnectionStatus.ACCEPTED, connection.getStatus());
            assertNotNull(connection.getAcceptedAt());
            // ✅ Acceptor (user2) and Requester (user1)
            verify(notificationService).sendConnectionAcceptedNotification(user2, user1);
        }
    }

    // =====================================================
    // TEST: Accept Connection Request - Not Receiver
    // =====================================================

    @Test
    void acceptConnectionRequest_NotReceiver_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange: User1 (requester) trying to accept their own request
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));

            // Act & Assert
            assertThrows(ForbiddenException.class, () ->
                            connectionService.acceptConnectionRequest(1L),
                    "Only receiver can accept request"
            );

            verify(connectionRepository, never()).save(any(Connection.class));
        }
    }

    // =====================================================
    // TEST: Accept Connection Request - Not Pending
    // =====================================================

    @Test
    void acceptConnectionRequest_NotPending_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            Connection acceptedConnection = Connection.builder()
                    .connectionId(1L)
                    .user1(user1)
                    .user2(user2)
                    .requestedBy(user1)
                    .status(ConnectionStatus.ACCEPTED)  // ✅ Already accepted
                    .acceptedAt(LocalDateTime.now())
                    .build();

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(acceptedConnection));
            when(userRepository.getReferenceById(2L)).thenReturn(user2);

            // Act & Assert
            assertThrows(BadRequestException.class, () ->
                            connectionService.acceptConnectionRequest(1L),
                    "Can only accept PENDING requests"
            );
        }
    }

    // =====================================================
    // TEST: Reject Connection Request - Success
    // =====================================================

    @Test
    void rejectConnectionRequest_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange: User2 (receiver) rejects request from User1
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));
            when(userRepository.getReferenceById(2L)).thenReturn(user2);
            when(connectionRepository.save(any(Connection.class))).thenReturn(connection);

            // Act
            connectionService.rejectConnectionRequest(1L);

            // Assert
            assertEquals(ConnectionStatus.REJECTED, connection.getStatus());
            verify(connectionRepository).save(connection);
            // ✅ ADDED: Verify rejection notification sent
            verify(notificationService).sendConnectionRejectedNotification(user2, user1);
        }
    }

    // =====================================================
    // TEST: Reject Connection Request - Not Receiver
    // =====================================================

    @Test
    void rejectConnectionRequest_NotReceiver_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange: User1 (requester) trying to reject their own request
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));

            // Act & Assert
            assertThrows(ForbiddenException.class, () ->
                            connectionService.rejectConnectionRequest(1L),
                    "Only receiver can reject request"
            );

            verify(connectionRepository, never()).save(any(Connection.class));
        }
    }

    // =====================================================
    // TEST: Reject Connection Request - Not Pending
    // =====================================================

    @Test
    void rejectConnectionRequest_NotPending_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange: User2 is the receiver, trying to reject a non-pending request
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            // ✅ User1 sent request to user2, but it's already ACCEPTED (not pending)
            Connection acceptedConnection = Connection.builder()
                    .connectionId(1L)
                    .user1(user1)
                    .user2(user2)
                    .requestedBy(user1)  // User1 sent the request
                    .status(ConnectionStatus.ACCEPTED)  // ✅ Already accepted (not pending)
                    .acceptedAt(LocalDateTime.now())
                    .build();

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(acceptedConnection));
            when(userRepository.getReferenceById(2L)).thenReturn(user2);

            // Act & Assert: User2 (receiver) tries to reject an already-accepted connection
            assertThrows(BadRequestException.class, () ->
                            connectionService.rejectConnectionRequest(1L),
                    "Can only reject PENDING requests"
            );

            verify(connectionRepository, never()).save(any(Connection.class));
        }
    }

    // =====================================================
    // TEST: Cancel Connection Request - Success
    // =====================================================

    @Test
    void cancelConnectionRequest_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange: User1 (requester) cancels their request
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));

            // Act
            connectionService.cancelConnectionRequest(1L);

            // Assert
            verify(connectionRepository).delete(connection);
        }
    }

    // =====================================================
    // TEST: Cancel Connection Request - Not Requester
    // =====================================================

    @Test
    void cancelConnectionRequest_NotRequester_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange: User2 (receiver) trying to cancel User1's request
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));

            // Act & Assert
            assertThrows(ForbiddenException.class, () ->
                            connectionService.cancelConnectionRequest(1L),
                    "Only requester can cancel request"
            );

            verify(connectionRepository, never()).delete(any(Connection.class));
        }
    }

    // =====================================================
    // TEST: Cancel Connection Request - Not Pending
    // =====================================================

    @Test
    void cancelConnectionRequest_NotPending_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            Connection acceptedConnection = Connection.builder()
                    .connectionId(1L)
                    .user1(user1)
                    .user2(user2)
                    .requestedBy(user1)
                    .status(ConnectionStatus.ACCEPTED)  // ✅ Already accepted
                    .build();

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(acceptedConnection));

            // Act & Assert
            assertThrows(BadRequestException.class, () ->
                            connectionService.cancelConnectionRequest(1L),
                    "Can only cancel PENDING requests"
            );
        }
    }

    // =====================================================
    // TEST: Remove Connection - Success
    // =====================================================

    @Test
    void removeConnection_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            Connection acceptedConnection = Connection.builder()
                    .connectionId(1L)
                    .user1(user1)
                    .user2(user2)
                    .status(ConnectionStatus.ACCEPTED)
                    .build();

            when(connectionRepository.findConnectionBetweenUsersWithStatus(1L, 2L, ConnectionStatus.ACCEPTED))
                    .thenReturn(Optional.of(acceptedConnection));

            // Act
            connectionService.removeConnection(2L);

            // Assert
            verify(connectionRepository).delete(acceptedConnection);
        }
    }

    // =====================================================
    // TEST: Remove Connection - No Active Connection
    // =====================================================

    @Test
    void removeConnection_NoConnection_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(connectionRepository.findConnectionBetweenUsersWithStatus(1L, 2L, ConnectionStatus.ACCEPTED))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThrows(ResourceNotFoundException.class, () ->
                            connectionService.removeConnection(2L),
                    "Should throw ResourceNotFoundException when no active connection"
            );

            verify(connectionRepository, never()).delete(any(Connection.class));
        }
    }

    // =====================================================
    // TEST: Get My Connections - Success
    // =====================================================

    @Test
    void getMyConnections_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            Pageable pageable = PageRequest.of(0, 20);
            Page<Connection> connectionPage = new PageImpl<>(List.of(connection));

            when(connectionRepository.findAcceptedConnectionsByUserId(1L, pageable))
                    .thenReturn(connectionPage);
            when(connectionMapper.toResponse(connection, 1L))
                    .thenReturn(new ConnectionResponse());

            // Act
            Page<ConnectionResponse> response = connectionService.getMyConnections(pageable);

            // Assert
            assertNotNull(response);
            assertEquals(1, response.getTotalElements());
        }
    }

    // =====================================================
    // TEST: Get My Connections - Empty
    // =====================================================

    @Test
    void getMyConnections_Empty() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            Pageable pageable = PageRequest.of(0, 20);
            Page<Connection> emptyPage = new PageImpl<>(List.of());

            when(connectionRepository.findAcceptedConnectionsByUserId(1L, pageable))
                    .thenReturn(emptyPage);

            // Act
            Page<ConnectionResponse> response = connectionService.getMyConnections(pageable);

            // Assert
            assertNotNull(response);
            assertEquals(0, response.getTotalElements());
        }
    }

    // =====================================================
    // TEST: Get Pending Requests Received
    // =====================================================

    @Test
    void getPendingRequestsReceived_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange: User2 receives request from User1
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            Pageable pageable = PageRequest.of(0, 20);
            Page<Connection> requestsPage = new PageImpl<>(List.of(connection));

            when(connectionRepository.findPendingRequestsReceived(2L, pageable))
                    .thenReturn(requestsPage);
            when(connectionMapper.toResponse(connection, 2L))
                    .thenReturn(new ConnectionResponse());

            // Act
            Page<ConnectionResponse> response = connectionService.getPendingRequestsReceived(pageable);

            // Assert
            assertNotNull(response);
            assertEquals(1, response.getTotalElements());
        }
    }

    // =====================================================
    // TEST: Get Pending Requests Sent
    // =====================================================

    @Test
    void getPendingRequestsSent_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange: User1 sent request to User2
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            Pageable pageable = PageRequest.of(0, 20);
            Page<Connection> requestsPage = new PageImpl<>(List.of(connection));

            when(connectionRepository.findPendingRequestsSent(1L, pageable))
                    .thenReturn(requestsPage);
            when(connectionMapper.toResponse(connection, 1L))
                    .thenReturn(new ConnectionResponse());

            // Act
            Page<ConnectionResponse> response = connectionService.getPendingRequestsSent(pageable);

            // Assert
            assertNotNull(response);
            assertEquals(1, response.getTotalElements());
        }
    }

    // =====================================================
    // TEST: Get Connection Statistics
    // =====================================================

    @Test
    void getConnectionStats_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(connectionRepository.countConnectionsByUserId(1L)).thenReturn(5L);
            when(connectionRepository.countPendingRequestsReceived(1L)).thenReturn(2L);
            when(connectionRepository.countPendingRequestsSent(1L)).thenReturn(1L);

            // Act
            ConnectionStatsResponse stats = connectionService.getConnectionStats();

            // Assert
            assertNotNull(stats);
            assertEquals(5L, stats.getTotalConnections());
            assertEquals(2L, stats.getPendingRequestsReceived());
            assertEquals(1L, stats.getPendingRequestsSent());
        }
    }

    // =====================================================
    // TEST: Check Connection Status - Connected
    // =====================================================

    @Test
    void getConnectionStatus_Connected() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            connection.setStatus(ConnectionStatus.ACCEPTED);

            when(connectionRepository.findConnectionBetweenUsers(1L, 2L))
                    .thenReturn(Optional.of(connection));

            // Act
            ConnectionStatus status = connectionService.getConnectionStatus(2L);

            // Assert
            assertEquals(ConnectionStatus.ACCEPTED, status);
        }
    }

    // =====================================================
    // TEST: Check Connection Status - Not Connected
    // =====================================================

    @Test
    void getConnectionStatus_NotConnected() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(connectionRepository.findConnectionBetweenUsers(1L, 2L))
                    .thenReturn(Optional.empty());

            // Act
            ConnectionStatus status = connectionService.getConnectionStatus(2L);

            // Assert
            assertNull(status);
        }
    }

    // =====================================================
    // TEST: Check if Users are Connected
    // =====================================================

    @Test
    void areUsersConnected_True() {
        // Arrange
        when(connectionRepository.areUsersConnected(1L, 2L)).thenReturn(true);

        // Act
        boolean result = connectionService.areUsersConnected(1L, 2L);

        // Assert
        assertTrue(result);
    }

    @Test
    void areUsersConnected_False() {
        // Arrange
        when(connectionRepository.areUsersConnected(1L, 2L)).thenReturn(false);

        // Act
        boolean result = connectionService.areUsersConnected(1L, 2L);

        // Assert
        assertFalse(result);
    }

    // =====================================================
    // TEST: Graph Helper Methods - Get Connection IDs
    // =====================================================

    @Test
    void getConnectionIds_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            List<Long> connectedIds = List.of(2L, 3L, 5L);

            when(connectionRepository.findConnectedUserIds(1L))
                    .thenReturn(connectedIds);

            // Act
            List<Long> result = connectionService.getMyConnectionIds();

            // Assert
            assertNotNull(result);
            assertEquals(3, result.size());
            assertTrue(result.contains(2L));
            assertTrue(result.contains(3L));
            assertTrue(result.contains(5L));
        }
    }

    // =====================================================
    // TEST: Graph Helper Methods - Get Mutual Connections
    // =====================================================

    @Test
    void getMutualConnectionIds_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            List<Long> mutualIds = List.of(3L, 5L);  // Both 1 and 2 are connected to 3 and 5

            when(connectionRepository.findMutualConnectionIds(1L, 2L))
                    .thenReturn(mutualIds);

            // Act
            List<Long> result = connectionService.getMutualConnectionIds(2L);

            // Assert
            assertNotNull(result);
            assertEquals(2, result.size());
            assertTrue(result.contains(3L));
            assertTrue(result.contains(5L));
        }
    }

    // =====================================================
    // TEST: Search Connections
    // =====================================================

    @Test
    void searchConnections_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            Pageable pageable = PageRequest.of(0, 20);
            Page<Connection> searchResults = new PageImpl<>(List.of(connection));

            when(connectionRepository.searchConnections(1L, "Bob", pageable))
                    .thenReturn(searchResults);
            when(connectionMapper.toResponse(connection, 1L))
                    .thenReturn(new ConnectionResponse());

            // Act
            Page<ConnectionResponse> result = connectionService.searchConnections("Bob", pageable);

            // Assert
            assertNotNull(result);
            assertEquals(1, result.getTotalElements());
        }
    }

    @Test
    void searchConnections_EmptyQuery_ReturnsAllConnections() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            Pageable pageable = PageRequest.of(0, 20);
            Page<Connection> allConnections = new PageImpl<>(List.of(connection));

            when(connectionRepository.findAcceptedConnectionsByUserId(1L, pageable))
                    .thenReturn(allConnections);
            when(connectionMapper.toResponse(connection, 1L))
                    .thenReturn(new ConnectionResponse());

            // Act
            Page<ConnectionResponse> result = connectionService.searchConnections("", pageable);

            // Assert
            assertNotNull(result);
            assertEquals(1, result.getTotalElements());
        }
    }
}