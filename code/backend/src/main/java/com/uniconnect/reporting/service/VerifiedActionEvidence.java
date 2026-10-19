package com.uniconnect.reporting.service;
import com.uniconnect.reporting.domain.ActionEvidenceSource;
import java.time.LocalDateTime;
public record VerifiedActionEvidence(ActionEvidenceSource source,long id,String actionType,String subjectType,long subjectId,LocalDateTime occurredAt) {}
