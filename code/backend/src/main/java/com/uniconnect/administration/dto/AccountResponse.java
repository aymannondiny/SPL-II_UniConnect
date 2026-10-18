package com.uniconnect.administration.dto;

import com.uniconnect.authentication.service.AccountAdministrationService.Account;
import com.uniconnect.shared.security.*;
import java.time.LocalDateTime;

public record AccountResponse(long userId, String fullName, String email, PlatformRole platformRole,
        AccountStatus accountStatus, LocalDateTime createdAt, LocalDateTime updatedAt) {
    public static AccountResponse from(Account account) {
        return new AccountResponse(account.id(), account.fullName(), account.email(), account.role(),
                account.status(), account.createdAt(), account.updatedAt());
    }
}
