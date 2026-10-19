package com.uniconnect.reporting.dto;
import com.uniconnect.reporting.domain.*;
import java.time.LocalDateTime;
public record ReportAuditResponse(Long id, Long actorId, ReportAuditEventType eventType,
        ReportStatus previousStatus, ReportStatus newStatus, String internalNote, LocalDateTime occurredAt) {
    public static ReportAuditResponse from(ReportAuditLog a){return new ReportAuditResponse(a.getId(),a.getActorId(),a.getEventType(),
            a.getPreviousStatus(),a.getNewStatus(),a.getInternalNote(),a.getOccurredAt());}
}
