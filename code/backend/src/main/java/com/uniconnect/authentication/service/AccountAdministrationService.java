package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import java.time.LocalDateTime;
import java.util.*;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Authentication-owned account access for the administration module. */
@Service
public class AccountAdministrationService {
    public record Account(long id, String fullName, String email, PlatformRole role,
            AccountStatus status, boolean anonymized, LocalDateTime createdAt, LocalDateTime updatedAt) {}

    private final UserRepository users;
    private final SessionService sessions;
    private final SessionContextService contexts;

    public AccountAdministrationService(UserRepository users, SessionService sessions,
            SessionContextService contexts) {
        this.users = users;
        this.sessions = sessions;
        this.contexts = contexts;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public Account lockTarget(SessionPrincipal actor, long targetId) {
        if (actor == null) throw new InvalidSessionException();
        var ids = new TreeSet<Long>(List.of(actor.userId(), targetId));
        var locked = new HashMap<Long, User>();
        for (long id : ids) {
            var user = users.findForUpdateById(id).orElseThrow(() -> new ResourceNotFoundException("Account", id));
            locked.put(id, user);
        }
        requireSystemAdministration(actor, locked.get(actor.userId()));
        return snapshot(locked.get(targetId));
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void requireAdministration(SessionPrincipal actor) {
        if (actor == null) throw new InvalidSessionException();
        var user = users.findForUpdateById(actor.userId()).orElseThrow(InvalidSessionException::new);
        requireSystemAdministration(actor, user);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public Page<Account> search(String term, PlatformRole role, AccountStatus status, Pageable page) {
        return users.searchForAdministration(term, role, status, page).map(this::snapshot);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void suspendLocked(long targetId, LocalDateTime now) {
        users.findById(targetId).orElseThrow(() -> new ResourceNotFoundException("Account", targetId)).suspend(now);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void restoreLocked(long targetId, LocalDateTime now) {
        users.findById(targetId).orElseThrow(() -> new ResourceNotFoundException("Account", targetId)).restore(now);
    }

    private void requireSystemAdministration(SessionPrincipal actor, User user) {
        sessions.requireCurrentSession(actor);
        if (!user.canPerformProtectedAction() || user.getPlatformRole() != PlatformRole.SYSTEM_ADMIN
                || contexts.get(actor).type() != ContextType.SYSTEM_ADMINISTRATION) {
            throw new ForbiddenException("Select SYSTEM_ADMINISTRATION using an active system administrator account.");
        }
    }

    private Account snapshot(User user) {
        return new Account(user.getUserId(), user.isAnonymized() ? "Former User" : user.getFullName(),
                user.isAnonymized() ? null : user.getEmail(), user.getPlatformRole(), user.getAccountStatus(),
                user.isAnonymized(), user.getCreatedAt(), user.getUpdatedAt());
    }
}
