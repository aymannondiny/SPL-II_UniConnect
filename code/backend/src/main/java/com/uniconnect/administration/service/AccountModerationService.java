package com.uniconnect.administration.service;

import com.uniconnect.administration.dto.*;
import com.uniconnect.administration.repository.AdministrationRepository;
import com.uniconnect.authentication.service.AccountAdministrationService;
import com.uniconnect.club.service.ClubAssignmentSetChangedException;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.ConflictException;
import com.uniconnect.shared.security.*;
import com.uniconnect.shared.validation.PageValidation;
import java.util.Locale;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AccountModerationService {
    private static final int MAX_ATTEMPTS = 3;
    private final AccountModerationAttemptService attempts;
    private final AccountAdministrationService accounts;
    private final AdministrationRepository administration;

    public AccountModerationService(AccountModerationAttemptService attempts,
            AccountAdministrationService accounts, AdministrationRepository administration) {
        this.attempts = attempts; this.accounts = accounts; this.administration = administration;
    }

    public AccountResponse suspend(SessionPrincipal actor, long targetId, AccountModerationRequest request) {
        for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
            try { return attempts.suspend(actor, targetId, request); }
            catch (ClubAssignmentSetChangedException changed) {
                if (attempt == MAX_ATTEMPTS) throw concurrentChange();
            }
        }
        throw concurrentChange();
    }

    public AccountResponse restore(SessionPrincipal actor, long targetId, AccountModerationRequest request) {
        return attempts.restore(actor, targetId, request);
    }

    @Transactional
    public PageResponse<AccountResponse> search(SessionPrincipal actor, String query, PlatformRole role,
            AccountStatus status, int page, int size) {
        PageValidation.check(page, size);
        String term = query == null ? "" : query.strip().toLowerCase(Locale.ROOT);
        if (term.length() > 150) throw new com.uniconnect.shared.exception.BadRequestException(
                "INVALID_SEARCH", "Account search must not exceed 150 characters.");
        accounts.requireAdministration(actor);
        var result = accounts.search(term, role, status, PageRequest.of(page, size, Sort.by("userId")));
        return new PageResponse<>(result.map(AccountResponse::from).getContent(), page, size, result.getTotalElements());
    }

    @Transactional
    public AccountResponse get(SessionPrincipal actor, long targetId) {
        return AccountResponse.from(accounts.lockTarget(actor, targetId));
    }

    @Transactional
    public PageResponse<AccountAuditResponse> audit(SessionPrincipal actor, long targetId, int page, int size) {
        PageValidation.check(page, size);
        accounts.lockTarget(actor, targetId);
        var rows = administration.audit(targetId, page, size).stream().map(AccountAuditResponse::from).toList();
        return new PageResponse<>(rows, page, size, administration.auditCount(targetId));
    }

    private ConflictException concurrentChange() {
        return new ConflictException("CONCURRENT_ACCOUNT_CHANGE",
                "The account's club administration assignment changed. Retry the request.");
    }
}
