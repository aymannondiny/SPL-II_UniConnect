package com.uniconnect.club.publication.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "club_announcements")
public class Announcement {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long announcementId;
    @Column(nullable = false, updatable = false) private Long clubId;
    @Column(nullable = false, updatable = false) private Long authorUserId;
    @Column(nullable = false, updatable = false) private Long authorAssignmentId;
    @Column(nullable = false, length = 200) private String title;
    @Column(nullable = false, length = 10000) private String content;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private AnnouncementPriority priority;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private AnnouncementStatus status;
    @Column(nullable = false, updatable = false) private LocalDateTime createdAt;
    @Column(nullable = false) private LocalDateTime updatedAt;
    private LocalDateTime publishedAt;
    private LocalDateTime expiresAt;
    private LocalDateTime removedAt;
    protected Announcement() {}
    public Announcement(long club, long author, long assignment, String title, String content,
            AnnouncementPriority priority, LocalDateTime expiresAt, LocalDateTime now) {
        clubId = club; authorUserId = author; authorAssignmentId = assignment;
        status = AnnouncementStatus.UNPUBLISHED; createdAt = now;
        edit(title, content, priority, expiresAt, now);
    }
    public void edit(String title, String content, AnnouncementPriority priority, LocalDateTime expiresAt, LocalDateTime now) {
        this.title = title; this.content = content; this.priority = priority; this.expiresAt = expiresAt; updatedAt = now;
    }
    public void publish(LocalDateTime now) { status = AnnouncementStatus.PUBLISHED; publishedAt = now; updatedAt = now; }
    public void unpublish(LocalDateTime now) { status = AnnouncementStatus.UNPUBLISHED; updatedAt = now; }
    public void remove(LocalDateTime now) { status = AnnouncementStatus.REMOVED; removedAt = now; updatedAt = now; }
    // Expiry is evaluated on every query/read: no scheduler lag and no writes in public GETs.
    public AnnouncementStatus statusAt(LocalDateTime now) {
        return status == AnnouncementStatus.PUBLISHED && expiresAt != null && !expiresAt.isAfter(now)
                ? AnnouncementStatus.EXPIRED : status;
    }
    public Long getId() { return announcementId; }
    public Long getClubId() { return clubId; }
    public Long getAuthorUserId() { return authorUserId; }
    public Long getAuthorAssignmentId() { return authorAssignmentId; }
    public String getTitle() { return title; }
    public String getContent() { return content; }
    public AnnouncementPriority getPriority() { return priority; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public LocalDateTime getPublishedAt() { return publishedAt; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public LocalDateTime getRemovedAt() { return removedAt; }
}
