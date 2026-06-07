package com.spl2.uniconnect.config;

import com.spl2.uniconnect.domain.user.AdminProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.repository.user.AdminProfileRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
@Slf4j
@Profile("!test")
public class BootstrapDataLoader {

    private final UserRepository userRepository;
    private final AdminProfileRepository adminProfileRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * Bootstrap data loader - Creates default system admin on startup
     */
    @Bean
    public CommandLineRunner loadBootstrapData() {
        return args -> {
            log.info("========================================");
            log.info("Starting Bootstrap Data Loader...");
            log.info("========================================");

            try {
                // Check if system admin already exists
                boolean adminExists = userRepository
                        .findByEmail("systemadmin@iut-dhaka.edu")
                        .isPresent();

                if (adminExists) {
                    log.info("✅ System admin account already exists - skipping creation");
                    log.info("========================================");
                    return;
                }

                log.info("❌ System admin not found - creating...");

                // 1. Create system admin user
                User systemAdmin = User.builder()
                        .email("systemadmin@iut-dhaka.edu")
                        .passwordHash(passwordEncoder.encode("AdminPassword123"))
                        .fullName("System Administrator")
                        .role(UserRole.SYSTEM_ADMIN)
                        .emailVerified(true)
                        .build();

                User savedAdmin = userRepository.save(systemAdmin);
                log.info("✅ System admin user created with ID: {}", savedAdmin.getUserId());
                log.info("   Email: {}", savedAdmin.getEmail());
                log.info("   Role: {}", savedAdmin.getRole());

                // 2. Refresh user from DB to avoid detached entity error
                User managedUser = userRepository.findById(savedAdmin.getUserId())
                        .orElseThrow(() -> new RuntimeException("Failed to retrieve saved admin user"));

                // 3. Create admin profile
                AdminProfile adminProfile = AdminProfile.builder()
                        .user(managedUser)  // ← Use fresh managed user
                        .adminRole("Super Admin")
                        .build();

                AdminProfile savedProfile = adminProfileRepository.save(adminProfile);
                log.info("✅ System admin profile created successfully");
                log.info("   Admin Role: {}", savedProfile.getAdminRole());

                log.info("========================================");
                log.info("Bootstrap Data Loader Completed Successfully!");
                log.info("========================================");
                log.info("You can now login with:");
                log.info("   Email: systemadmin@iut-dhaka.edu");
                log.info("   Password: AdminPassword123");
                log.info("========================================");

            } catch (Exception e) {
                log.error("❌ Error during bootstrap data loading", e);
                log.error("========================================");
                throw new RuntimeException("Bootstrap data loading failed", e);
            }
        };
    }
}



//curl -X POST http://localhost:8080/api/auth/login \
//  -H "Content-Type: application/json" \
//  -d '{
//    "email": "systemadmin@iut-dhaka.edu",
//    "password": "AdminPassword123"
//  }'


//# Replace TOKEN with the JWT from login response
//TOKEN="your-jwt-token-here"
//
//curl -X GET http://localhost:8080/api/auth/me \
//  -H "Authorization: Bearer $TOKEN"



//TOKEN="your-jwt-token-here"
//
//curl -X POST http://localhost:8080/api/auth/create-admin \
//  -H "Content-Type: application/json" \
//  -H "Authorization: Bearer $TOKEN" \
//  -d '{
//    "email": "moderator@iut-dhaka.edu",
//    "password": "ModeratorPassword123",
//    "fullName": "Content Moderator",
//    "adminRole": "Content Moderator"
//  }'
