package com.uniconnect.club.publication.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import org.hibernate.annotations.Immutable;

@Entity
@Immutable
@Table(name = "club_publication_audit")
public class PublicationAudit {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long auditId;
    @Column(nullable = false, updatable = false) private Long clubId;
    private Long announcementId;
    private Long eventId;
    @Column(nullable = false, updatable = false) private Long actorUserId;
    @Column(nullable = false, updatable = false) private Long actorAssignmentId;
    @Column(nullable = false, updatable = false, length = 20) private String action;
    @Column(length = 1000, updatable = false) private String reason;
    @Column(columnDefinition = "text", updatable = false) private String beforeSnapshot;
    @Column(nullable = false, columnDefinition = "text", updatable = false) private String afterSnapshot;
    @Column(nullable = false, updatable = false) private LocalDateTime createdAt;
    protected PublicationAudit() {}
    public PublicationAudit(long club, Long announcement, Long event, long actor, long assignment, String action,
            String reason, String before, String after, LocalDateTime now) {
        clubId = club; announcementId = announcement; eventId = event; actorUserId = actor; actorAssignmentId = assignment;
        this.action = action; this.reason = reason; beforeSnapshot = before; afterSnapshot = after; createdAt = now;
    }
    public Long getId() { return auditId; }
    public Long getAnnouncementId() { return announcementId; }
    public Long getEventId() { return eventId; }
    public Long getActorUserId() { return actorUserId; }
    public Long getActorAssignmentId() { return actorAssignmentId; }
    public String getAction() { return action; }
    public String getReason() { return reason; }
    public String getBeforeSnapshot() { return beforeSnapshot; }
    public String getAfterSnapshot() { return afterSnapshot; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
