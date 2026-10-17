package com.uniconnect.authentication.dto;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.shared.security.AccountStatus;
import com.uniconnect.shared.security.PlatformRole;

public record RegisterResponse(
        Long userId,
        String fullName,
        String email,
        PlatformRole platformRole,
        AccountStatus accountStatus
) {

    public static RegisterResponse from(User user) {
        return new RegisterResponse(
                user.getUserId(),
                user.getFullName(),
                user.getEmail(),
                user.getPlatformRole(),
                user.getAccountStatus()
        );
    }
}
