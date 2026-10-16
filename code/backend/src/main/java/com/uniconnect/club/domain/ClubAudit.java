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
    @Column(updatable = false) private Long targetAssignmentId;
    @Enumerated(EnumType.STRING) @Column(length = 30, updatable = false) private ClubStatus previousState;
    @Enumerated(EnumType.STRING) @Column(length = 30, updatable = false) private ClubStatus newState;
    @Column(nullable = false, length = 50, updatable = false) private String action;
    @Column(nullable = false, length = 1000, updatable = false) private String reason;
    @Column(nullable = false, updatable = false) private LocalDateTime createdAt;
    protected ClubAudit() {}
    public ClubAudit(long club, long actor, Long actingAssignment, long target, String action, String reason, LocalDateTime now) {
        clubId = club; actorId = actor; actorAssignmentId = actingAssignment; targetAssignmentId = target;
        this.action = action; this.reason = reason; createdAt = now;
    }
    public static ClubAudit lifecycle(long club, long actor, String action, String reason,
            ClubStatus before, ClubStatus after, LocalDateTime now) {
        var audit = new ClubAudit();
        audit.clubId = club; audit.actorId = actor; audit.action = action; audit.reason = reason;
        audit.previousState = before; audit.newState = after; audit.createdAt = now;
        return audit;
    }
    public ClubStatus getPreviousState() { return previousState; }
    public ClubStatus getNewState() { return newState; }
    public Long getId() { return auditId; }
    public Long getClubId() { return clubId; }
    public Long getActorId() { return actorId; }
    public Long getActorAssignmentId() { return actorAssignmentId; }
    public Long getTargetAssignmentId() { return targetAssignmentId; }
    public String getAction() { return action; }
    public String getReason() { return reason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
