package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

@Service
public class MemberAccountService {
    private final UserRepository users;
    private final SessionService sessions;
    public MemberAccountService(UserRepository users, SessionService sessions) {
        this.users = users;
        this.sessions = sessions;
    }

    /** Lock accounts in ID order, before loading connection state. */
    @Transactional(propagation = Propagation.MANDATORY)
    public void lockPair(SessionPrincipal actor, long otherId, boolean requireEligiblePeer) {
        if (actor == null) throw new InvalidSessionException();
        if (otherId <= 0 || actor.userId() == otherId)
            throw new BadRequestException("INVALID_CONNECTION_TARGET", "Select another member.");
        long low = Math.min(actor.userId(), otherId);
        long high = Math.max(actor.userId(), otherId);
        User first = users.findForUpdateById(low).orElseThrow(() -> missing(low));
        User second = users.findForUpdateById(high).orElseThrow(() -> missing(high));
        sessions.requireCurrentSession(actor);
        User peer = first.getUserId().equals(actor.userId()) ? second : first;
        if (requireEligiblePeer && !peer.canPerformProtectedAction()) throw missing(otherId);
    }

    private ResourceNotFoundException missing(long id) {
        return new ResourceNotFoundException("Member", id);
    }
}
