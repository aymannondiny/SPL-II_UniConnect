package com.uniconnect.reporting.dto;
import com.uniconnect.reporting.domain.*;
import java.time.LocalDateTime;
public record ReportResponse(Long id, ReportTargetType targetType, Long targetId, String targetLabel,
        String reason, ReportStatus status, LocalDateTime submittedAt, LocalDateTime reviewStartedAt,
        LocalDateTime resolvedAt, String resolutionSummary) {
    public static ReportResponse from(ContentReport r){return new ReportResponse(r.getId(),r.getTargetType(),r.getTargetId(),
            r.getTargetLabel(),r.getReason(),r.getStatus(),r.getSubmittedAt(),r.getReviewStartedAt(),r.getResolvedAt(),r.getResolutionSummary());}
}
