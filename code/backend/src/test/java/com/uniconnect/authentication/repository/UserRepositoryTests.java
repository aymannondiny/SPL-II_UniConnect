package com.uniconnect.authentication.repository;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.domain.UserTestFactory;
import com.uniconnect.shared.security.AccountStatus;
import com.uniconnect.shared.security.PlatformRole;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase;
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase.Replace;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;


import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
@AutoConfigureTestDatabase(replace = Replace.NONE)
@ActiveProfiles("test")
class UserRepositoryTests {

    @Autowired
    private UserRepository userRepository;

    @Test
    void savesAndLoadsCanonicalUser() {
        User user = UserTestFactory.create(
                "Ayman",
                "ayman@example.com",
                "encoded-password",
                PlatformRole.STUDENT,
                AccountStatus.ACTIVE
        );

        User saved = userRepository.saveAndFlush(user);

        assertThat(saved.getUserId()).isNotNull();

        User loaded = userRepository.findById(saved.getUserId())
                .orElseThrow();

        assertThat(loaded.getFullName()).isEqualTo("Ayman");
        assertThat(loaded.getEmail()).isEqualTo("ayman@example.com");
        assertThat(loaded.getPasswordHash()).isEqualTo("encoded-password");
        assertThat(loaded.getPlatformRole()).isEqualTo(PlatformRole.STUDENT);
        assertThat(loaded.getAccountStatus()).isEqualTo(AccountStatus.ACTIVE);
        assertThat(loaded.getCreatedAt()).isNotNull();
        assertThat(loaded.getUpdatedAt()).isNotNull();
        assertThat(loaded.getAnonymizedAt()).isNull();
    }

    @Test
    void findsUserByEmail() {
        User user = UserTestFactory.create(
                "Ayman",
                "lookup@example.com",
                "encoded-password",
                PlatformRole.STUDENT,
                AccountStatus.ACTIVE
        );

        userRepository.saveAndFlush(user);

        assertThat(userRepository.findByEmail("lookup@example.com"))
                .isPresent();

        assertThat(userRepository.existsByEmail("lookup@example.com"))
                .isTrue();
    }

    @Test
    void rejectsDuplicateNonNullEmail() {
        User first = UserTestFactory.create(
                "First User",
                "duplicate@example.com",
                "encoded-password-1",
                PlatformRole.STUDENT,
                AccountStatus.ACTIVE
        );

        User second = UserTestFactory.create(
                "Second User",
                "duplicate@example.com",
                "encoded-password-2",
                PlatformRole.ALUMNI,
                AccountStatus.ACTIVE
        );

        userRepository.saveAndFlush(first);

        assertThatThrownBy(() -> userRepository.saveAndFlush(second))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void allowsMultipleNullEmails() {
        User first = UserTestFactory.create(
                null,
                null,
                null,
                PlatformRole.STUDENT,
                AccountStatus.SUSPENDED
        );

        User second = UserTestFactory.create(
                null,
                null,
                null,
                PlatformRole.ALUMNI,
                AccountStatus.SUSPENDED
        );

        userRepository.saveAndFlush(first);
        userRepository.saveAndFlush(second);

        assertThat(first.getUserId()).isNotNull();
        assertThat(second.getUserId()).isNotNull();
        assertThat(first.getUserId()).isNotEqualTo(second.getUserId());
    }
}
