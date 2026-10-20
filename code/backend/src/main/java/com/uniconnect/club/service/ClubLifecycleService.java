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
    public record ClubModerationEvidence(long auditId,long clubId,String actionType,LocalDateTime occurredAt) {}
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
    public ClubResponse archive(SessionPrincipal actor, long id, ClubLifecycleRequest request) {
        return change(actor, id, request, ClubStatus.ARCHIVED);
    }
    public ClubResponse restoreArchive(SessionPrincipal actor, long id, ClubLifecycleRequest request) {
        validation.check(request);
        // Keep the club -> assignments -> accounts lock order used by other lifecycle writes.
        var club = clubs.lock(id);
        var operators = club == null ? List.<ClubRoleAssignment>of() : clubs.currentOperators(id);
        var locked = accounts.lock(actor, operators.stream().map(ClubRoleAssignment::getUserId).toList());
        contexts.requireSystem(actor, locked.get(actor.userId()));
        if (club == null) throw new ResourceNotFoundException("Club", id);
        if (club.getStatus() != ClubStatus.ARCHIVED)
            throw new ConflictException("INVALID_CLUB_STATE", "Only archived clubs can be restored from the archive.");
        var archived = clubs.latestLifecycleAudit(id);
        if (archived == null || !archived.getAction().equals("CLUB_ARCHIVED")
                || archived.getNewState() != ClubStatus.ARCHIVED) {
            throw new ConflictException("INVALID_CLUB_STATE", "The archive history required to restore this club is unavailable.");
        }
        var previousStatus = archived.getPreviousState();
        if (previousStatus != ClubStatus.ACTIVE && previousStatus != ClubStatus.PUBLISHING_SUSPENDED)
            throw new ConflictException("INVALID_CLUB_STATE", "The club's previous status cannot be restored.");
        var administrators = operators.stream().filter(a -> a.getRole() == ClubRole.CLUB_ADMINISTRATOR).toList();
        if (administrators.stream().noneMatch(a -> locked.get(a.getUserId()).eligibleStudent()))
            throw new ConflictException("INELIGIBLE_CLUB_ADMINISTRATOR", "Assign an eligible current student administrator before restoring this archived club.");

        var now = LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
        String reason = request.reason().strip();
        club.restoreArchive(previousStatus, now);
        var audit = clubs.insert(ClubAudit.lifecycle(id, actor.userId(), "CLUB_ARCHIVE_RESTORED",
                reason, ClubStatus.ARCHIVED, previousStatus, now));
        for (var administrator : administrators)
            if (locked.get(administrator.getUserId()).eligibleStudent())
                notifications.publishingChanged(administrator.getUserId(), id, audit.getId(), previousStatus == ClubStatus.ACTIVE);
        return mapper.club(club);
    }
    public ClubResponse remove(SessionPrincipal actor, long id, ClubLifecycleRequest request) {
        return change(actor, id, request, ClubStatus.REMOVED);
    }
    public ClubResponse delete(SessionPrincipal actor, long id, ClubLifecycleRequest request) {
        return remove(actor, id, request);
    }
    public ClubModerationEvidence verifyModerationEvidence(long auditId){
        // Lifecycle restoration locks this same audit row before recording reversal.
        // Holding it through report commit prevents validation/link races without
        // changing the established club -> accounts lock order of lifecycle writes.
        var audit=clubs.lockAudit(auditId);
        if(audit==null||!(audit.getAction().equals("CLUB_PUBLISHING_SUSPENDED")
                || audit.getAction().equals("CLUB_ARCHIVED") || audit.getAction().equals("CLUB_REMOVED")))
            throw new ConflictException("INVALID_ACTION_EVIDENCE","Club evidence must reference a publishing suspension, archive or deletion.");
        String restorationAction = switch (audit.getAction()) {
            case "CLUB_PUBLISHING_SUSPENDED" -> "CLUB_PUBLISHING_RESTORED";
            case "CLUB_ARCHIVED" -> "CLUB_ARCHIVE_RESTORED";
            default -> null;
        };
        if(restorationAction != null && clubs.restoredAfter(audit.getClubId(),auditId,restorationAction))
            throw new ConflictException("INVALID_ACTION_EVIDENCE","The club action evidence was already reversed.");
        return new ClubModerationEvidence(audit.getId(),audit.getClubId(),audit.getAction(),audit.getCreatedAt());
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
        if (before == ClubStatus.REMOVED) throw new ConflictException("INVALID_CLUB_STATE", "Deleted clubs cannot be restored or changed.");
        if (before == ClubStatus.ARCHIVED && next != ClubStatus.REMOVED)
            throw new ConflictException("INVALID_CLUB_STATE", "Archived clubs must be restored before changing their publishing status.");
        if (next == ClubStatus.ACTIVE && before == ClubStatus.PUBLISHING_SUSPENDED
                && clubs.lockLatestPublishingSuspension(id) == null)
            throw new ConflictException("INVALID_CLUB_STATE", "The publishing suspension audit is unavailable.");
        var administrators = operators.stream().filter(a -> a.getRole() == ClubRole.CLUB_ADMINISTRATOR).toList();
        if (next == ClubStatus.ACTIVE && administrators.stream().noneMatch(a -> locked.get(a.getUserId()).eligibleStudent()))
            throw new ConflictException("INELIGIBLE_CLUB_ADMINISTRATOR", "An eligible current student administrator is required before restoring publishing.");
        var now = LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
        String reason = request.reason().strip();
        String action;
        switch (next) {
            case PUBLISHING_SUSPENDED -> { club.suspendPublishing(now); action = "CLUB_PUBLISHING_SUSPENDED"; }
            case ACTIVE -> { club.restorePublishing(now); action = "CLUB_PUBLISHING_RESTORED"; }
            case ARCHIVED -> { club.archive(now); action = "CLUB_ARCHIVED"; }
            case REMOVED -> {
                club.delete(now); action = "CLUB_REMOVED";
            }
            default -> throw new IllegalStateException("Unsupported club state.");
        }
        var audit = clubs.insert(ClubAudit.lifecycle(id, actor.userId(), action, reason, before, next, now));
        // Notify every current administrator; no broadcast to all members.
        if (next == ClubStatus.ACTIVE || next == ClubStatus.PUBLISHING_SUSPENDED)
            for (var administrator : administrators)
                notifications.publishingChanged(administrator.getUserId(), id, audit.getId(), next == ClubStatus.ACTIVE);
        return mapper.club(club);
    }
}
