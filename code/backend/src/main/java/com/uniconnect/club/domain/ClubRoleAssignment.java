package com.uniconnect.club.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "club_role_assignments")
public class ClubRoleAssignment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long assignmentId;
    @Column(nullable = false, updatable = false) private Long clubId;
    @Column(nullable = false, updatable = false) private Long userId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30, updatable = false) private ClubRole role;
    @Column(nullable = false, updatable = false) private Long assignedBy;
    @Column(nullable = false, updatable = false) private LocalDateTime assignedAt;
    private Long revokedBy;
    private LocalDateTime revokedAt;
    // Nullable keys express current-assignment uniqueness in PostgreSQL and H2.
    private Long currentClubId;
    private Long currentUserId;
    // These nullable search keys are intentionally non-unique: administrators
    // may be assigned to multiple clubs and a club may have multiple admins.
    private Long administratorClubId;
    private Long administratorUserId;
    protected ClubRoleAssignment() {}
    public ClubRoleAssignment(long club, long user, ClubRole role, long grantor, LocalDateTime now) {
        clubId = club; userId = user; this.role = role; assignedBy = grantor; assignedAt = now;
        currentClubId = club; currentUserId = user;
        if (role == ClubRole.CLUB_ADMINISTRATOR) { administratorClubId = club; administratorUserId = user; }
    }
    public void revoke(long actor, LocalDateTime now) {
        if (!isCurrent()) throw new IllegalStateException("Assignment already revoked");
        revokedBy = actor; revokedAt = now;
        currentClubId = null; currentUserId = null; administratorClubId = null; administratorUserId = null;
    }
    public boolean isCurrent() { return revokedAt == null; }
    public Long getId() { return assignmentId; }
    public Long getClubId() { return clubId; }
    public Long getUserId() { return userId; }
    public ClubRole getRole() { return role; }
    public Long getAssignedBy() { return assignedBy; }
    public LocalDateTime getAssignedAt() { return assignedAt; }
    public Long getRevokedBy() { return revokedBy; }
    public LocalDateTime getRevokedAt() { return revokedAt; }
}
