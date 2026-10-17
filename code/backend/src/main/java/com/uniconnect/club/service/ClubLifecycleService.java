package com.uniconnect.club.service;

import com.uniconnect.authentication.service.ClubAccountService;
import com.uniconnect.authentication.service.SessionContextService;
import com.uniconnect.club.domain.*;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.mapper.ClubMapper;
import com.uniconnect.club.repository.ClubRepository;
import com.uniconnect.notification.service.ClubNotificationService;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import java.time.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ClubLifecycleService {
    private final ClubRepository clubs;
    private final ClubAccountService accounts;
    private final ClubContextService contexts;
    private final SessionContextService sessions;
    private final ClubNotificationService notifications;
    private final ClubValidation validation;
    private final ClubMapper mapper;
    private final Clock clock;

    public ClubLifecycleService(ClubRepository clubs, ClubAccountService accounts, ClubContextService contexts,
            SessionContextService sessions, ClubNotificationService notifications, ClubValidation validation,
            ClubMapper mapper, Clock clock) {
        this.clubs = clubs; this.accounts = accounts; this.contexts = contexts; this.sessions = sessions;
        this.notifications = notifications; this.validation = validation; this.mapper = mapper; this.clock = clock;
    }
    public ClubResponse get(SessionPrincipal actor, long id) {
        var club = clubs.lock(id);
        contexts.requireSystem(actor, accounts.lock(actor, List.of()).get(actor.userId()));
        if (club == null) throw new ResourceNotFoundException("Club", id);
        return mapper.club(club);
    }
    public ClubResponse suspend(SessionPrincipal actor, long id, ClubLifecycleRequest request) {
        return change(actor, id, request, ClubStatus.PUBLISHING_SUSPENDED);
    }
    public ClubResponse restore(SessionPrincipal actor, long id, ClubLifecycleRequest request) {
        return change(actor, id, request, ClubStatus.ACTIVE);
    }
    public ClubResponse remove(SessionPrincipal actor, long id, ClubLifecycleRequest request) {
        return change(actor, id, request, ClubStatus.REMOVED);
    }
    private ClubResponse change(SessionPrincipal actor, long id, ClubLifecycleRequest request, ClubStatus next) {
        validation.check(request);
        // Same lock order as publication writes, context selection and assignment changes.
        var club = clubs.lock(id);
        var operators = club == null ? List.<ClubRoleAssignment>of() : clubs.currentOperators(id);
        var locked = accounts.lock(actor, operators.stream().map(ClubRoleAssignment::getUserId).toList());
        contexts.requireSystem(actor, locked.get(actor.userId()));
        if (club == null) throw new ResourceNotFoundException("Club", id);
        var before = club.getStatus();
        if (before == next) return mapper.club(club); // Authorized retries produce no duplicate audit or notification.
        if (before == ClubStatus.REMOVED) throw new ConflictException("INVALID_CLUB_STATE", "Removed clubs cannot be restored or suspended.");
        var administrators = operators.stream().filter(a -> a.getRole() == ClubRole.CLUB_ADMINISTRATOR).toList();
        if (next == ClubStatus.ACTIVE && (administrators.size() != 1 || !locked.get(administrators.getFirst().getUserId()).eligibleStudent()))
            throw new ConflictException("INELIGIBLE_CLUB_ADMINISTRATOR", "An eligible current student administrator is required before restoring publishing.");
        var now = LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
        String reason = request.reason().strip();
        String action;
        switch (next) {
            case PUBLISHING_SUSPENDED -> { club.suspendPublishing(now); action = "CLUB_PUBLISHING_SUSPENDED"; }
            case ACTIVE -> { club.restorePublishing(now); action = "CLUB_PUBLISHING_RESTORED"; }
            case REMOVED -> {
                club.remove(now); action = "CLUB_REMOVED";
                for (var assignment : operators) {
                    assignment.revoke(actor.userId(), now);
                    sessions.revokeAssignment(assignment.getId());
                    clubs.insert(new ClubAudit(id, actor.userId(), null, assignment.getId(), "ROLE_REVOKED", reason, now));
                    notifications.roleChanged(assignment.getUserId(), id, assignment.getId(), assignment.getRole().name(), false);
                }
            }
            default -> throw new IllegalStateException("Unsupported club state.");
        }
        var audit = clubs.insert(ClubAudit.lifecycle(id, actor.userId(), action, reason, before, next, now));
        // One informational event to the current administrator; no broadcast to all members.
        if (next != ClubStatus.REMOVED && administrators.size() == 1)
            notifications.publishingChanged(administrators.getFirst().getUserId(), id, audit.getId(), next == ClubStatus.ACTIVE);
        return mapper.club(club);
    }
}
