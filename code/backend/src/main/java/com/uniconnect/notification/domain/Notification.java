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
    public static Notification clubRole(long recipient, long club, long assignment, String role, boolean granted, LocalDateTime now) {
        var n = new Notification();
        n.recipientId = recipient; n.referenceId = club; n.referenceType = "CLUB";
        n.type = granted ? NotificationType.CLUB_ROLE_GRANTED : NotificationType.CLUB_ROLE_REVOKED;
        n.eventKey = "club-assignment:" + assignment + ":" + n.type.name();
        n.title = granted ? "Club access granted" : "Club access revoked";
        n.message = role + " access " + (granted ? "granted" : "revoked") + " for club " + club + ".";
        n.createdAt = now;
        return n;
    }
    public static Notification accountStatus(long recipient, long actionId, boolean restored, LocalDateTime now) {
        var n = new Notification();
        n.recipientId = recipient; n.referenceId = recipient; n.referenceType = "USER";
        n.type = restored ? NotificationType.ACCOUNT_REACTIVATED : NotificationType.ACCOUNT_SUSPENDED;
        n.eventKey = "account-moderation:" + actionId;
        n.title = restored ? "Account reactivated" : "Account suspended";
        n.message = restored ? "Your account has been reactivated." : "Your account has been suspended.";
        n.createdAt = now;
        return n;
    }
    public static Notification clubPublishing(long recipient, long club, long auditId, boolean restored, LocalDateTime now) {
        var n = new Notification();
        n.recipientId = recipient; n.referenceId = club; n.referenceType = "CLUB";
        n.type = restored ? NotificationType.PUBLISHING_RESTORED : NotificationType.PUBLISHING_SUSPENDED;
        n.eventKey = "club-lifecycle:" + auditId;
        n.title = restored ? "Club publishing restored" : "Club publishing suspended";
        n.message = "Publishing " + (restored ? "restored" : "suspended") + " for club " + club + ".";
        n.createdAt = now;
        return n;
    }
    public static Notification newMessage(long recipient, long conversation, long messageId, String senderName, LocalDateTime now) {
        var n = new Notification();
        n.recipientId = recipient;
        n.referenceId = conversation;
        n.referenceType = "CONVERSATION";
        n.type = NotificationType.NEW_MESSAGE;
        String name = senderName == null || senderName.isBlank() ? "A connection" : senderName.trim();
        if (name.length() > 125) name = name.substring(0, 125);
        n.title = "New message from " + name;
        n.message = "Sent you a message.";
        n.eventKey = "chat-message:" + messageId;
        n.createdAt = now;
        return n;
    }
    public static Notification reportResolved(long recipient,long reportId,boolean actionTaken,LocalDateTime now){
        var n=new Notification();n.recipientId=recipient;n.referenceId=reportId;n.referenceType="REPORT";
        n.type=NotificationType.REPORT_RESOLVED;n.eventKey="report-resolution:"+reportId;n.title="Report resolved";
        n.message=actionTaken?"Your report was reviewed and action was taken.":"Your report was reviewed and no action was taken.";
        n.createdAt=now;return n;
    }
    public static Notification projectApplication(long recipient, long projectId, long applicationId,
            boolean accepted, LocalDateTime now) {
        var n = new Notification(); n.recipientId = recipient; n.referenceId = projectId; n.referenceType = "PROJECT";
        n.type = accepted ? NotificationType.PROJECT_APPLICATION_ACCEPTED : NotificationType.PROJECT_APPLICATION_REJECTED;
        n.eventKey = "project-application:" + applicationId + ":" + n.type.name();
        n.title = accepted ? "Project application accepted" : "Project application rejected";
        n.message = accepted ? "Your project application was accepted." : "Your project application was rejected.";
        n.createdAt = now; return n;
    }
    public static Notification projectDeleted(long recipient, long projectId, long applicationId, LocalDateTime now) {
        var n = new Notification(); n.recipientId = recipient; n.referenceId = projectId; n.referenceType = "PROJECT";
        n.type = NotificationType.PROJECT_DELETED; n.eventKey = "project-deleted:" + applicationId;
        n.title = "Project deleted"; n.message = "A project you applied to was deleted."; n.createdAt = now;
        return n;
    }
    public void markRead(LocalDateTime now) { if (readAt == null) readAt = now; }
    public void dismiss(LocalDateTime now) { if (dismissedAt == null) dismissedAt = now; }
    public Long getId() { return notificationId; }
    public NotificationType getType() { return type; }
    public String getTitle() { return title; }
    public String getMessage() { return message; }
    public String getReferenceType() { return referenceType; }
    public Long getReferenceId() { return referenceId; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getReadAt() { return readAt; }
}
