package com.uniconnect.reporting.dto;
import com.uniconnect.reporting.domain.*;
import java.time.LocalDateTime;
import java.util.List;
public record AdminReportResponse(Long id, Long reporterId, ReportTargetType targetType, Long targetId,
        String targetLabel, String reason, ReportStatus status, String targetSnapshot, Long targetOwnerUserId,
        Long parentClubId, Long reviewerId, LocalDateTime submittedAt, LocalDateTime reviewStartedAt,
        LocalDateTime resolvedAt, String resolutionSummary, String internalNotes,
        ActionLinkResponse action, List<ReportAuditResponse> history) {}
