package com.uniconnect.connection.service;

import com.uniconnect.authentication.service.*;
import com.uniconnect.connection.domain.*;
import com.uniconnect.connection.dto.*;
import com.uniconnect.connection.repository.ConnectionRepository;
import com.uniconnect.notification.service.ConnectionNotificationService;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import jakarta.validation.Validator;
import java.time.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ConnectionService {
    private final ConnectionRepository connections;
    private final MemberAccountService accounts;
    private final ConnectionNotificationService notifications;
    private final Validator validator;
    private final Clock clock;
    public ConnectionService(ConnectionRepository connections, MemberAccountService accounts,
            ConnectionNotificationService notifications, Validator validator, Clock clock) {
        this.connections = connections;
        this.accounts = accounts;
        this.notifications = notifications;
        this.validator = validator;
        this.clock = clock;
    }
    public ConnectionResponse send(SessionPrincipal actor, ConnectionRequest request) {
        if (request == null || !validator.validate(request).isEmpty())
            throw new BadRequestException("INVALID_CONNECTION_REQUEST", "Invalid connection request.");
        accounts.lockPair(actor, request.receiverId(), true);
        long low = Math.min(actor.userId(), request.receiverId());
        long high = Math.max(actor.userId(), request.receiverId());
        if (connections.findByOpenLowAndOpenHigh(low, high).isPresent())
            throw new ConflictException("CONNECTION_ALREADY_OPEN", "A pending request or accepted connection already exists.");
        String introduction = request.introductoryMessage();
        introduction = introduction == null || introduction.isBlank() ? null : introduction.strip();
        var connection = connections.saveAndFlush(new Connection(actor.userId(), request.receiverId(), introduction, now()));
        notifications.requested(connection.getReceiverId(), connection.getId());
        return ConnectionResponse.from(connection);
    }
    public ConnectionResponse accept(SessionPrincipal actor, long id) {
        Connection c = locked(actor, id, true);
        requireReceiver(actor, c);
        c.accept(now());
        notifications.accepted(c.getRequesterId(), c.getId());
        return ConnectionResponse.from(c);
    }
    public ConnectionResponse reject(SessionPrincipal actor, long id) {
        Connection c = locked(actor, id, false);
        requireReceiver(actor, c);
        c.close(ConnectionStatus.REJECTED, now());
        return ConnectionResponse.from(c);
    }
    public ConnectionResponse cancel(SessionPrincipal actor, long id) {
        Connection c = locked(actor, id, false);
        if (!c.getRequesterId().equals(actor.userId())) throw new ForbiddenException("Only the requester may cancel.");
        c.close(ConnectionStatus.CANCELLED, now());
        return ConnectionResponse.from(c);
    }
    public ConnectionResponse remove(SessionPrincipal actor, long id) {
        Connection c = locked(actor, id, false);
        c.close(ConnectionStatus.REMOVED, now());
        return ConnectionResponse.from(c);
    }
    public ConnectionResponse get(SessionPrincipal actor, long id) {
        return ConnectionResponse.from(locked(actor, id, false));
    }
    private Connection locked(SessionPrincipal actor, long id, boolean eligiblePeer) {
        if (actor == null) throw new InvalidSessionException();
        // Projection avoids caching stale entity state before waiting for the account locks.
        var pair = connections.participants(id).orElseThrow(() -> missing(id));
        if (!pair.getRequesterId().equals(actor.userId()) && !pair.getReceiverId().equals(actor.userId())) throw missing(id);
        long other = pair.getRequesterId().equals(actor.userId()) ? pair.getReceiverId() : pair.getRequesterId();
        accounts.lockPair(actor, other, eligiblePeer);
        return connections.findById(id).orElseThrow(() -> missing(id));
    }
    private void requireReceiver(SessionPrincipal actor, Connection c) {
        if (!c.getReceiverId().equals(actor.userId())) throw new ForbiddenException("Only the receiver may accept or reject.");
    }
    private ResourceNotFoundException missing(long id) { return new ResourceNotFoundException("Connection", id); }
    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }
}
