package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.exception.ConflictException;
import com.uniconnect.shared.security.PlatformRole;
import java.util.Locale;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RegistrationService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailVerificationService verificationService;

    public RegistrationService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            EmailVerificationService verificationService
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.verificationService = verificationService;
    }

    @Transactional
    public User register(
            String fullName,
            String email,
            String rawPassword,
            PlatformRole platformRole
    ) {
        if (platformRole == PlatformRole.SYSTEM_ADMIN) {
            throw new BadRequestException(
                    "INVALID_REGISTRATION_ROLE",
                    "SYSTEM_ADMIN cannot be selected during public registration"
            );
        }

        String normalizedEmail = email.trim().toLowerCase(Locale.ROOT);

        if (!normalizedEmail.endsWith("@iut-dhaka.edu")) {
            throw new BadRequestException(
                    "INVALID_EMAIL_DOMAIN",
                    "Registration requires an IUT email address ending with @iut-dhaka.edu"
            );
        }

        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new ConflictException(
                    "EMAIL_ALREADY_EXISTS",
                    "An account with this email already exists"
            );
        }

        String passwordHash = passwordEncoder.encode(rawPassword);

        User user = User.register(
                fullName,
                normalizedEmail,
                passwordHash,
                platformRole
        );

        User saved = userRepository.save(user);
        verificationService.issueForRegistration(saved);
        return saved;
    }
}
