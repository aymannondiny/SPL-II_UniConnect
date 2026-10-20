package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.ResourceNotFoundException;
import com.uniconnect.shared.security.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Authentication-owned account boundary for Project Teammate Finder. */
@Service
@Transactional(propagation = Propagation.MANDATORY)
public class ProjectAccountService {
    public record Account(long id, String displayName, PlatformRole role, boolean active) {
        public boolean eligibleStudent() { return active && role == PlatformRole.STUDENT; }
    }
    private final UserRepository users;
    private final SessionService sessions;
    public ProjectAccountService(UserRepository users, SessionService sessions) {
        this.users = users; this.sessions = sessions;
    }

    /** Account rows are always locked in ascending ID order before project-owned rows. */
    public Map<Long, Account> lock(SessionPrincipal principal, Collection<Long> involved) {
        if (principal == null) throw new InvalidSessionException();
        var ids = new TreeSet<Long>(involved); ids.add(principal.userId());
        var result = new LinkedHashMap<Long, Account>();
        for (long id : ids) {
            User user = users.findForUpdateById(id)
                    .orElseThrow(() -> new ResourceNotFoundException("Account", id));
            result.put(id, snapshot(user));
        }
        sessions.requireCurrentSession(principal);
        return result;
    }

    @Transactional(readOnly = true)
    public Map<Long, String> displayNames(Collection<Long> ids) {
        var result = new LinkedHashMap<Long, String>();
        users.findAllById(ids).forEach(user -> result.put(user.getUserId(),
                user.isAnonymized() ? "Former User" : user.getFullName()));
        return result;
    }

    @Transactional(readOnly = true)
    public Map<Long, Account> summaries(Collection<Long> ids) {
        var result = new LinkedHashMap<Long, Account>();
        users.findAllById(ids).forEach(user -> result.put(user.getUserId(), snapshot(user)));
        return result;
    }

    private Account snapshot(User user) {
        return new Account(user.getUserId(), user.isAnonymized() ? "Former User" : user.getFullName(),
                user.getPlatformRole(), user.canPerformProtectedAction());
    }
}
