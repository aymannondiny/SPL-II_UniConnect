package com.uniconnect.project.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "teammate_project_audits")
public class ProjectAudit {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) @Column(name = "audit_id") private Long auditId;
    @Column(name = "project_id", nullable = false, updatable = false) private Long projectId;
    @Column(name = "actor_user_id", updatable = false) private Long actorUserId;
    @Column(name = "application_id", updatable = false) private Long applicationId;
    @Enumerated(EnumType.STRING) @Column(name = "event_type", nullable = false, length = 40, updatable = false)
    private ProjectAuditEvent eventType;
    @Column(name = "occurred_at", nullable = false, updatable = false) private LocalDateTime occurredAt;
    protected ProjectAudit() {}
    public ProjectAudit(long project, Long actor, Long application, ProjectAuditEvent event, LocalDateTime now) {
        projectId = project; actorUserId = actor; applicationId = application; eventType = event; occurredAt = now;
    }
    public Long getAuditId() { return auditId; }
    public Long getProjectId() { return projectId; }
    public Long getActorUserId() { return actorUserId; }
    public Long getApplicationId() { return applicationId; }
    public ProjectAuditEvent getEventType() { return eventType; }
    public LocalDateTime getOccurredAt() { return occurredAt; }
}
