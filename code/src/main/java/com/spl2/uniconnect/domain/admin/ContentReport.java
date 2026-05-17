package com.spl2.uniconnect.domain.admin;

import com.spl2.uniconnect.domain.user.User;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "content_reports", indexes = {
        @Index(name = "idx_report_reported_by", columnList = "reported_by"),
        @Index(name = "idx_report_status", columnList = "status"),
        @Index(name = "idx_report_content_type", columnList = "content_type"),
        @Index(name = "idx_report_created", columnList = "created_at"),
        @Index(name = "idx_report_content_type_id", columnList = "content_type, content_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ContentReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "report_id")
    private Long reportId;

    @NotNull(message = "Reporter is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reported_by", nullable = false)
    private User reportedBy;

    @NotNull(message = "Content type is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "content_type", nullable = false, length = 50)
    private ContentType contentType;

    @NotNull(message = "Content ID is required")
    @Column(name = "content_id", nullable = false)
    private Long contentId;

    @NotBlank(message = "Report reason is required")
    @Column(name = "reason", nullable = false, columnDefinition = "TEXT")
    private String reason;

    @NotNull(message = "Status is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private ReportStatus status = ReportStatus.PENDING;

    /**
     * Internal notes by reviewers - NOT visible to reporter
     */
    @Column(name = "admin_notes", columnDefinition = "TEXT")
    private String adminNotes;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewed_by")
    private User reviewedBy;

    // =====================================================
    // Helper Methods
    // =====================================================

    public void startReview(User admin) {
        this.status = ReportStatus.UNDER_REVIEW;
        this.reviewedBy = admin;
    }

    public void resolve(User admin, String notes) {
        this.status = ReportStatus.RESOLVED;
        this.reviewedBy = admin;
        this.adminNotes = notes;
        this.reviewedAt = LocalDateTime.now();
    }

    public void dismiss(User admin, String notes) {
        this.status = ReportStatus.DISMISSED;
        this.reviewedBy = admin;
        this.adminNotes = notes;
        this.reviewedAt = LocalDateTime.now();
    }

    public boolean isPending() {
        return status == ReportStatus.PENDING;
    }

    public boolean isProcessed() {
        return status == ReportStatus.RESOLVED
                || status == ReportStatus.DISMISSED;
    }
}