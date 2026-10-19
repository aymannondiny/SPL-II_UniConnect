package com.uniconnect.reporting.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import org.hibernate.annotations.Immutable;

@Entity @Immutable
@Table(name = "report_audit_logs")
public class ReportAuditLog {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long auditId;
    @Column(nullable = false, updatable = false) private Long reportId;
    @Column(nullable = false, updatable = false) private Long actorId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30, updatable = false) private ReportAuditEventType eventType;
    @Enumerated(EnumType.STRING) @Column(length = 30, updatable = false) private ReportStatus previousStatus;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30, updatable = false) private ReportStatus newStatus;
    @Column(length = 2000, updatable = false) private String internalNote;
    @Column(nullable = false, updatable = false) private LocalDateTime occurredAt;
    protected ReportAuditLog() {}
    public ReportAuditLog(long reportId, long actorId, ReportAuditEventType eventType,
            ReportStatus previousStatus, ReportStatus newStatus, String internalNote, LocalDateTime occurredAt) {
        this.reportId=reportId; this.actorId=actorId; this.eventType=eventType;
        this.previousStatus=previousStatus; this.newStatus=newStatus; this.internalNote=internalNote; this.occurredAt=occurredAt;
    }
    public Long getId(){return auditId;} public Long getActorId(){return actorId;}
    public ReportAuditEventType getEventType(){return eventType;} public ReportStatus getPreviousStatus(){return previousStatus;}
    public ReportStatus getNewStatus(){return newStatus;} public String getInternalNote(){return internalNote;}
    public LocalDateTime getOccurredAt(){return occurredAt;}
}
