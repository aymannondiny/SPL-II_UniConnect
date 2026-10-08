package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.security.SessionPrincipal;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Account boundary for profile operations. Never trust a role supplied by a client. */
@Service
public class ProfileAccountService {
    private final UserRepository users;
    private final SessionService sessions;
    public ProfileAccountService(UserRepository users, SessionService sessions) {
        this.users = users;
        this.sessions = sessions;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public User lockActiveAccount(SessionPrincipal principal) {
        if (principal == null) throw new InvalidSessionException();
        User user = users.findForUpdateById(principal.userId()).orElseThrow(InvalidSessionException::new);
        sessions.requireCurrentSession(principal);
        return user;
    }
}
