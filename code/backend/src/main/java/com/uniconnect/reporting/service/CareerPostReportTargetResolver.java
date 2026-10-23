package com.uniconnect.reporting.service;

import com.uniconnect.career.service.CareerBoardService;
import com.uniconnect.reporting.domain.ReportTargetType;
import com.uniconnect.shared.security.SessionPrincipal;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

@Component
public class CareerPostReportTargetResolver implements ReportTargetResolver {
    private final CareerBoardService careers;
    private final JsonMapper json;

    public CareerPostReportTargetResolver(CareerBoardService careers, JsonMapper json) {
        this.careers = careers;
        this.json = json;
    }

    @Override
    public boolean supports(ReportTargetType type) {
        return type == ReportTargetType.CAREER_POST;
    }

    @Override
    public ReportTargetEvidence resolve(SessionPrincipal actor, ReportTargetType type, long id) {
        var target = careers.reportable(actor, id);
        return new ReportTargetEvidence(target.label(), json.writeValueAsString(target.snapshot()),
                target.ownerUserId(), null);
    }
}
