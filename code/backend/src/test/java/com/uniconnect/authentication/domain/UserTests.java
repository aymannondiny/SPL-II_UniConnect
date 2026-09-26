package com.uniconnect.authentication.domain;

import com.uniconnect.shared.security.AccountStatus;
import com.uniconnect.shared.security.PlatformRole;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class UserTests {

    @Test
    void activeNonAnonymizedUserCanAuthenticate() {
        User user = createUser(AccountStatus.ACTIVE);

        assertThat(user.canAuthenticate()).isTrue();
        assertThat(user.canPerformProtectedAction()).isTrue();
        assertThat(user.isAnonymized()).isFalse();
    }

    @Test
    void pendingVerificationUserCannotAuthenticate() {
        User user = createUser(AccountStatus.PENDING_VERIFICATION);

        assertThat(user.canAuthenticate()).isFalse();
        assertThat(user.canPerformProtectedAction()).isFalse();
    }

    @Test
    void suspendedUserCannotAuthenticate() {
        User user = createUser(AccountStatus.SUSPENDED);

        assertThat(user.canAuthenticate()).isFalse();
        assertThat(user.canPerformProtectedAction()).isFalse();
    }

    @Test
    void anonymizedUserCannotAuthenticateEvenWhenStatusIsActive() {
        User user = UserTestFactory.createWithAnonymizedAt(
                "Ayman",
                "ayman@example.com",
                "encoded-password",
                PlatformRole.STUDENT,
                AccountStatus.ACTIVE,
                LocalDateTime.now()
        );

        assertThat(user.isAnonymized()).isTrue();
        assertThat(user.canAuthenticate()).isFalse();
        assertThat(user.canPerformProtectedAction()).isFalse();
    }

    private User createUser(AccountStatus accountStatus) {
        return UserTestFactory.create(
                "Ayman",
                "ayman@example.com",
                "encoded-password",
                PlatformRole.STUDENT,
                accountStatus
        );
    }
}