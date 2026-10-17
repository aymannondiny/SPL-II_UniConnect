package com.uniconnect.authentication.service;

import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.ResourceNotFoundException;
import com.uniconnect.shared.security.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Club code receives account summaries, never another module's repository or entity. */
@Service
@Transactional(propagation = Propagation.MANDATORY)
public class ClubAccountService {
    public record Account(long id, String fullName, PlatformRole platformRole, boolean active) {
        public boolean eligibleStudent() { return active && platformRole == PlatformRole.STUDENT; }
    }
    private final UserRepository users;
    private final SessionService sessions;
    public ClubAccountService(UserRepository users, SessionService sessions) { this.users = users; this.sessions = sessions; }
    /** Existing club first, then every involved account in ascending order, then session. */
    public Map<Long, Account> lock(SessionPrincipal actor, Collection<Long> involved) {
        if (actor == null) throw new InvalidSessionException();
        var ids = new TreeSet<Long>(involved); ids.add(actor.userId());
        var result = new HashMap<Long, Account>();
        for (long id : ids) {
            var user = users.findForUpdateById(id).orElseThrow(() -> new ResourceNotFoundException("Member", id));
            result.put(id, new Account(id, user.isAnonymized() ? "Former User" : user.getFullName(), user.getPlatformRole(), user.canPerformProtectedAction()));
        }
        sessions.requireCurrentSession(actor);
        return result;
    }
    public String displayName(long id) {
        return users.findById(id).map(u -> u.isAnonymized() ? "Former User" : u.getFullName()).orElse("Former User");
    }
}
