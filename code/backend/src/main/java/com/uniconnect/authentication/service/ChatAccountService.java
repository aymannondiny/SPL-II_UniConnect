package com.uniconnect.authentication.service;

import com.uniconnect.authentication.repository.AuthenticatedSessionRepository;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.security.SessionPrincipal;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

@Service
public class ChatAccountService {
    private final UserRepository users;
    private final SessionService sessions;
    private final AuthenticatedSessionRepository sessionRecords;
    private final AuthenticationTokenGenerator tokens;
    private final Clock clock;
    public ChatAccountService(UserRepository users,SessionService sessions,AuthenticatedSessionRepository sessionRecords,
            AuthenticationTokenGenerator tokens,Clock clock) {
        this.users=users; this.sessions=sessions; this.sessionRecords=sessionRecords; this.tokens=tokens; this.clock=clock;
    }
    public record Summary(String name,boolean active) {}
    /** Stores only a hash, so token rotation also invalidates an established socket. */
    public record SocketIdentity(SessionPrincipal actor,String accessHash) {}
    @Transactional(propagation=Propagation.MANDATORY,readOnly=true)
    public Summary summary(long userId) {
        return users.findById(userId).map(u -> new Summary(u.isAnonymized() ? "Former User" : u.getFullName(),u.canPerformProtectedAction()))
                .orElse(new Summary("Former User",false));
    }
    @Transactional(propagation=Propagation.MANDATORY,readOnly=true)
    public Map<Long,Summary> summaries(Collection<Long> userIds) {
        Map<Long,Summary> result=new HashMap<>();
        if(userIds.isEmpty()) return result;
        for(var user:users.findAllById(userIds))
            result.put(user.getUserId(),new Summary(user.isAnonymized()?"Former User":user.getFullName(),user.canPerformProtectedAction()));
        for(var userId:userIds) result.putIfAbsent(userId,new Summary("Former User",false));
        return result;
    }
    @Transactional(readOnly=true)
    public SocketIdentity authenticateSocket(String token) {
        return new SocketIdentity(sessions.authenticate(token),tokens.hash(token));
    }
    @Transactional(readOnly=true)
    public void validateLiveSession(SocketIdentity identity) {
        if(identity==null) throw new InvalidSessionException();
        var session=sessionRecords.findByAccessHash(identity.accessHash()).orElseThrow(InvalidSessionException::new);
        if(!session.getSessionId().equals(identity.actor().sessionId()) ||
                !session.getUser().getUserId().equals(identity.actor().userId()) ||
                !session.allowsAccess(LocalDateTime.ofInstant(clock.instant(),ZoneOffset.UTC))) throw new InvalidSessionException();
    }
}
