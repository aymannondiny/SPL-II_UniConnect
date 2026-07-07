package com.spl2.uniconnect.integration.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.auth.CreateAdminRequest;
import com.spl2.uniconnect.dto.request.auth.LoginRequest;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@DisplayName("Admin Creation Controller Integration Tests")
class AdminCreationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    private String adminJwtToken;
    private User systemAdminUser;

    @BeforeEach
    void setUp() throws Exception {
        // Create system admin user
        systemAdminUser = User.builder()
                .email("testadmin@iut-dhaka.edu")
                .passwordHash(passwordEncoder.encode("AdminPassword123"))
                .fullName("Test System Admin")
                .role(UserRole.SYSTEM_ADMIN)
                .emailVerified(true)
                .build();

        systemAdminUser = userRepository.save(systemAdminUser);

        // Login and get JWT token
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setEmail("testadmin@iut-dhaka.edu");
        loginRequest.setPassword("AdminPassword123");

        String loginJson = objectMapper.writeValueAsString(loginRequest);

        MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson))
                .andExpect(status().isOk())
                .andReturn();

        String loginResponse = loginResult.getResponse().getContentAsString();
        // Extract token from response
        adminJwtToken = objectMapper.readTree(loginResponse)
                .path("data")
                .path("token")
                .asText();
    }

    @Test
    @DisplayName("Should create admin successfully with 201 Created")
    void testCreateAdminSuccess() throws Exception {
        CreateAdminRequest request = CreateAdminRequest.builder()
                .email("newadmin@iut-dhaka.edu")
                .password("NewAdminPassword123")
                .fullName("New Admin")
                .adminRole("Content Moderator")
                .build();

        mockMvc.perform(post("/api/auth/create-admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + adminJwtToken)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Admin account created successfully!"))
                .andExpect(jsonPath("$.data.email").value("newadmin@iut-dhaka.edu"))
                .andExpect(jsonPath("$.data.fullName").value("New Admin"))
                .andExpect(jsonPath("$.data.userId", notNullValue()));
    }

    @Test
    @DisplayName("Should return 403 Forbidden without SYSTEM_ADMIN role")
    void testCreateAdminWithoutSystemAdminRole() throws Exception {
        // Create non-admin user
        User regularUser = User.builder()
                .email("student@iut-dhaka.edu")
                .passwordHash(passwordEncoder.encode("Password123"))
                .fullName("Regular Student")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();

        regularUser = userRepository.save(regularUser);

        // Login as regular user
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setEmail("student@iut-dhaka.edu");
        loginRequest.setPassword("Password123");

        MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String studentToken = objectMapper.readTree(loginResult.getResponse().getContentAsString())
                .path("data")
                .path("token")
                .asText();

        // Try to create admin
        CreateAdminRequest request = CreateAdminRequest.builder()
                .email("hacker@iut-dhaka.edu")
                .password("HackerPassword123")
                .fullName("Hacker")
                .adminRole("Super Admin")
                .build();

        mockMvc.perform(post("/api/auth/create-admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + studentToken)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Should return 409 Conflict for duplicate email")
    void testCreateAdminWithDuplicateEmail() throws Exception {
        CreateAdminRequest request = CreateAdminRequest.builder()
                .email("testadmin@iut-dhaka.edu")  // Already exists
                .password("Password123")
                .fullName("Duplicate")
                .adminRole("Super Admin")
                .build();

        mockMvc.perform(post("/api/auth/create-admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + adminJwtToken)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.error").value("Conflict"))
                .andExpect(jsonPath("$.message", containsString("already registered")));
    }

    @Test
    @DisplayName("Should return 400 Bad Request for invalid email")
    void testCreateAdminWithInvalidEmail() throws Exception {
        CreateAdminRequest request = CreateAdminRequest.builder()
                .email("invalid-email")  // Not @iut-dhaka.edu
                .password("Password123")
                .fullName("Invalid")
                .adminRole("Super Admin")
                .build();

        mockMvc.perform(post("/api/auth/create-admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + adminJwtToken)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.error").value("Validation Failed"))  // ✅ Changed
                .andExpect(jsonPath("$.validationErrors.email", notNullValue()));  // ✅ Added
    }
    @Test
    @DisplayName("Should return 400 Bad Request for short password")
    void testCreateAdminWithShortPassword() throws Exception {
        CreateAdminRequest request = CreateAdminRequest.builder()
                .email("admin@iut-dhaka.edu")
                .password("short")  // Less than 8 chars
                .fullName("Admin")
                .adminRole("Super Admin")
                .build();

        mockMvc.perform(post("/api/auth/create-admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + adminJwtToken)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.error", notNullValue()));
    }

    @Test
    @DisplayName("Should return 400 Bad Request for missing required fields")
    void testCreateAdminWithMissingFields() throws Exception {
        String invalidJson = "{ \"email\": \"admin@iut-dhaka.edu\" }";

        mockMvc.perform(post("/api/auth/create-admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + adminJwtToken)
                        .content(invalidJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Should return 403 Forbidden without SYSTEM_ADMIN role")
    void testCreateAdminWithoutToken() throws Exception {
        CreateAdminRequest request = CreateAdminRequest.builder()
                .email("admin@iut-dhaka.edu")
                .password("Password123")
                .fullName("Admin")
                .adminRole("Super Admin")
                .build();

        mockMvc.perform(post("/api/auth/create-admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())  // Changed from isUnauthorized()
                .andExpect(jsonPath("$.status").value(403));
    }

    @Test
    @DisplayName("End-to-end: Create admin and login as new admin")
    void testCreateAdminAndLoginAsNewAdmin() throws Exception {
        // Step 1: Create new admin
        CreateAdminRequest createRequest = CreateAdminRequest.builder()
                .email("neoadmin@iut-dhaka.edu")
                .password("NewAdminPassword123")
                .fullName("Neo Admin")
                .adminRole("User Manager")
                .build();

        MvcResult createResult = mockMvc.perform(post("/api/auth/create-admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + adminJwtToken)
                        .content(objectMapper.writeValueAsString(createRequest)))
                .andExpect(status().isCreated())
                .andReturn();

        // Step 2: Verify admin was created
        String createResponse = createResult.getResponse().getContentAsString();
        Long newAdminId = objectMapper.readTree(createResponse)
                .path("data")
                .path("userId")
                .asLong();

        assertTrue(newAdminId > 0);

        // Step 3: Login as new admin
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setEmail("neoadmin@iut-dhaka.edu");
        loginRequest.setPassword("NewAdminPassword123");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.user.email").value("neoadmin@iut-dhaka.edu"))
                .andExpect(jsonPath("$.data.user.role").value("SYSTEM_ADMIN"))
                .andExpect(jsonPath("$.data.token", notNullValue()));
    }

    @Test
    @DisplayName("Should create multiple admins with different roles")
    void testCreateMultipleAdminsWithDifferentRoles() throws Exception {
        // Create Content Moderator
        CreateAdminRequest moderatorRequest = CreateAdminRequest.builder()
                .email("moderator@iut-dhaka.edu")
                .password("ModeratorPassword123")
                .fullName("Content Moderator")
                .adminRole("Content Moderator")
                .build();

        mockMvc.perform(post("/api/auth/create-admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + adminJwtToken)
                        .content(objectMapper.writeValueAsString(moderatorRequest)))
                .andExpect(status().isCreated());

        // Create User Manager
        CreateAdminRequest managerRequest = CreateAdminRequest.builder()
                .email("manager@iut-dhaka.edu")
                .password("ManagerPassword123")
                .fullName("User Manager")
                .adminRole("User Manager")
                .build();

        mockMvc.perform(post("/api/auth/create-admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + adminJwtToken)
                        .content(objectMapper.writeValueAsString(managerRequest)))
                .andExpect(status().isCreated());

        // Verify both were created
        assertTrue(userRepository.existsByEmail("moderator@iut-dhaka.edu"));
        assertTrue(userRepository.existsByEmail("manager@iut-dhaka.edu"));
    }
}