package com.uniconnect.club.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import org.hibernate.annotations.Immutable;

@Entity @Immutable
@Table(name = "club_audit")
public class ClubAudit {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long auditId;
    @Column(nullable = false, updatable = false) private Long clubId;
    @Column(nullable = false, updatable = false) private Long actorId;
    @Column(updatable = false) private Long actorAssignmentId;
    @Column(nullable = false, updatable = false) private Long targetAssignmentId;
    @Column(nullable = false, length = 50, updatable = false) private String action;
    @Column(nullable = false, length = 1000, updatable = false) private String reason;
    @Column(nullable = false, updatable = false) private LocalDateTime createdAt;
    protected ClubAudit() {}
    public ClubAudit(long club, long actor, Long actingAssignment, long target, String action, String reason, LocalDateTime now) {
        clubId = club; actorId = actor; actorAssignmentId = actingAssignment; targetAssignmentId = target;
        this.action = action; this.reason = reason; createdAt = now;
    }
    public Long getId() { return auditId; }
    public Long getClubId() { return clubId; }
    public Long getActorId() { return actorId; }
    public Long getActorAssignmentId() { return actorAssignmentId; }
    public Long getTargetAssignmentId() { return targetAssignmentId; }
    public String getAction() { return action; }
    public String getReason() { return reason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
