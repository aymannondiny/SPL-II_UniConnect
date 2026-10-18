package com.uniconnect.administration.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import org.hibernate.annotations.Immutable;

@Entity
@Immutable
@Table(name = "audit_logs")
public class AuditLog {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long auditLogId;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "moderation_action_id", nullable = false, updatable = false)
    private ModerationAction moderationAction;
    @Column(nullable = false, updatable = false) private Long actorId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 50, updatable = false)
    private AuditEventType eventType;
    @Column(nullable = false, length = 30, updatable = false) private String subjectType;
    @Column(nullable = false, updatable = false) private Long subjectId;
    @Column(nullable = false, length = 1000, updatable = false) private String reason;
    @Column(nullable = false, length = 1000, updatable = false) private String previousStateJson;
    @Column(nullable = false, length = 1000, updatable = false) private String newStateJson;
    @Column(nullable = false, updatable = false) private LocalDateTime occurredAt;

    protected AuditLog() {}

    public AuditLog(ModerationAction action, AuditEventType eventType, String previousStateJson,
            String newStateJson, LocalDateTime occurredAt) {
        this.moderationAction = action;
        this.actorId = action.getActorId();
        this.eventType = eventType;
        this.subjectType = "USER";
        this.subjectId = action.getTargetUserId();
        this.reason = action.getReason();
        this.previousStateJson = previousStateJson;
        this.newStateJson = newStateJson;
        this.occurredAt = occurredAt;
    }

    public Long getId() { return auditLogId; }
    public ModerationAction getModerationAction() { return moderationAction; }
    public Long getActorId() { return actorId; }
    public AuditEventType getEventType() { return eventType; }
    public Long getSubjectId() { return subjectId; }
    public String getReason() { return reason; }
    public String getPreviousStateJson() { return previousStateJson; }
    public String getNewStateJson() { return newStateJson; }
    public LocalDateTime getOccurredAt() { return occurredAt; }
}
