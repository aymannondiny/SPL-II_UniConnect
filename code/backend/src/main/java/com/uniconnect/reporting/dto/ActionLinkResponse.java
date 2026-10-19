package com.uniconnect.reporting.dto;
import com.uniconnect.reporting.domain.*;
import java.time.LocalDateTime;
public record ActionLinkResponse(ActionEvidenceSource source, Long evidenceId, String actionType,
        String subjectType, Long subjectId, LocalDateTime actionOccurredAt, Long linkedBy, LocalDateTime linkedAt) {
    public static ActionLinkResponse from(ReportActionLink l){return l==null?null:new ActionLinkResponse(l.getEvidenceSource(),l.getEvidenceId(),
            l.getActionType(),l.getSubjectType(),l.getSubjectId(),l.getActionOccurredAt(),l.getLinkedBy(),l.getLinkedAt());}
}
