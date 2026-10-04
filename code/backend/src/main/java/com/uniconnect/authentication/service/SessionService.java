package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.AuthenticatedSession;
import com.uniconnect.authentication.dto.*;
import com.uniconnect.authentication.repository.*;
import com.uniconnect.shared.security.SessionPrincipal;
import java.time.*;
import java.util.Locale;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

@Service
public class SessionService {
    private static final Duration ACCESS_LIFETIME = Duration.ofMinutes(15);
    private static final Duration SESSION_LIFETIME = Duration.ofDays(7);
    private final UserRepository users;
    private final AuthenticatedSessionRepository sessions;
    private final PasswordEncoder passwords;
    private final SessionTokenGenerator tokens;
    private final Clock clock;
    private final String dummyPasswordHash;

    public SessionService(UserRepository users, AuthenticatedSessionRepository sessions,
            PasswordEncoder passwords, SessionTokenGenerator tokens, Clock clock) {
        this.users = users;
        this.sessions = sessions;
        this.passwords = passwords;
        this.tokens = tokens;
        this.clock = clock;
        this.dummyPasswordHash = passwords.encode(tokens.generate());
    }

    @Transactional
    public SessionResponse login(LoginRequest request) {
        var user = users.findForUpdateByEmail(request.email().strip().toLowerCase(Locale.ROOT));
        String hash = user.map(u -> u.getPasswordHash()).orElse(dummyPasswordHash);
        boolean oversized = request.password().getBytes(java.nio.charset.StandardCharsets.UTF_8).length > 72;
        boolean matches = passwords.matches(oversized ? "invalid-oversized-password" : request.password(), hash);
        matches = matches && !oversized;
        if (user.isEmpty() || !matches || !user.get().canAuthenticate()) {
            throw new InvalidCredentialsException();
        }
        LocalDateTime now = now();
        String access = tokens.generate();
        String refresh = tokens.generate();
        var session = new AuthenticatedSession(user.get(), tokens.hash(access), tokens.hash(refresh),
                now, now.plus(SESSION_LIFETIME), now.plus(ACCESS_LIFETIME));
        sessions.save(session);
        return response(session, access, refresh);
    }

    @Transactional
    public SessionResponse refresh(String rawToken) {
        if (!tokens.isWellFormed(rawToken)) throw new InvalidSessionException();
        String hash = tokens.hash(rawToken);
        Long owner = sessions.findOwnerByRefreshHash(hash).orElseThrow(InvalidSessionException::new);
        // All session mutations lock the owner first. Load token state only after acquiring the lock.
        users.findForUpdateById(owner).orElseThrow(InvalidSessionException::new);
        var session = sessions.findByRefreshHash(hash).orElseThrow(InvalidSessionException::new);
        LocalDateTime now = now();
        if (!session.isValid(now)) throw new InvalidSessionException();
        String access = tokens.generate();
        String refresh = tokens.generate();
        session.rotate(tokens.hash(access), tokens.hash(refresh), now, now.plus(ACCESS_LIFETIME));
        return response(session, access, refresh);
    }

    @Transactional(readOnly = true)
    public SessionPrincipal authenticate(String rawToken) {
        if (!tokens.isWellFormed(rawToken)) throw new InvalidSessionException();
        var session = sessions.findByAccessHash(tokens.hash(rawToken)).orElseThrow(InvalidSessionException::new);
        if (!session.allowsAccess(now())) throw new InvalidSessionException();
        return new SessionPrincipal(session.getSessionId(), session.getUser().getUserId(),
                session.getUser().getPlatformRole());
    }

    @Transactional
    public void logout(SessionPrincipal principal) {
        users.findForUpdateById(principal.userId()).orElseThrow(InvalidSessionException::new);
        var session = sessions.findById(principal.sessionId()).orElseThrow(InvalidSessionException::new);
        if (!session.getUser().getUserId().equals(principal.userId())) throw new InvalidSessionException();
        session.revoke(now(), "LOGOUT");
    }

    @Transactional(readOnly = true)
    public CurrentUserResponse currentUser(SessionPrincipal principal) {
        var user = users.findById(principal.userId()).orElseThrow(InvalidSessionException::new);
        if (!user.canAuthenticate()) throw new InvalidSessionException();
        return new CurrentUserResponse(user.getUserId(), user.getFullName(), user.getEmail(),
                user.getPlatformRole(), user.getAccountStatus());
    }

    /** Join the owning account-state transaction; callers must never expose this as a public endpoint. */
    @Transactional(propagation = Propagation.MANDATORY)
    public void revokeAllForAccount(Long userId) {
        users.findForUpdateById(userId).orElseThrow(InvalidSessionException::new);
        sessions.revokeAll(userId, now(), "ACCOUNT_CHANGE");
    }

    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }

    private SessionResponse response(AuthenticatedSession session, String access, String refresh) {
        return new SessionResponse(session.getSessionId(), "Bearer", access, refresh,
                session.getAccessExpiresAt().toInstant(ZoneOffset.UTC),
                session.getExpiresAt().toInstant(ZoneOffset.UTC));
    }
}
