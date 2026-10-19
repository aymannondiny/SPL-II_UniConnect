package com.uniconnect.reporting.service;

import com.uniconnect.authentication.service.ProfileAccountService;
import com.uniconnect.reporting.domain.*;
import com.uniconnect.reporting.dto.*;
import com.uniconnect.reporting.repository.ReportingRepository;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import java.time.*;
import java.util.List;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @Transactional
public class ReportingService {
    private final ProfileAccountService accounts;private final ReportingRepository reports;
    private final List<ReportTargetResolver> resolvers;private final Clock clock;
    public ReportingService(ProfileAccountService accounts,ReportingRepository reports,List<ReportTargetResolver> resolvers,Clock clock){
        this.accounts=accounts;this.reports=reports;this.resolvers=resolvers;this.clock=clock;}
    public ReportResponse submit(SessionPrincipal actor,SubmitReportRequest request){
        accounts.lockActiveAccount(actor);
        var evidence=resolve(actor,request.targetType(),request.targetId());var now=now();
        var report=new ContentReport(actor.userId(),request.targetType(),request.targetId(),request.reason().strip(),
                evidence.label(),evidence.snapshot(),evidence.ownerUserId(),evidence.parentClubId(),now);
        try{reports.insert(report);reports.insert(new ReportAuditLog(report.getId(),actor.userId(),ReportAuditEventType.SUBMITTED,
                null,ReportStatus.SUBMITTED,null,now));}
        catch(DataIntegrityViolationException duplicate){throw new ConflictException("DUPLICATE_OPEN_REPORT","You already have an open report for this target.");}
        return ReportResponse.from(report);
    }
    public PageResponse<ReportResponse> list(SessionPrincipal actor,int page,int size){accounts.lockActiveAccount(actor);PageValidation.check(page,size);
        return new PageResponse<>(reports.reporter(actor.userId(),page,size).stream().map(ReportResponse::from).toList(),page,size,reports.reporterCount(actor.userId()));}
    public ReportResponse get(SessionPrincipal actor,long id){accounts.lockActiveAccount(actor);var report=reports.find(id);
        if(report==null||report.getReporterId()!=actor.userId())throw new ResourceNotFoundException("Report",id);return ReportResponse.from(report);}
    private ReportTargetEvidence resolve(SessionPrincipal actor,ReportTargetType type,long id){
        return resolvers.stream().filter(r->r.supports(type)).findFirst().orElseThrow(()->new BadRequestException("UNSUPPORTED_REPORT_TARGET","Unsupported report target."))
                .resolve(actor,type,id);
    }
    private LocalDateTime now(){return LocalDateTime.ofInstant(clock.instant(),ZoneOffset.UTC);}
}
