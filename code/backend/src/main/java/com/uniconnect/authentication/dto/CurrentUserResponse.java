package com.uniconnect.authentication.dto;

import com.uniconnect.shared.security.AccountStatus;
import com.uniconnect.shared.security.PlatformRole;

public record CurrentUserResponse(Long userId, String fullName, String email,
        PlatformRole platformRole, AccountStatus accountStatus) { }
