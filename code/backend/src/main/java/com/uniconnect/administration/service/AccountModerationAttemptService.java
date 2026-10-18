package com.uniconnect.administration.service;

import com.uniconnect.administration.domain.*;
import com.uniconnect.administration.dto.*;
import com.uniconnect.administration.repository.AdministrationRepository;
import com.uniconnect.authentication.service.*;
import com.uniconnect.club.service.ClubAccountModerationService;
import com.uniconnect.notification.service.AccountNotificationService;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import java.time.*;
import java.util.List;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

@Service
public class AccountModerationAttemptService {
    private final AccountAdministrationService accounts;
    private final SessionService sessions;
    private final ClubAccountModerationService clubs;
    private final AdministrationRepository administration;
    private final AccountNotificationService notifications;
    private final ApplicationEventPublisher events;
    private final Clock clock;

    public AccountModerationAttemptService(AccountAdministrationService accounts, SessionService sessions,
            ClubAccountModerationService clubs, AdministrationRepository administration,
            AccountNotificationService notifications, ApplicationEventPublisher events, Clock clock) {
        this.accounts = accounts; this.sessions = sessions; this.clubs = clubs;
        this.administration = administration; this.notifications = notifications;
        this.events = events; this.clock = clock;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public AccountResponse suspend(SessionPrincipal actor, long targetId, AccountModerationRequest request) {
        var candidates = clubs.discover(targetId);
        clubs.lockCandidates(candidates);
        var target = accounts.lockTarget(actor, targetId);
        requireEligibleMember(target);
        if (target.status() == AccountStatus.SUSPENDED) return AccountResponse.from(target);
        if (target.status() != AccountStatus.ACTIVE) throw invalidState("Only ACTIVE member accounts can be suspended.");

        // At READ_COMMITTED this scalar query executes against the database after the account lock.
        // Assignment writers need the same target account lock, so a missing club means retry or later ineligibility.
        clubs.requireNoAdditionalClub(targetId, candidates);
        var now = now();
        String reason = request.reason().strip();
        clubs.suspendAdministeredClubs(actor.userId(), targetId, candidates, reason, now);
        accounts.suspendLocked(targetId, now);
        sessions.revokeAllForAccount(targetId);
        var action = record(actor.userId(), targetId, ModerationActionType.SUSPEND_ACCOUNT,
                AuditEventType.ACCOUNT_SUSPENDED, reason, AccountStatus.ACTIVE, AccountStatus.SUSPENDED, null, now);
        notifications.statusChanged(targetId, action.getId(), false, now);
        events.publishEvent(new AccountSessionsRevoked(targetId));
        return AccountResponse.from(accounts.lockTarget(actor, targetId));
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public AccountResponse restore(SessionPrincipal actor, long targetId, AccountModerationRequest request) {
        var target = accounts.lockTarget(actor, targetId);
        requireEligibleMember(target);
        if (target.status() == AccountStatus.ACTIVE) return AccountResponse.from(target);
        if (target.status() != AccountStatus.SUSPENDED) throw invalidState("Only SUSPENDED member accounts can be restored.");
        var now = now();
        String reason = request.reason().strip();
        accounts.restoreLocked(targetId, now);
        var reversed = administration.latestOpenSuspension(targetId);
        reversed.ifPresent(action -> action.markReversed(now));
        var action = record(actor.userId(), targetId, ModerationActionType.REACTIVATE_ACCOUNT,
                AuditEventType.ACCOUNT_REACTIVATED, reason, AccountStatus.SUSPENDED, AccountStatus.ACTIVE,
                reversed.map(ModerationAction::getId).orElse(null), now);
        notifications.statusChanged(targetId, action.getId(), true, now);
        return AccountResponse.from(accounts.lockTarget(actor, targetId));
    }

    private ModerationAction record(long actorId, long targetId, ModerationActionType actionType,
            AuditEventType eventType, String reason, AccountStatus before, AccountStatus after,
            Long reversalOfActionId, LocalDateTime now) {
        var action = administration.insert(new ModerationAction(actorId, targetId, actionType,
                reason, before, after, reversalOfActionId, now));
        administration.insert(new AuditLog(action, eventType, state(before), state(after), now));
        return action;
    }

    private void requireEligibleMember(AccountAdministrationService.Account target) {
        if (target.role() == PlatformRole.SYSTEM_ADMIN) {
            throw new ForbiddenException("System administrator accounts are excluded from account moderation.");
        }
        if (target.anonymized() || (target.role() != PlatformRole.STUDENT && target.role() != PlatformRole.ALUMNI)) {
            throw invalidState("Only non-anonymized student or alumni accounts can be moderated.");
        }
    }

    private String state(AccountStatus status) { return "{\"accountStatus\":\"" + status.name() + "\"}"; }
    private ConflictException invalidState(String message) { return new ConflictException("INVALID_ACCOUNT_STATE", message); }
    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }
}
