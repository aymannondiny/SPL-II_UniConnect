package com.uniconnect.club.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "club_creation_requests")
public class ClubCreationRequest {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long requestId;
    @Column(nullable = false, updatable = false) private Long requesterUserId;
    @Column(nullable = false, length = 150, updatable = false) private String clubName;
    @Column(nullable = false, length = 150, updatable = false) private String nameKey;
    @Column(nullable = false, length = 100, updatable = false) private String category;
    @Column(nullable = false, length = 5000, updatable = false) private String description;
    @Column(length = 2048, updatable = false) private String logoUrl;
    @Column(length = 320, updatable = false) private String contactEmail;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private ClubCreationRequestStatus status;
    @Column(nullable = false, updatable = false) private LocalDateTime createdAt;
    @Column(nullable = false) private LocalDateTime updatedAt;
    private LocalDateTime decidedAt;
    private Long decidedBy;
    @Column(length = 1000) private String rejectionReason;
    private Long clubId;
    protected ClubCreationRequest() {}

    public ClubCreationRequest(long requester, String name, String category, String description,
            String logo, String email, LocalDateTime now) {
        requesterUserId = requester; clubName = name; nameKey = Club.key(name); this.category = category;
        this.description = description; logoUrl = logo; contactEmail = email;
        status = ClubCreationRequestStatus.PENDING; createdAt = now; updatedAt = now;
    }
    public void approve(long administrator, long createdClubId, LocalDateTime now) {
        requirePending(); status = ClubCreationRequestStatus.APPROVED; decidedBy = administrator;
        clubId = createdClubId; decidedAt = now; updatedAt = now;
    }
    public void reject(long administrator, String reason, LocalDateTime now) {
        requirePending(); status = ClubCreationRequestStatus.REJECTED; decidedBy = administrator;
        rejectionReason = reason; decidedAt = now; updatedAt = now;
    }
    private void requirePending() {
        if (status != ClubCreationRequestStatus.PENDING) throw new IllegalStateException("Request has already been decided.");
    }
    public Long getId() { return requestId; }
    public Long getRequesterUserId() { return requesterUserId; }
    public String getClubName() { return clubName; }
    public String getCategory() { return category; }
    public String getDescription() { return description; }
    public String getLogoUrl() { return logoUrl; }
    public String getContactEmail() { return contactEmail; }
    public ClubCreationRequestStatus getStatus() { return status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public LocalDateTime getDecidedAt() { return decidedAt; }
    public Long getDecidedBy() { return decidedBy; }
    public String getRejectionReason() { return rejectionReason; }
    public Long getClubId() { return clubId; }
}
