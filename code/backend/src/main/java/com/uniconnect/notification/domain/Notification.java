package com.uniconnect.notification.domain;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
public class Notification {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long notificationId;
    @Column(nullable = false) private Long recipientId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 50) private NotificationType type;
    @Column(nullable = false, length = 150) private String title;
    @Column(nullable = false, length = 1000) private String message;
    @Column(nullable = false, length = 50) private String referenceType;
    @Column(nullable = false) private Long referenceId;
    @Column(nullable = false, length = 150) private String eventKey;
    @Column(nullable = false) private LocalDateTime createdAt;
    private LocalDateTime readAt;
    private LocalDateTime dismissedAt;
    protected Notification() {}
    public Notification(long recipient, long connection, NotificationType type, LocalDateTime now) {
        recipientId = recipient;
        referenceId = connection;
        referenceType = "CONNECTION";
        this.type = type;
        eventKey = "connection:" + connection + ":" + type.name();
        title = type == NotificationType.CONNECTION_REQUESTED ? "New connection request" : "Connection accepted";
        message = type == NotificationType.CONNECTION_REQUESTED ? "You received a connection request." : "Your connection request was accepted.";
        createdAt = now;
    }
    public void markRead(LocalDateTime now) { if (readAt == null) readAt = now; }
    public Long getId() { return notificationId; }
    public NotificationType getType() { return type; }
    public String getTitle() { return title; }
    public String getMessage() { return message; }
    public String getReferenceType() { return referenceType; }
    public Long getReferenceId() { return referenceId; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getReadAt() { return readAt; }
}
