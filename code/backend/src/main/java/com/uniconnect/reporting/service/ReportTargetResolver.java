package com.uniconnect.reporting.service;
import com.uniconnect.reporting.domain.ReportTargetType;
import com.uniconnect.shared.security.SessionPrincipal;
public interface ReportTargetResolver {
    boolean supports(ReportTargetType type);
    ReportTargetEvidence resolve(SessionPrincipal actor, ReportTargetType type, long targetId);
}
