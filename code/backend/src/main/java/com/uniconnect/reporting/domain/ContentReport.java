package com.uniconnect.reporting.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "content_reports")
public class ContentReport {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long reportId;
    @Column(nullable = false, updatable = false) private Long reporterId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30, updatable = false) private ReportTargetType targetType;
    @Column(nullable = false, updatable = false) private Long targetId;
    @Column(nullable = false, length = 1000, updatable = false) private String reason;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30) private ReportStatus status;
    @Column(nullable = false, length = 500, updatable = false) private String targetLabel;
    @Column(nullable = false, columnDefinition = "text", updatable = false) private String targetSnapshot;
    @Column(updatable = false) private Long targetOwnerUserId;
    @Column(updatable = false) private Long parentClubId;
    private Long reviewerId;
    @Column(nullable = false, updatable = false) private LocalDateTime submittedAt;
    private LocalDateTime reviewStartedAt;
    private LocalDateTime resolvedAt;
    @Column(length = 1000) private String resolutionSummary;
    @Column(length = 2000) private String internalNotes;
    private Long openReporterId;
    @Enumerated(EnumType.STRING) @Column(length = 30) private ReportTargetType openTargetType;
    private Long openTargetId;

    protected ContentReport() {}

    public ContentReport(long reporterId, ReportTargetType targetType, long targetId, String reason,
            String targetLabel, String targetSnapshot, Long targetOwnerUserId, Long parentClubId,
            LocalDateTime submittedAt) {
        this.reporterId = reporterId; this.targetType = targetType; this.targetId = targetId;
        this.reason = reason; this.status = ReportStatus.SUBMITTED; this.targetLabel = targetLabel;
        this.targetSnapshot = targetSnapshot; this.targetOwnerUserId = targetOwnerUserId;
        this.parentClubId = parentClubId; this.submittedAt = submittedAt;
        this.openReporterId = reporterId; this.openTargetType = targetType; this.openTargetId = targetId;
    }

    public boolean startReview(long reviewerId, LocalDateTime now) {
        if (status == ReportStatus.UNDER_REVIEW && this.reviewerId != null && this.reviewerId == reviewerId) return false;
        if (status != ReportStatus.SUBMITTED) return false;
        status = ReportStatus.UNDER_REVIEW; this.reviewerId = reviewerId; reviewStartedAt = now; return true;
    }

    public void resolve(ReportStatus outcome, String summary, String notes, LocalDateTime now) {
        status = outcome; resolutionSummary = summary; internalNotes = notes; resolvedAt = now;
        openReporterId = null; openTargetType = null; openTargetId = null;
    }

    public Long getId() { return reportId; }
    public Long getReporterId() { return reporterId; }
    public ReportTargetType getTargetType() { return targetType; }
    public Long getTargetId() { return targetId; }
    public String getReason() { return reason; }
    public ReportStatus getStatus() { return status; }
    public String getTargetLabel() { return targetLabel; }
    public String getTargetSnapshot() { return targetSnapshot; }
    public Long getTargetOwnerUserId() { return targetOwnerUserId; }
    public Long getParentClubId() { return parentClubId; }
    public Long getReviewerId() { return reviewerId; }
    public LocalDateTime getSubmittedAt() { return submittedAt; }
    public LocalDateTime getReviewStartedAt() { return reviewStartedAt; }
    public LocalDateTime getResolvedAt() { return resolvedAt; }
    public String getResolutionSummary() { return resolutionSummary; }
    public String getInternalNotes() { return internalNotes; }
}
