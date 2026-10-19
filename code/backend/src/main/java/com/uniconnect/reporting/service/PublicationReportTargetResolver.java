package com.uniconnect.reporting.service;
import com.uniconnect.club.publication.service.PublicationService;
import com.uniconnect.reporting.domain.ReportTargetType;
import com.uniconnect.shared.security.SessionPrincipal;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;
@Component
public class PublicationReportTargetResolver implements ReportTargetResolver {
    private final PublicationService publications;private final JsonMapper json;
    public PublicationReportTargetResolver(PublicationService publications,JsonMapper json){this.publications=publications;this.json=json;}
    public boolean supports(ReportTargetType type){return type==ReportTargetType.ANNOUNCEMENT||type==ReportTargetType.EVENT;}
    public ReportTargetEvidence resolve(SessionPrincipal actor,ReportTargetType type,long id){
        if(type==ReportTargetType.ANNOUNCEMENT){var a=publications.reportableAnnouncement(actor,id);
            return new ReportTargetEvidence(a.title(),json.writeValueAsString(a),a.authorUserId(),a.clubId());}
        var e=publications.reportableEvent(actor,id);
        return new ReportTargetEvidence(e.title(),json.writeValueAsString(e),e.authorUserId(),e.clubId());
    }
}
