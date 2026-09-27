package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.exception.ConflictException;
import com.uniconnect.shared.security.PlatformRole;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

@Service
public class RegistrationService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public RegistrationService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
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

        return userRepository.save(user);
    }
}
