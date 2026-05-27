package com.spl2.uniconnect.base;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.spl2.uniconnect.config.TestConfig;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

/**
 * Base class for all Integration Tests
 * Integration tests test the FULL FLOW from HTTP request to database
 *
 * Extend this for: Controller tests, API endpoint tests
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
@Import(TestConfig.class)
public abstract class BaseIntegrationTest {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    @Autowired
    protected JwtTokenProvider jwtTokenProvider;

    @Autowired
    protected UserRepository userRepository;

    @Autowired
    protected PasswordEncoder passwordEncoder;

    @BeforeEach
    public void baseSetUp() {
        // Clean state handled by @Transactional rollback after each test
    }

    /**
     * Generate a JWT token for a saved user (uses userId internally)
     */
    protected String generateTokenForUser(User savedUser) {
        return jwtTokenProvider.generateTokenFromUserId(savedUser.getUserId());
    }

    /**
     * Generate Authorization header value
     */
    protected String bearerToken(User savedUser) {
        return "Bearer " + generateTokenForUser(savedUser);
    }

    /**
     * Helper: create and save a test user with given role
     */
    protected User createAndSaveUser(String email, UserRole role, boolean verified) {
        User user = User.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode("Test@1234"))
                .fullName("Test User")
                .role(role)
                .emailVerified(verified)
                .build();
        return userRepository.save(user);
    }

    /**
     * Helper: create verified student user
     */
    protected User createVerifiedStudent(String email) {
        return createAndSaveUser(email, UserRole.STUDENT, true);
    }

    /**
     * Helper: create verified alumni user
     */
    protected User createVerifiedAlumni(String email) {
        return createAndSaveUser(email, UserRole.ALUMNI, true);
    }

    /**
     * Helper: create verified club admin user
     */
    protected User createVerifiedClub(String email) {
        return createAndSaveUser(email, UserRole.CLUB_ADMIN, true);
    }

    /**
     * Helper: create verified system admin user
     */
    protected User createVerifiedAdmin(String email) {
        return createAndSaveUser(email, UserRole.SYSTEM_ADMIN, true);
    }

    /**
     * Helper: create unverified user
     */
    protected User createUnverifiedUser(String email, UserRole role) {
        return createAndSaveUser(email, role, false);
    }
}
