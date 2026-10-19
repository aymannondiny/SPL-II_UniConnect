package com.uniconnect.reporting.service;
import com.uniconnect.club.service.ClubService;
import com.uniconnect.reporting.domain.ReportTargetType;
import com.uniconnect.shared.security.SessionPrincipal;
import java.util.LinkedHashMap;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;
@Component
public class ClubReportTargetResolver implements ReportTargetResolver {
    private final ClubService clubs;private final JsonMapper json;
    public ClubReportTargetResolver(ClubService clubs,JsonMapper json){this.clubs=clubs;this.json=json;}
    public boolean supports(ReportTargetType type){return type==ReportTargetType.CLUB;}
    public ReportTargetEvidence resolve(SessionPrincipal actor,ReportTargetType type,long id){
        var c=clubs.get(actor,id);var evidence=new LinkedHashMap<String,Object>();
        evidence.put("clubId",c.id());evidence.put("clubName",c.clubName());evidence.put("category",c.category());
        evidence.put("description",c.description());evidence.put("logoUrl",c.logoUrl());evidence.put("status",c.status());
        return new ReportTargetEvidence(c.clubName(),json.writeValueAsString(evidence),null,c.id());
    }
}
