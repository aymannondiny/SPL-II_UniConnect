package com.uniconnect.reporting.service;

import com.uniconnect.administration.service.AccountModerationService;
import com.uniconnect.club.publication.service.PublicationService;
import com.uniconnect.club.service.ClubLifecycleService;
import com.uniconnect.reporting.domain.*;
import com.uniconnect.reporting.dto.ActionEvidenceRequest;
import com.uniconnect.shared.exception.ConflictException;
import org.springframework.stereotype.Service;

@Service
public class ReportActionEvidenceService {
    private final AccountModerationService accounts;private final ClubLifecycleService clubs;private final PublicationService publications;
    public ReportActionEvidenceService(AccountModerationService accounts,ClubLifecycleService clubs,PublicationService publications){
        this.accounts=accounts;this.clubs=clubs;this.publications=publications;}
    public VerifiedActionEvidence verify(ContentReport report,ActionEvidenceRequest request){
        if(request==null)throw invalid("ACTION_TAKEN requires action evidence.");
        VerifiedActionEvidence evidence=switch(request.source()){
            case ACCOUNT_MODERATION->{var a=accounts.verifySuspensionEvidence(request.id());
                yield new VerifiedActionEvidence(request.source(),a.actionId(),a.actionType(),"USER",a.targetUserId(),a.occurredAt());}
            case CLUB_LIFECYCLE->{var a=clubs.verifyModerationEvidence(request.id());
                yield new VerifiedActionEvidence(request.source(),a.auditId(),a.actionType(),"CLUB",a.clubId(),a.occurredAt());}
            case PUBLICATION->{var a=publications.verifyRemovalEvidence(request.id());
                yield new VerifiedActionEvidence(request.source(),a.auditId(),a.actionType(),a.subjectType(),a.subjectId(),a.occurredAt());}
        };
        if(evidence.occurredAt().isBefore(report.getSubmittedAt()))throw invalid("The action must occur after the report was submitted.");
        boolean related=switch(report.getTargetType()){
            case USER->evidence.subjectType().equals("USER")&&evidence.subjectId()==report.getTargetId();
            case CLUB->evidence.subjectType().equals("CLUB")&&evidence.subjectId()==report.getTargetId();
            case ANNOUNCEMENT->publicationRelationship(report,evidence,"ANNOUNCEMENT");
            case EVENT->publicationRelationship(report,evidence,"EVENT");
            case CHAT_MESSAGE->evidence.subjectType().equals("USER")&&evidence.subjectId()==safe(report.getTargetOwnerUserId());
        };
        if(!related)throw invalid("The action does not qualify for this report target.");
        return evidence;
    }
    private boolean publicationRelationship(ContentReport report,VerifiedActionEvidence evidence,String target){
        return (evidence.subjectType().equals(target)&&evidence.subjectId()==report.getTargetId())
                ||(evidence.subjectType().equals("USER")&&evidence.subjectId()==safe(report.getTargetOwnerUserId()))
                ||(evidence.subjectType().equals("CLUB")&&evidence.subjectId()==safe(report.getParentClubId()));
    }
    private long safe(Long value){return value==null?-1:value;}
    private ConflictException invalid(String message){return new ConflictException("INVALID_ACTION_EVIDENCE",message);}
}
