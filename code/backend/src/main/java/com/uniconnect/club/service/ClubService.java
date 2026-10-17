package com.uniconnect.club.service;

import com.uniconnect.authentication.service.ClubAccountService;
import com.uniconnect.authentication.service.ClubAccountService.Account;
import com.uniconnect.authentication.service.SessionContextService;
import com.uniconnect.club.domain.*;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.mapper.ClubMapper;
import com.uniconnect.club.repository.ClubRepository;
import com.uniconnect.notification.service.ClubNotificationService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import java.time.*;
import java.util.*;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ClubService {
    private final ClubRepository clubs;
    private final ClubAccountService accounts;
    private final ClubContextService contexts;
    private final SessionContextService sessions;
    private final ClubNotificationService notifications;
    private final ClubMapper mapper;
    private final ClubValidation validation;
    private final Clock clock;
    public ClubService(ClubRepository clubs, ClubAccountService accounts, ClubContextService contexts,
            SessionContextService sessions, ClubNotificationService notifications, ClubMapper mapper, ClubValidation validation, Clock clock) {
        this.clubs = clubs; this.accounts = accounts; this.contexts = contexts; this.sessions = sessions;
        this.notifications = notifications; this.mapper = mapper; this.validation = validation; this.clock = clock;
    }
    public ClubResponse create(SessionPrincipal actor, CreateClubRequest request) {
        validation.check(request);
        var locked = accounts.lock(actor, List.of(request.administratorUserId()));
        contexts.requireSystem(actor, locked.get(actor.userId()));
        eligible(locked.get(request.administratorUserId()));
        if (clubs.administersAny(request.administratorUserId())) throw conflict("ADMINISTRATOR_ALREADY_ASSIGNED", "This student already administers a club.");
        String name = request.clubName().strip();
        if (clubs.nameExists(Club.key(name))) throw conflict("CLUB_NAME_EXISTS", "A club with this name already exists.");
        Club club;
        try {
            club = clubs.insert(new Club(name, request.category().strip(), request.description().strip(), validation.logo(request.logoUrl()), validation.optional(request.contactEmail()), now()));
        } catch (DataIntegrityViolationException duplicate) {
            throw conflict("CLUB_NAME_EXISTS", "A club with this name already exists.");
        }
        var assignment = grant(club, request.administratorUserId(), ClubRole.CLUB_ADMINISTRATOR, actor, null, "Initial administrator appointed during creation.");
        audit(club, actor, null, assignment, "CLUB_CREATED", "Club and first administrator created atomically.");
        return mapper.club(club);
    }
    public PageResponse<ClubResponse> directory(SessionPrincipal actor, String query, int page, int size) {
        accounts.lock(actor, List.of()); PageValidation.check(page, size);
        String search = query == null ? "" : query.strip().toLowerCase(Locale.ROOT);
        if (search.length() > 150) throw new BadRequestException("INVALID_SEARCH", "Club search must not exceed 150 characters.");
        return new PageResponse<>(clubs.directory(search, page, size).stream().map(mapper::club).toList(), page, size, clubs.directoryCount(search));
    }
    public ClubResponse get(SessionPrincipal actor, long id) {
        accounts.lock(actor, List.of());
        var club = clubs.find(id);
        if (club == null || club.getStatus() == ClubStatus.REMOVED) throw missing(id);
        return mapper.club(club);
    }
    public AssignmentResponse assignRepresentative(SessionPrincipal actor, long id, AssignRepresentativeRequest request) {
        validation.check(request); var club = lockedClub(id);
        var locked = accounts.lock(actor, List.of(request.userId()));
        var acting = contexts.requireAdministrator(actor, club, locked.get(actor.userId()));
        eligible(locked.get(request.userId()));
        if (clubs.current(id, request.userId()).isPresent()) throw conflict("CLUB_ROLE_ALREADY_ASSIGNED", "This student already holds a current role for this club.");
        var assignment = grant(club, request.userId(), ClubRole.REPRESENTATIVE, actor, acting.getId(), "Representative assigned by club administrator.");
        return mapper.assignment(assignment, locked.get(request.userId()).fullName());
    }
    public PageResponse<AssignmentResponse> operators(SessionPrincipal actor, long id, String status, int page, int size) {
        var club = lockedClub(id); var account = accounts.lock(actor, List.of()).get(actor.userId());
        contexts.requireAdministrator(actor, club, account); PageValidation.check(page, size);
        if (!Set.of("CURRENT", "REVOKED", "ALL").contains(status)) throw new BadRequestException("INVALID_ASSIGNMENT_FILTER", "Status must be CURRENT, REVOKED, or ALL.");
        var rows = clubs.operators(id, status, page, size).stream().map(a -> mapper.assignment(a, accounts.displayName(a.getUserId()))).toList();
        return new PageResponse<>(rows, page, size, clubs.operatorCount(id, status));
    }
    public AssignmentResponse revokeRepresentative(SessionPrincipal actor, long id, long assignmentId, RevokeRepresentativeRequest request) {
        validation.check(request); var club = lockedClub(id);
        var target = clubs.assignment(assignmentId);
        if (target == null || target.getClubId() != id) throw new ResourceNotFoundException("Assignment", assignmentId);
        var locked = accounts.lock(actor, List.of(target.getUserId()));
        var acting = contexts.requireAdministrator(actor, club, locked.get(actor.userId()));
        if (target.getRole() != ClubRole.REPRESENTATIVE) throw new ForbiddenException("Use system administrator replacement to change a club administrator.");
        if (!target.isCurrent()) throw conflict("ASSIGNMENT_REVOKED", "This assignment is already revoked.");
        revoke(club, target, actor, acting.getId(), request.reason().strip());
        return mapper.assignment(target, locked.get(target.getUserId()).fullName());
    }
    public AssignmentResponse replaceAdministrator(SessionPrincipal actor, long id, ReplaceAdministratorRequest request) {
        validation.check(request); var club = lockedClub(id);
        var previous = clubs.administrator(id).orElseThrow(() -> conflict("MISSING_CLUB_ADMINISTRATOR", "Club has no current administrator."));
        var locked = accounts.lock(actor, List.of(previous.getUserId(), request.userId()));
        contexts.requireSystem(actor, locked.get(actor.userId())); eligible(locked.get(request.userId()));
        if (clubs.administersAny(request.userId())) throw conflict("ADMINISTRATOR_ALREADY_ASSIGNED", "Replacement already administers a club.");
        String reason = request.reason().strip();
        // Promotion revokes the old representative assignment; authoring history is retained.
        clubs.current(id, request.userId()).ifPresent(a -> revoke(club, a, actor, null, reason));
        revoke(club, previous, actor, null, reason);
        clubs.flush(); // Release unique current-administrator keys before inserting the replacement.
        var replacement = grant(club, request.userId(), ClubRole.CLUB_ADMINISTRATOR, actor, null, reason);
        audit(club, actor, null, replacement, "ADMINISTRATOR_REPLACED", reason);
        return mapper.assignment(replacement, locked.get(request.userId()).fullName());
    }
    public PageResponse<ClubAuditResponse> auditHistory(SessionPrincipal actor, long id, int page, int size) {
        var club = clubs.lock(id);
        var account = accounts.lock(actor, List.of()).get(actor.userId());
        contexts.requireSystem(actor, account);
        if (club == null) throw missing(id);
        PageValidation.check(page, size);
        return new PageResponse<>(clubs.audit(id, page, size).stream().map(mapper::audit).toList(), page, size, clubs.auditCount(id));
    }
    private ClubRoleAssignment grant(Club club, long user, ClubRole role, SessionPrincipal actor, Long acting, String reason) {
        var assignment = clubs.insert(new ClubRoleAssignment(club.getId(), user, role, actor.userId(), now()));
        notifications.roleChanged(user, club.getId(), assignment.getId(), role.name(), true);
        audit(club, actor, acting, assignment, "ROLE_GRANTED", reason);
        return assignment;
    }
    private void revoke(Club club, ClubRoleAssignment target, SessionPrincipal actor, Long acting, String reason) {
        target.revoke(actor.userId(), now());
        sessions.revokeAssignment(target.getId());
        notifications.roleChanged(target.getUserId(), club.getId(), target.getId(), target.getRole().name(), false);
        audit(club, actor, acting, target, "ROLE_REVOKED", reason);
    }
    private void audit(Club club, SessionPrincipal actor, Long acting, ClubRoleAssignment target, String action, String reason) {
        clubs.insert(new ClubAudit(club.getId(), actor.userId(), acting, target.getId(), action, reason, now()));
    }
    private Club lockedClub(long id) {
        var club = clubs.lock(id);
        if (club == null || club.getStatus() == ClubStatus.REMOVED) throw missing(id);
        return club;
    }
    private void eligible(Account account) { if (!account.eligibleStudent()) throw new BadRequestException("INELIGIBLE_CLUB_ASSIGNEE", "Club assignees must be ACTIVE, non-anonymized students."); }
    private ConflictException conflict(String code, String message) { return new ConflictException(code, message); }
    private ResourceNotFoundException missing(long id) { return new ResourceNotFoundException("Club", id); }
    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }
}
