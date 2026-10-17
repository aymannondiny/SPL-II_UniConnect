package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.AuthenticatedSession;
import com.uniconnect.authentication.repository.AuthenticatedSessionRepository;
import com.uniconnect.shared.security.*;
import jakarta.persistence.EntityManager;
import java.time.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Callers lock the owning account and validate club authority before selecting context. */
@Service
@Transactional(propagation = Propagation.MANDATORY)
public class SessionContextService {
    public record Selection(ContextType type, Long assignmentId, LocalDateTime selectedAt) {}
    private final AuthenticatedSessionRepository sessions;
    private final SessionService access;
    private final EntityManager em;
    private final Clock clock;
    public SessionContextService(AuthenticatedSessionRepository sessions, SessionService access, EntityManager em, Clock clock) {
        this.sessions = sessions; this.access = access; this.em = em; this.clock = clock;
    }
    public Selection get(SessionPrincipal actor) {
        var session = current(actor);
        return new Selection(session.getContextType(), session.getContextAssignmentId(), session.getContextSelectedAt());
    }
    public void select(SessionPrincipal actor, ContextType type, Long assignment) { current(actor).selectContext(type, assignment, now()); }
    public void revokeAssignment(long assignment) {
        // Target account is locked by the caller, serializing every session mutation for it.
        em.createQuery("update AuthenticatedSession s set s.contextType=:personal, s.contextAssignmentId=null, s.contextSelectedAt=:now where s.contextAssignmentId=:assignment")
                .setParameter("personal", ContextType.PERSONAL).setParameter("now", now()).setParameter("assignment", assignment).executeUpdate();
    }
    private AuthenticatedSession current(SessionPrincipal actor) {
        if (actor == null) throw new InvalidSessionException();
        access.requireCurrentSession(actor);
        return sessions.findById(actor.sessionId()).orElseThrow(InvalidSessionException::new);
    }
    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }
}
