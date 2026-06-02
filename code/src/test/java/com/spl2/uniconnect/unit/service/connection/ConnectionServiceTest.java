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
        // Setup User 1
        user1 = User.builder()
                .userId(1L)
                .fullName("Alice Student")
                .email("alice@iut-dhaka.edu")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();

        // Setup User 2
        user2 = User.builder()
                .userId(2L)
                .fullName("Bob Alumni")
                .email("bob@iut-dhaka.edu")
                .role(UserRole.ALUMNI)
                .emailVerified(true)
                .build();

        // Setup User 3
        user3 = User.builder()
                .userId(3L)
                .fullName("Charlie Club")
                .email("charlie@iut-dhaka.edu")
                .role(UserRole.CLUB_ADMIN)
                .emailVerified(true)
                .build();

        // Setup Connection (user1 < user2, so ordered correctly)
        connection = Connection.builder()
                .connectionId(1L)
                .user1(user1)
                .user2(user2)
                .requestedBy(user1)
                .status(ConnectionStatus.PENDING)
                .requestMessage("Let's connect!")
                .requestedAt(LocalDateTime.now())
                .build();

        // Setup Connection Request
        connectionRequest = new ConnectionRequest(2L, "Let's connect!");
    }

    // =====================================================
    // TEST: Send Connection Request
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
            verify(connectionRepository).save(any(Connection.class));
            verify(notificationService).sendConnectionRequestNotification(user1, user2);
        }
    }

    @Test
    void sendConnectionRequest_ToSelf_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            ConnectionRequest selfRequest = new ConnectionRequest(1L, "Self request");

            // Act & Assert
            assertThrows(BadRequestException.class, () ->
                    connectionService.sendConnectionRequest(selfRequest)
            );
        }
    }

    @Test
    void sendConnectionRequest_UserNotFound_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

//            when(userRepository.findById(1L)).thenReturn(Optional.of(user1));
            when(userRepository.findById(2L)).thenReturn(Optional.empty());
            // ✅ REMOVE this line - it's never called:
            // when(connectionRepository.findConnectionBetweenUsers(anyLong(), anyLong()))
            //     .thenReturn(Optional.empty());

            // Act & Assert
            assertThrows(ResourceNotFoundException.class, () ->
                    connectionService.sendConnectionRequest(connectionRequest)
            );
        }
    }


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
                    connectionService.sendConnectionRequest(connectionRequest)
            );
        }
    }

    // =====================================================
    // TEST: Accept Connection Request
    // =====================================================

    @Test
    void acceptConnectionRequest_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
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
            // User2 (acceptor) accepted request from User1 (requester)
            verify(notificationService).sendConnectionAcceptedNotification(user2, user1);
        }
    }

    @Test
    void acceptConnectionRequest_NotReceiver_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));

            // Act & Assert
            assertThrows(ForbiddenException.class, () ->
                    connectionService.acceptConnectionRequest(1L)
            );
        }
    }

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
                    .status(ConnectionStatus.ACCEPTED)
                    .acceptedAt(LocalDateTime.now())
                    .build();

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(acceptedConnection));
            when(userRepository.getReferenceById(2L)).thenReturn(user2);

            // Act & Assert
            assertThrows(BadRequestException.class, () ->
                    connectionService.acceptConnectionRequest(1L)
            );
        }
    }

    // =====================================================
    // TEST: Reject Connection Request
    // =====================================================

    @Test
    void rejectConnectionRequest_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));
            when(userRepository.getReferenceById(2L)).thenReturn(user2);

            // Act
            connectionService.rejectConnectionRequest(1L);

            // Assert
            assertEquals(ConnectionStatus.REJECTED, connection.getStatus());
            verify(connectionRepository).save(connection);
        }
    }

    @Test
    void rejectConnectionRequest_NotReceiver_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));
//            when(userRepository.getReferenceById(1L)).thenReturn(user1);

            // Act & Assert
            assertThrows(ForbiddenException.class, () ->
                    connectionService.rejectConnectionRequest(1L)
            );
        }
    }

    // =====================================================
    // TEST: Cancel Connection Request
    // =====================================================

    @Test
    void cancelConnectionRequest_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));

            // Act
            connectionService.cancelConnectionRequest(1L);

            // Assert
            verify(connectionRepository).delete(connection);
        }
    }

    @Test
    void cancelConnectionRequest_NotRequester_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            when(connectionRepository.findById(1L)).thenReturn(Optional.of(connection));

            // Act & Assert
            assertThrows(ForbiddenException.class, () ->
                    connectionService.cancelConnectionRequest(1L)
            );
        }
    }

    // =====================================================
    // TEST: Remove Connection
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

    @Test
    void removeConnection_NoConnection_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(connectionRepository.findConnectionBetweenUsersWithStatus(1L, 2L, ConnectionStatus.ACCEPTED))
                    .thenReturn(Optional.empty());

            // Act & Assert
            assertThrows(ResourceNotFoundException.class, () ->
                    connectionService.removeConnection(2L)
            );
        }
    }

    // =====================================================
    // TEST: Get My Connections
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
            // Arrange
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

    @Test
    void getPendingRequestsSent_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            // Arrange
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
    // TEST: Check Connection Status
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
}