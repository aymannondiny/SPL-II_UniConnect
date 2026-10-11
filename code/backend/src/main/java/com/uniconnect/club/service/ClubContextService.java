package com.uniconnect.club.service;

import com.uniconnect.authentication.service.ClubAccountService;
import com.uniconnect.authentication.service.ClubAccountService.Account;
import com.uniconnect.authentication.service.SessionContextService;
import com.uniconnect.club.domain.*;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.repository.ClubRepository;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

@Service
@Transactional
public class ClubContextService {
    private final ClubRepository clubs;
    private final ClubAccountService accounts;
    private final SessionContextService sessions;
    private final ClubValidation validation;
    public ClubContextService(ClubRepository clubs, ClubAccountService accounts, SessionContextService sessions, ClubValidation validation) {
        this.clubs = clubs; this.accounts = accounts; this.sessions = sessions; this.validation = validation;
    }
    public ContextsResponse get(SessionPrincipal actor) {
        var account = accounts.lock(actor, List.of()).get(actor.userId());
        return response(actor, account);
    }
    public ContextsResponse select(SessionPrincipal actor, SelectContextRequest request) {
        validation.check(request);
        if ((request.contextType() == ContextType.CLUB) != (request.assignmentId() != null))
            throw new BadRequestException("INVALID_CONTEXT", "Only CLUB context requires an assignmentId.");
        // Resolve only the scalar ID before locking; revoke/replace also lock the club first.
        if (request.contextType() == ContextType.CLUB) {
            long club = clubs.assignmentClub(request.assignmentId()).orElseThrow(() -> new ForbiddenException("Club context is unavailable."));
            var locked = clubs.lock(club);
            if (locked == null || locked.getStatus() == ClubStatus.REMOVED) throw new ForbiddenException("Club context is unavailable.");
        }
        var account = accounts.lock(actor, List.of()).get(actor.userId());
        var options = options(account);
        boolean allowed = options.stream().anyMatch(c -> c.contextType() == request.contextType() && Objects.equals(c.assignmentId(), request.assignmentId()));
        if (!allowed) throw new ForbiddenException("Selected context is unavailable for this account.");
        sessions.select(actor, request.contextType(), request.assignmentId());
        return response(actor, account);
    }
    @Transactional(propagation = Propagation.MANDATORY)
    public void requireSystem(SessionPrincipal actor, Account account) {
        if (account.platformRole() != PlatformRole.SYSTEM_ADMIN || sessions.get(actor).type() != ContextType.SYSTEM_ADMINISTRATION)
            throw new ForbiddenException("Select SYSTEM_ADMINISTRATION using an active system administrator account.");
    }
    @Transactional(propagation = Propagation.MANDATORY)
    public ClubRoleAssignment requireAdministrator(SessionPrincipal actor, Club club, Account account) {
        var selected = sessions.get(actor);
        if (!account.eligibleStudent() || selected.type() != ContextType.CLUB)
            throw new ForbiddenException("Select this club's administrator context.");
        var assignment = clubs.assignment(selected.assignmentId());
        if (assignment == null || !assignment.isCurrent() || !assignment.getUserId().equals(actor.userId()) ||
                !assignment.getClubId().equals(club.getId()) || assignment.getRole() != ClubRole.CLUB_ADMINISTRATOR)
            throw new ForbiddenException("A current administrator assignment for this club is required.");
        return assignment;
    }
    private ContextsResponse response(SessionPrincipal actor, Account account) {
        var options = options(account);
        var selected = sessions.get(actor);
        var active = options.stream().filter(c -> c.contextType() == selected.type() && Objects.equals(c.assignmentId(), selected.assignmentId())).findFirst().orElse(null);
        if (active == null) {
            sessions.select(actor, ContextType.PERSONAL, null);
            return new ContextsResponse(personal(), sessions.get(actor).selectedAt(), options);
        }
        return new ContextsResponse(active, selected.selectedAt(), options);
    }
    private List<ContextResponse> options(Account account) {
        var options = new ArrayList<ContextResponse>(); options.add(personal());
        if (account.platformRole() == PlatformRole.SYSTEM_ADMIN)
            options.add(new ContextResponse(ContextType.SYSTEM_ADMINISTRATION, null, null, null, null));
        if (account.eligibleStudent()) for (var assignment : clubs.contexts(account.id())) {
            var club = clubs.find(assignment.getClubId());
            options.add(new ContextResponse(ContextType.CLUB, assignment.getId(), club.getId(), club.getClubName(), assignment.getRole()));
        }
        return List.copyOf(options);
    }
    private ContextResponse personal() { return new ContextResponse(ContextType.PERSONAL, null, null, null, null); }
}
