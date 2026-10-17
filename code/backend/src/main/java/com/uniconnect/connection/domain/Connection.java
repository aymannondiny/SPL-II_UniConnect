package com.uniconnect.connection.domain;

import com.uniconnect.shared.exception.ConflictException;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "connections")
public class Connection {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long connectionId;
    @Column(nullable = false, updatable = false) private Long requesterId;
    @Column(nullable = false, updatable = false) private Long receiverId;
    @Column(nullable = false, updatable = false) private Long userLow;
    @Column(nullable = false, updatable = false) private Long userHigh;
    private Long openLow;
    private Long openHigh;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20)
    private ConnectionStatus status;
    @Column(length = 1000) private String introductoryMessage;
    @Column(nullable = false) private LocalDateTime requestedAt;
    private LocalDateTime acceptedAt;
    private LocalDateTime closedAt;
    protected Connection() {}
    public Connection(long requester, long receiver, String introduction, LocalDateTime now) {
        requesterId = requester;
        receiverId = receiver;
        userLow = Math.min(requester, receiver);
        userHigh = Math.max(requester, receiver);
        openLow = userLow;
        openHigh = userHigh;
        status = ConnectionStatus.PENDING;
        introductoryMessage = introduction;
        requestedAt = now;
    }
    public void accept(LocalDateTime now) {
        requireStatus(ConnectionStatus.PENDING);
        status = ConnectionStatus.ACCEPTED;
        acceptedAt = now;
    }
    public void close(ConnectionStatus next, LocalDateTime now) {
        if (next != ConnectionStatus.REJECTED && next != ConnectionStatus.CANCELLED && next != ConnectionStatus.REMOVED)
            throw new IllegalArgumentException("Not a closing transition");
        requireStatus(next == ConnectionStatus.REMOVED ? ConnectionStatus.ACCEPTED : ConnectionStatus.PENDING);
        status = next;
        closedAt = now;
        openLow = null;
        openHigh = null;
    }
    private void requireStatus(ConnectionStatus expected) {
        if (status != expected) throw new ConflictException("INVALID_CONNECTION_STATE", "Connection is not " + expected + ".");
    }
    public Long getId() { return connectionId; }
    public Long getRequesterId() { return requesterId; }
    public Long getReceiverId() { return receiverId; }
    public ConnectionStatus getStatus() { return status; }
    public String getIntroductoryMessage() { return introductoryMessage; }
    public LocalDateTime getRequestedAt() { return requestedAt; }
    public LocalDateTime getAcceptedAt() { return acceptedAt; }
    public LocalDateTime getClosedAt() { return closedAt; }
}
