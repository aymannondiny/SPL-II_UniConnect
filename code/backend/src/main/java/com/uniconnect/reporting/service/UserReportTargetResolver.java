package com.uniconnect.reporting.service;

import com.uniconnect.profile.service.MemberProfileService;
import com.uniconnect.reporting.domain.ReportTargetType;
import com.uniconnect.shared.security.SessionPrincipal;
import java.util.LinkedHashMap;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

@Component
public class UserReportTargetResolver implements ReportTargetResolver {
    private final MemberProfileService profiles; private final JsonMapper json;
    public UserReportTargetResolver(MemberProfileService profiles,JsonMapper json){this.profiles=profiles;this.json=json;}
    public boolean supports(ReportTargetType type){return type==ReportTargetType.USER;}
    public ReportTargetEvidence resolve(SessionPrincipal actor,ReportTargetType type,long id){
        var p=profiles.view(actor,id);var evidence=new LinkedHashMap<String,Object>();
        evidence.put("userId",p.userId());evidence.put("fullName",p.fullName());evidence.put("platformRole",p.platformRole());
        evidence.put("profilePhotoUrl",p.profilePhotoUrl());
        if(p.detailsVisible()&&p.details()!=null){evidence.put("bio",p.details().bio());evidence.put("skills",p.details().skills());evidence.put("interests",p.details().interests());}
        return new ReportTargetEvidence(p.fullName(),json.writeValueAsString(evidence),p.userId(),null);
    }
}
