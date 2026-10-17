package com.uniconnect.club.publication.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "club_events")
public class ClubEvent {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long eventId;
    @Column(nullable = false, updatable = false) private Long clubId;
    @Column(nullable = false, updatable = false) private Long authorUserId;
    @Column(nullable = false, updatable = false) private Long authorAssignmentId;
    @Column(nullable = false, length = 200) private String title;
    @Column(nullable = false, length = 10000) private String description;
    @Column(length = 500) private String location;
    @Column(length = 2048) private String registrationUrl;
    private LocalDateTime registrationDeadline;
    @Column(nullable = false) private LocalDateTime startsAt;
    @Column(nullable = false) private LocalDateTime endsAt;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private EventStatus status;
    @Column(nullable = false, updatable = false) private LocalDateTime publishedAt;
    @Column(nullable = false) private LocalDateTime updatedAt;
    private LocalDateTime removedAt;
    protected ClubEvent() {}
    public ClubEvent(long club, long author, long assignment, String title, String description, String location,
            String registrationUrl, LocalDateTime registrationDeadline, LocalDateTime startsAt, LocalDateTime endsAt, LocalDateTime now) {
        clubId = club; authorUserId = author; authorAssignmentId = assignment;
        status = EventStatus.PUBLISHED; publishedAt = now;
        edit(title, description, location, registrationUrl, registrationDeadline, startsAt, endsAt, now);
    }
    public void edit(String title, String description, String location, String registrationUrl,
            LocalDateTime registrationDeadline, LocalDateTime startsAt, LocalDateTime endsAt, LocalDateTime now) {
        this.title = title; this.description = description; this.location = location;
        this.registrationUrl = registrationUrl; this.registrationDeadline = registrationDeadline;
        this.startsAt = startsAt; this.endsAt = endsAt; updatedAt = now;
    }
    public void remove(LocalDateTime now) { status = EventStatus.REMOVED; removedAt = now; updatedAt = now; }
    public EventTiming timingAt(LocalDateTime now) {
        return now.isBefore(startsAt) ? EventTiming.UPCOMING : now.isAfter(endsAt) ? EventTiming.PAST : EventTiming.ACTIVE;
    }
    public Long getId() { return eventId; }
    public Long getClubId() { return clubId; }
    public Long getAuthorUserId() { return authorUserId; }
    public Long getAuthorAssignmentId() { return authorAssignmentId; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public String getLocation() { return location; }
    public String getRegistrationUrl() { return registrationUrl; }
    public LocalDateTime getRegistrationDeadline() { return registrationDeadline; }
    public LocalDateTime getStartsAt() { return startsAt; }
    public LocalDateTime getEndsAt() { return endsAt; }
    public EventStatus getStatus() { return status; }
    public LocalDateTime getPublishedAt() { return publishedAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public LocalDateTime getRemovedAt() { return removedAt; }
}
