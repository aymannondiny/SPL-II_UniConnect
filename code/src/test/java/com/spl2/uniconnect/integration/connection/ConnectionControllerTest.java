package com.spl2.uniconnect.integration.connection;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.AfterEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.spl2.uniconnect.domain.connection.Connection;
import com.spl2.uniconnect.domain.connection.ConnectionStatus;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.connection.ConnectionRequest;
import com.spl2.uniconnect.repository.connection.ConnectionRepository;
import com.spl2.uniconnect.repository.user.UserRepository;

import java.time.LocalDateTime;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class ConnectionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ConnectionRepository connectionRepository;

    private User user1;
    private User user2;
    private User user3;

    @BeforeEach
    void setUp() {
        // Create test users
        user1 = User.builder()
                .fullName("Alice Student")
                .email("alice@iut-dhaka.edu")
                .passwordHash("hashedpassword1")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();
        user1 = userRepository.save(user1);

        user2 = User.builder()
                .fullName("Bob Alumni")
                .email("bob@iut-dhaka.edu")
                .passwordHash("hashedpassword2")
                .role(UserRole.ALUMNI)
                .emailVerified(true)
                .build();
        user2 = userRepository.save(user2);

        user3 = User.builder()
                .fullName("Charlie Club")
                .email("charlie@iut-dhaka.edu")
                .passwordHash("hashedpassword3")
                .role(UserRole.CLUB_ADMIN)
                .emailVerified(true)
                .build();
        user3 = userRepository.save(user3);
    }

    @AfterEach
    void tearDown() {
        TestSecurityUtil.clearSecurityContext();
    }

    // =====================================================
    // TEST: Send Connection Request
    // =====================================================

    @Test
    void sendConnectionRequest_Success() throws Exception {
        // Arrange
        TestSecurityUtil.authenticateUser(user1);
        ConnectionRequest request = new ConnectionRequest(user2.getUserId(), "Let's connect!");

        // Act & Assert
        mockMvc.perform(post("/api/connections/request")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value(containsString("sent successfully")))
                .andExpect(jsonPath("$.data.id").isNumber())
                .andExpect(jsonPath("$.data.status").value("PENDING"));
    }

    @Test
    void sendConnectionRequest_ToSelf_BadRequest() throws Exception {
        // Arrange
        TestSecurityUtil.authenticateUser(user1);
        ConnectionRequest request = new ConnectionRequest(user1.getUserId(), "Self request");

        // Act & Assert
        mockMvc.perform(post("/api/connections/request")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.error").value("Bad Request"))
                .andExpect(jsonPath("$.message").value(containsString("yourself")))
                .andExpect(jsonPath("$.path").value("/api/connections/request"));
    }

    @Test
    void sendConnectionRequest_UserNotFound_NotFound() throws Exception {
        // Arrange
        TestSecurityUtil.authenticateUser(user1);
        ConnectionRequest request = new ConnectionRequest(9999L, "Not found user");

        // Act & Assert
        mockMvc.perform(post("/api/connections/request")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.error").value("Not Found"))
                .andExpect(jsonPath("$.message").exists())
                .andExpect(jsonPath("$.path").value("/api/connections/request"));
    }

    // =====================================================
    // TEST: Accept Connection Request
    // =====================================================

    @Test
    void acceptConnectionRequest_Success() throws Exception {
        // Arrange: Create a pending connection
        Connection connection = Connection.builder()
                .user1(user1)  // Smaller ID
                .user2(user2)  // Larger ID
                .requestedBy(user1)
                .status(ConnectionStatus.PENDING)
                .requestedAt(LocalDateTime.now())
                .build();
        connection = connectionRepository.save(connection);

        TestSecurityUtil.authenticateUser(user2);

        // Act & Assert
        mockMvc.perform(put("/api/connections/" + connection.getConnectionId() + "/accept")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("ACCEPTED"))
                .andExpect(jsonPath("$.data.acceptedAt").isNotEmpty());
    }

    @Test
    void acceptConnectionRequest_NotReceiver_Forbidden() throws Exception {
        // Arrange: Create a pending connection where user1 is requester
        Connection connection = Connection.builder()
                .user1(user1)
                .user2(user2)
                .requestedBy(user1)
                .status(ConnectionStatus.PENDING)
                .build();
        connection = connectionRepository.save(connection);

        TestSecurityUtil.authenticateUser(user1);

        // Act & Assert (user1 trying to accept their own request)
        mockMvc.perform(put("/api/connections/" + connection.getConnectionId() + "/accept")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.status").value(403))
                .andExpect(jsonPath("$.error").value("Forbidden"))
                .andExpect(jsonPath("$.message").exists());
    }

    // =====================================================
    // TEST: Reject Connection Request
    // =====================================================

    @Test
    void rejectConnectionRequest_Success() throws Exception {
        // Arrange
        Connection connection = Connection.builder()
                .user1(user1)
                .user2(user2)
                .requestedBy(user1)
                .status(ConnectionStatus.PENDING)
                .build();
        connection = connectionRepository.save(connection);

        TestSecurityUtil.authenticateUser(user2);

        // Act & Assert
        mockMvc.perform(put("/api/connections/" + connection.getConnectionId() + "/reject")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        // Verify
        Connection rejected = connectionRepository.findById(connection.getConnectionId()).orElseThrow();
        assert rejected.getStatus() == ConnectionStatus.REJECTED;
    }

    // =====================================================
    // TEST: Cancel Connection Request
    // =====================================================

    @Test
    void cancelConnectionRequest_Success() throws Exception {
        // Arrange
        Connection connection = Connection.builder()
                .user1(user1)
                .user2(user2)
                .requestedBy(user1)
                .status(ConnectionStatus.PENDING)
                .build();
        connection = connectionRepository.save(connection);

        TestSecurityUtil.authenticateUser(user1);

        // Act & Assert
        mockMvc.perform(delete("/api/connections/" + connection.getConnectionId() + "/cancel")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        // Verify
        assert !connectionRepository.existsById(connection.getConnectionId());
    }

    // =====================================================
    // TEST: Remove Connection
    // =====================================================

    @Test
    void removeConnection_Success() throws Exception {
        // Arrange: Create accepted connection
        Connection connection = Connection.builder()
                .user1(user1)
                .user2(user2)
                .requestedBy(user1)
                .status(ConnectionStatus.ACCEPTED)
                .acceptedAt(LocalDateTime.now())
                .build();
        connection = connectionRepository.save(connection);

        TestSecurityUtil.authenticateUser(user1);

        // Act & Assert
        mockMvc.perform(delete("/api/connections/users/" + user2.getUserId())
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        // Verify
        assert !connectionRepository.existsById(connection.getConnectionId());
    }

    // =====================================================
    // TEST: Get My Connections
    // =====================================================

    @Test
    void getMyConnections_Success() throws Exception {
        // Arrange: Create multiple accepted connections
        Connection conn1 = Connection.builder()
                .user1(user1)
                .user2(user2)
                .requestedBy(user1)
                .status(ConnectionStatus.ACCEPTED)
                .acceptedAt(LocalDateTime.now())
                .build();
        connectionRepository.save(conn1);

        Connection conn2 = Connection.builder()
                .user1(user1)
                .user2(user3)
                .requestedBy(user1)
                .status(ConnectionStatus.ACCEPTED)
                .acceptedAt(LocalDateTime.now())
                .build();
        connectionRepository.save(conn2);

        TestSecurityUtil.authenticateUser(user1);

        // Act & Assert
        mockMvc.perform(get("/api/connections/my-connections")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray())
                .andExpect(jsonPath("$.data.totalElements").value(2));
    }

    @Test
    void getMyConnections_Empty() throws Exception {
        TestSecurityUtil.authenticateUser(user1);

        // Act & Assert
        mockMvc.perform(get("/api/connections/my-connections")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalElements").value(0));
    }

    // =====================================================
    // TEST: Get Pending Requests Received
    // =====================================================

    @Test
    void getPendingRequestsReceived_Success() throws Exception {
        // Arrange
        Connection connection = Connection.builder()
                .user1(user1)
                .user2(user2)
                .requestedBy(user1)
                .status(ConnectionStatus.PENDING)
                .build();
        connectionRepository.save(connection);

        TestSecurityUtil.authenticateUser(user2);

        // Act & Assert
        mockMvc.perform(get("/api/connections/requests/received")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalElements").value(1));
    }

    // =====================================================
    // TEST: Get Pending Requests Sent
    // =====================================================

    @Test
    void getPendingRequestsSent_Success() throws Exception {
        // Arrange
        Connection connection = Connection.builder()
                .user1(user1)
                .user2(user2)
                .requestedBy(user1)
                .status(ConnectionStatus.PENDING)
                .build();
        connectionRepository.save(connection);

        TestSecurityUtil.authenticateUser(user1);

        // Act & Assert
        mockMvc.perform(get("/api/connections/requests/sent")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalElements").value(1));
    }

    // =====================================================
    // TEST: Get Connection Statistics
    // =====================================================

    @Test
    void getConnectionStats_Success() throws Exception {
        // Arrange: Create various connections
        Connection accepted = Connection.builder()
                .user1(user1)
                .user2(user2)
                .requestedBy(user1)
                .status(ConnectionStatus.ACCEPTED)
                .acceptedAt(LocalDateTime.now())
                .build();
        connectionRepository.save(accepted);

        Connection pending = Connection.builder()
                .user1(user1)
                .user2(user3)
                .requestedBy(user1)
                .status(ConnectionStatus.PENDING)
                .build();
        connectionRepository.save(pending);

        TestSecurityUtil.authenticateUser(user1);

        // Act & Assert
        mockMvc.perform(get("/api/connections/stats")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalConnections").value(1))
                .andExpect(jsonPath("$.data.pendingRequestsSent").value(1));
    }

    // =====================================================
    // TEST: Check Connection Status
    // =====================================================

    @Test
    void getConnectionStatus_Connected() throws Exception {
        // Arrange
        Connection connection = Connection.builder()
                .user1(user1)
                .user2(user2)
                .requestedBy(user1)
                .status(ConnectionStatus.ACCEPTED)
                .acceptedAt(LocalDateTime.now())
                .build();
        connectionRepository.save(connection);

        TestSecurityUtil.authenticateUser(user1);

        // Act & Assert
        mockMvc.perform(get("/api/connections/status/" + user2.getUserId())
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").value("ACCEPTED"));
    }

    @Test
    void getConnectionStatus_NotConnected() throws Exception {
        TestSecurityUtil.authenticateUser(user1);

        // Act & Assert
        mockMvc.perform(get("/api/connections/status/" + user2.getUserId())
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").doesNotExist());  // ✅ Or check it doesn't exist
    }

    // =====================================================
    // TEST: Unauthorized Access
    // =====================================================

    @Test
    void sendConnectionRequest_Unauthorized() throws Exception {
        // Arrange (NO authentication)
        ConnectionRequest request = new ConnectionRequest(user2.getUserId(), "Request");

        // Act & Assert
        // When not authenticated, CSRF protection returns 403, not 401
        // This is expected behavior in Spring Security
        mockMvc.perform(post("/api/connections/request")
                        .with(csrf())  // ✅ KEEP CSRF token
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());  // ✅ Expect 403, not 401
    }
}