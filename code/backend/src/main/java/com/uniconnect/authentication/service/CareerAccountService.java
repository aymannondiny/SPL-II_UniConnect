package com.uniconnect.authentication.service;

import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.security.PlatformRole;
import com.uniconnect.shared.security.SessionPrincipal;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Authentication-owned account boundary for the Career Board. */
@Service
@Transactional(propagation = Propagation.MANDATORY)
public class CareerAccountService {
    public record Actor(long userId, PlatformRole role, String displayName) {}
    public record Author(long userId, String displayName, boolean anonymized) {}

    private final UserRepository users;
    private final SessionService sessions;

    public CareerAccountService(UserRepository users, SessionService sessions) {
        this.users = users;
        this.sessions = sessions;
    }

    public Actor lockActive(SessionPrincipal principal) {
        if (principal == null) throw new InvalidSessionException();
        var user = users.findForUpdateById(principal.userId()).orElseThrow(InvalidSessionException::new);
        sessions.requireCurrentSession(principal);
        if (!user.canPerformProtectedAction()) throw new InvalidSessionException();
        return new Actor(user.getUserId(), user.getPlatformRole(), user.getFullName());
    }

    @Transactional(readOnly = true)
    public Map<Long, Author> authors(Collection<Long> ids) {
        var result = new LinkedHashMap<Long, Author>();
        users.findAllById(ids).forEach(user -> result.put(user.getUserId(), new Author(
                user.getUserId(), user.isAnonymized() ? "Former User" : user.getFullName(), user.isAnonymized())));
        return result;
    }
}
