package com.uniconnect.reporting.service;

import com.uniconnect.project.service.ProjectTeammateService;
import com.uniconnect.reporting.domain.ReportTargetType;
import com.uniconnect.shared.security.SessionPrincipal;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

@Component
public class ProjectReportTargetResolver implements ReportTargetResolver {
    private final ProjectTeammateService projects;
    private final JsonMapper json;

    public ProjectReportTargetResolver(ProjectTeammateService projects, JsonMapper json) {
        this.projects = projects;
        this.json = json;
    }

    @Override
    public boolean supports(ReportTargetType type) {
        return type == ReportTargetType.PROJECT;
    }

    @Override
    public ReportTargetEvidence resolve(SessionPrincipal actor, ReportTargetType type, long id) {
        var target = projects.reportable(actor, id);
        return new ReportTargetEvidence(target.label(), json.writeValueAsString(target.snapshot()),
                target.ownerUserId(), null);
    }
}
