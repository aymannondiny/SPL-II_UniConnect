package com.uniconnect.reporting.controller;
import com.uniconnect.reporting.domain.*;
import com.uniconnect.reporting.dto.*;
import com.uniconnect.reporting.service.ReportReviewService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.ApiError;
import com.uniconnect.shared.security.SessionPrincipal;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1/admin/reports") @Tag(name="Report administration") @SecurityRequirement(name="sessionBearer")
@ApiResponse(responseCode="400",description="Invalid filter or resolution request",content=@Content(schema=@Schema(implementation=ApiError.class)))
@ApiResponse(responseCode="401",description="Invalid session",content=@Content(schema=@Schema(implementation=ApiError.class)))
@ApiResponse(responseCode="403",description="Administration context or reviewer required",content=@Content(schema=@Schema(implementation=ApiError.class)))
@ApiResponse(responseCode="404",description="Report not found",content=@Content(schema=@Schema(implementation=ApiError.class)))
@ApiResponse(responseCode="409",description="Invalid lifecycle, concurrency, or action evidence",content=@Content(schema=@Schema(implementation=ApiError.class)))
public class ReportAdministrationController {
    private final ReportReviewService reports;public ReportAdministrationController(ReportReviewService reports){this.reports=reports;}
    @GetMapping @Operation(summary="List the moderation queue",description="Requires selected SYSTEM_ADMINISTRATION context.")
    @ApiResponse(responseCode="200",description="Filtered administration report page",useReturnTypeSchema=true)
    public ResponseEntity<PageResponse<AdminReportResponse>> queue(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(required=false)ReportStatus status,@RequestParam(required=false)ReportTargetType targetType,
            @RequestParam(defaultValue="0")int page,@RequestParam(defaultValue="20")int size){return ok(reports.queue(actor,status,targetType,page,size));}
    @GetMapping("/{id}") @Operation(summary="Read report evidence and retained review history")
    @ApiResponse(responseCode="200",description="Administrator report detail",useReturnTypeSchema=true)
    public ResponseEntity<AdminReportResponse> get(@AuthenticationPrincipal SessionPrincipal actor,@PathVariable long id){return ok(reports.get(actor,id));}
    @PostMapping("/{id}/review") @Operation(summary="Claim a submitted report for review",description="The first reviewer owns resolution in this phase; identical retries are no-ops.")
    @ApiResponse(responseCode="200",description="Report under review",useReturnTypeSchema=true)
    public ResponseEntity<AdminReportResponse> review(@AuthenticationPrincipal SessionPrincipal actor,@PathVariable long id){return ok(reports.review(actor,id));}
    @PostMapping("/{id}/resolve") @Operation(summary="Resolve a reviewed report",description="Resolution never executes moderation. ACTION_TAKEN requires verified, committed action evidence.")
    @ApiResponse(responseCode="200",description="Terminal report with retained audit and optional verified action link",useReturnTypeSchema=true)
    public ResponseEntity<AdminReportResponse> resolve(@AuthenticationPrincipal SessionPrincipal actor,@PathVariable long id,
            @Valid @RequestBody ResolveReportRequest request){return ok(reports.resolve(actor,id,request));}
    private <T>ResponseEntity<T> ok(T body){return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(body);}
}
