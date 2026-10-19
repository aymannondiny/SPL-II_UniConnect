package com.uniconnect.reporting.service;

import com.uniconnect.authentication.service.AccountAdministrationService;
import com.uniconnect.notification.service.ReportNotificationService;
import com.uniconnect.reporting.domain.*;
import com.uniconnect.reporting.dto.*;
import com.uniconnect.reporting.repository.ReportingRepository;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import java.time.*;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @Transactional
public class ReportReviewService {
    private final AccountAdministrationService accounts;private final ReportingRepository reports;
    private final ReportActionEvidenceService evidence;private final ReportNotificationService notifications;private final Clock clock;
    public ReportReviewService(AccountAdministrationService accounts,ReportingRepository reports,
            ReportActionEvidenceService evidence,ReportNotificationService notifications,Clock clock){
        this.accounts=accounts;this.reports=reports;this.evidence=evidence;this.notifications=notifications;this.clock=clock;}
    public PageResponse<AdminReportResponse> queue(SessionPrincipal actor,ReportStatus status,ReportTargetType type,int page,int size){
        accounts.requireAdministration(actor);PageValidation.check(page,size);
        return new PageResponse<>(reports.queue(status,type,page,size).stream().map(this::response).toList(),page,size,reports.queueCount(status,type));}
    public AdminReportResponse get(SessionPrincipal actor,long id){accounts.requireAdministration(actor);return response(require(id));}
    public AdminReportResponse review(SessionPrincipal actor,long id){accounts.requireAdministration(actor);var report=requireLocked(id);var now=now();
        if(report.getStatus()==ReportStatus.UNDER_REVIEW){
            if(report.getReviewerId()==actor.userId())return response(report);
            throw conflict("REPORT_ALREADY_UNDER_REVIEW","Another administrator is reviewing this report.");
        }
        if(report.getStatus()!=ReportStatus.SUBMITTED)throw conflict("INVALID_REPORT_STATE","Only submitted reports can enter review.");
        report.startReview(actor.userId(),now);reports.insert(new ReportAuditLog(id,actor.userId(),ReportAuditEventType.UNDER_REVIEW,
                ReportStatus.SUBMITTED,ReportStatus.UNDER_REVIEW,null,now));return response(report);
    }
    public AdminReportResponse resolve(SessionPrincipal actor,long id,ResolveReportRequest request){
        accounts.requireAdministration(actor);validate(request);var report=requireLocked(id);
        if(report.getStatus()==ReportStatus.ACTION_TAKEN||report.getStatus()==ReportStatus.NO_ACTION)return retry(report,request);
        if(report.getStatus()!=ReportStatus.UNDER_REVIEW)throw conflict("INVALID_REPORT_STATE","The report must be under review before resolution.");
        if(report.getReviewerId()!=actor.userId())throw new ForbiddenException("Only the reviewing administrator may resolve this report.");
        var now=now();VerifiedActionEvidence verified=null;
        if(request.outcome()==ReportStatus.ACTION_TAKEN)verified=evidence.verify(report,request.actionEvidence());
        String summary=request.resolutionSummary().strip();String notes=clean(request.internalNotes());
        if(verified!=null)reports.insert(new ReportActionLink(id,verified.source(),verified.id(),verified.actionType(),verified.subjectType(),
                verified.subjectId(),verified.occurredAt(),actor.userId(),now));
        report.resolve(request.outcome(),summary,notes,now);
        reports.insert(new ReportAuditLog(id,actor.userId(),ReportAuditEventType.valueOf(request.outcome().name()),
                ReportStatus.UNDER_REVIEW,request.outcome(),notes,now));
        notifications.resolved(report.getReporterId(),id,request.outcome()==ReportStatus.ACTION_TAKEN,now);
        return response(report);
    }
    private AdminReportResponse retry(ContentReport report,ResolveReportRequest request){
        var link=reports.action(report.getId());boolean same=report.getStatus()==request.outcome()
                &&Objects.equals(report.getResolutionSummary(),request.resolutionSummary().strip())
                &&Objects.equals(report.getInternalNotes(),clean(request.internalNotes()));
        if(same&&request.outcome()==ReportStatus.ACTION_TAKEN)same=request.actionEvidence()!=null&&link!=null
                &&link.getEvidenceSource()==request.actionEvidence().source()&&link.getEvidenceId()==request.actionEvidence().id();
        if(same&&request.outcome()==ReportStatus.NO_ACTION)same=request.actionEvidence()==null;
        if(same)return response(report);
        throw conflict("REPORT_ALREADY_RESOLVED","The report was already resolved with different details.");
    }
    private void validate(ResolveReportRequest request){
        if(request.outcome()!=ReportStatus.ACTION_TAKEN&&request.outcome()!=ReportStatus.NO_ACTION)
            throw new BadRequestException("INVALID_REPORT_OUTCOME","Outcome must be ACTION_TAKEN or NO_ACTION.");
        if(request.outcome()==ReportStatus.NO_ACTION&&request.actionEvidence()!=null)
            throw new BadRequestException("INVALID_REPORT_OUTCOME","NO_ACTION cannot include action evidence.");
    }
    private ContentReport require(long id){var r=reports.find(id);if(r==null)throw new ResourceNotFoundException("Report",id);return r;}
    private ContentReport requireLocked(long id){var r=reports.lock(id);if(r==null)throw new ResourceNotFoundException("Report",id);return r;}
    private AdminReportResponse response(ContentReport r){return new AdminReportResponse(r.getId(),r.getReporterId(),r.getTargetType(),r.getTargetId(),
            r.getTargetLabel(),r.getReason(),r.getStatus(),r.getTargetSnapshot(),r.getTargetOwnerUserId(),r.getParentClubId(),r.getReviewerId(),
            r.getSubmittedAt(),r.getReviewStartedAt(),r.getResolvedAt(),r.getResolutionSummary(),r.getInternalNotes(),
            ActionLinkResponse.from(reports.action(r.getId())),reports.history(r.getId()).stream().map(ReportAuditResponse::from).toList());}
    private String clean(String value){return value==null||value.isBlank()?null:value.strip();}
    private ConflictException conflict(String code,String message){return new ConflictException(code,message);}
    private LocalDateTime now(){return LocalDateTime.ofInstant(clock.instant(),ZoneOffset.UTC);}
}
