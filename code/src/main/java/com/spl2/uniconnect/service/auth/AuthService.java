package com.spl2.uniconnect.service.auth;

import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.auth.LoginRequest;
import com.spl2.uniconnect.dto.request.auth.RegisterRequest;
import com.spl2.uniconnect.dto.response.auth.LoginResponse;
import com.spl2.uniconnect.dto.response.auth.RegisterResponse;
import com.spl2.uniconnect.dto.response.auth.UserResponse;
import com.spl2.uniconnect.exception.EmailAlreadyExistsException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.security.JwtTokenProvider;
import com.spl2.uniconnect.security.UserDetailsImpl;
import com.spl2.uniconnect.service.email.EmailService;
import com.spl2.uniconnect.dto.request.auth.CreateAdminRequest;
import com.spl2.uniconnect.domain.user.AdminProfile;
import com.spl2.uniconnect.repository.user.AdminProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;
    private final EmailVerificationService emailVerificationService;
    private final AdminProfileRepository adminProfileRepository;
    /**
     * Register a new user
     */
    @Transactional
    public RegisterResponse register(RegisterRequest request) {
        log.info("Registering new user with email: {}", request.getEmail());

        // Check if email already exists
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new EmailAlreadyExistsException(request.getEmail());
        }

        // Create user entity
        User user = User.builder()
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName())
                .role(request.getRole())
                .emailVerified(false)
                .build();

        // Save user
        User savedUser = userRepository.save(user);

        // Send verification email
        emailVerificationService.sendVerificationEmail(savedUser);

        log.info("User registered successfully with ID: {}", savedUser.getUserId());

        return RegisterResponse.builder()
                .userId(savedUser.getUserId())
                .email(savedUser.getEmail())
                .fullName(savedUser.getFullName())
                .message("Registration successful! Please check your email to verify your account.")
                .build();
    }

    /**
     * Login user and generate JWT token
     */
    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        log.info("Login attempt for email: {}", request.getEmail());

        // Authenticate user (throws BadCredentialsException or DisabledException if failed)
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        // Generate JWT token
        String token = jwtTokenProvider.generateToken(authentication);

        // Get user details
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();

        // Get user entity
        User user = userRepository.findById(userDetails.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userDetails.getUserId()));

        log.info("User logged in successfully: {}", user.getEmail());

        return LoginResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .expiresIn(jwtTokenProvider.getExpirationSeconds())
                .user(mapToUserResponse(user))
                .build();
    }

    /**
     * Get current authenticated user
     */
    @Transactional(readOnly = true)
    public UserResponse getCurrentUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        return mapToUserResponse(user);
    }

    /**
     * Map User entity to UserResponse DTO
     */
    public UserResponse mapToUserResponse(User user) {
        return UserResponse.builder()
                .userId(user.getUserId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .role(user.getRole().toString())  // ⭐ Convert enum to String
                .profilePhoto(user.getProfilePhoto())
                .emailVerified(user.getEmailVerified())
                .createdAt(user.getCreatedAt())
                .build();
    }

    /**
     * Create a new admin account
     * Only accessible by SYSTEM_ADMIN
     */
    @Transactional
    public RegisterResponse createAdmin(CreateAdminRequest request) {
        log.info("Creating admin user with email: {}", request.getEmail());

        // 1. Check if email already exists
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new EmailAlreadyExistsException(
                    "Email already registered: " + request.getEmail()
            );
        }

        // 2. Create User with ADMIN role
        User user = User.builder()
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName())
                .role(UserRole.SYSTEM_ADMIN)  // ✅ Set ADMIN role
                .emailVerified(true)   // ✅ Auto-verify admin emails (they're trusted)
                .build();

        // 3. Save User
        User savedUser = userRepository.save(user);
        log.info("Admin user saved with ID: {}", savedUser.getUserId());

        // 4. Create AdminProfile
        AdminProfile adminProfile = AdminProfile.builder()
                .user(savedUser)
                .adminRole(request.getAdminRole())
                .build();

        AdminProfile savedAdminProfile = adminProfileRepository.save(adminProfile);
        log.info("Admin profile created for userId: {}", savedUser.getUserId());

        log.info("Admin account created successfully - Email: {}, Role: {}",
                request.getEmail(), request.getAdminRole());

        return RegisterResponse.builder()
                .userId(savedUser.getUserId())
                .email(savedUser.getEmail())
                .fullName(savedUser.getFullName())
                .message("Admin account created successfully!")
                .build();
    }
}

//REGISTRATION:
//─────────────
//RegisterRequest → check duplicate → hash password
//→ save user → send email → RegisterResponse
//
//
//LOGIN:
//──────
//LoginRequest → authenticationManager
//→ DaoAuthenticationProvider
//    → UserDetailsServiceImpl (load from DB)
//    → BCrypt (verify password)
//    → isEnabled() (email verified?)
//→ JwtTokenProvider (generate token)
//→ LoginResponse (token + user info)
//
//
//GET CURRENT USER:
//─────────────────
//JWT in header → JwtAuthenticationFilter
//→ SecurityContextHolder (userId = 42)
//→ SecurityUtils.getCurrentUserId()
//→ authService.getCurrentUser(42)
//→ DB lookup → UserResponse