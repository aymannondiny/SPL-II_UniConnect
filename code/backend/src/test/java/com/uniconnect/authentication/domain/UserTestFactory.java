package com.uniconnect.authentication.domain;

import com.uniconnect.shared.security.AccountStatus;
import com.uniconnect.shared.security.PlatformRole;

import java.time.LocalDateTime;

public final class UserTestFactory {

    private UserTestFactory() {
    }

    public static User create(
            String fullName,
            String email,
            String passwordHash,
            PlatformRole platformRole,
            AccountStatus accountStatus
    ) {
        LocalDateTime now = LocalDateTime.now();

        return new User(
                fullName,
                email,
                passwordHash,
                platformRole,
                accountStatus,
                now,
                now
        );
    }

    public static User createWithAnonymizedAt(
            String fullName,
            String email,
            String passwordHash,
            PlatformRole platformRole,
            AccountStatus accountStatus,
            LocalDateTime anonymizedAt
    ) {
        User user = create(
                fullName,
                email,
                passwordHash,
                platformRole,
                accountStatus
        );

        try {
            var field = User.class.getDeclaredField("anonymizedAt");
            field.setAccessible(true);
            field.set(user, anonymizedAt);
        } catch (ReflectiveOperationException exception) {
            throw new IllegalStateException(exception);
        }

        return user;
    }
}