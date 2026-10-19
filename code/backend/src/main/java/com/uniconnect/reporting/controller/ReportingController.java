package com.uniconnect.reporting.controller;
import com.uniconnect.reporting.dto.*;
import com.uniconnect.reporting.service.ReportingService;
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
@RestController @RequestMapping("/api/v1/reports") @Tag(name="Content reporting") @SecurityRequirement(name="sessionBearer")
@ApiResponse(responseCode="400",description="Invalid report request",content=@Content(schema=@Schema(implementation=ApiError.class)))
@ApiResponse(responseCode="401",description="Invalid or inactive session",content=@Content(schema=@Schema(implementation=ApiError.class)))
@ApiResponse(responseCode="404",description="Report or accessible target not found",content=@Content(schema=@Schema(implementation=ApiError.class)))
@ApiResponse(responseCode="409",description="Duplicate open report",content=@Content(schema=@Schema(implementation=ApiError.class)))
public class ReportingController {
    private final ReportingService reports;public ReportingController(ReportingService reports){this.reports=reports;}
    @PostMapping @Operation(summary="Submit a content report",description="Requires an ACTIVE account. The selected context does not affect submission authority.")
    @ApiResponse(responseCode="201",description="Report submitted",content=@Content(schema=@Schema(implementation=ReportResponse.class)))
    public ResponseEntity<ReportResponse> submit(@AuthenticationPrincipal SessionPrincipal actor,@Valid @RequestBody SubmitReportRequest request){
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore()).body(reports.submit(actor,request));}
    @GetMapping @Operation(summary="List the current reporter's reports")
    @ApiResponse(responseCode="200",description="Reporter-owned report page",useReturnTypeSchema=true)
    public ResponseEntity<PageResponse<ReportResponse>> list(@AuthenticationPrincipal SessionPrincipal actor,@RequestParam(defaultValue="0")int page,
            @RequestParam(defaultValue="20")int size){return ok(reports.list(actor,page,size));}
    @GetMapping("/{id}") @Operation(summary="Read one reporter-owned report")
    @ApiResponse(responseCode="200",description="Reporter-safe report detail",useReturnTypeSchema=true)
    public ResponseEntity<ReportResponse> get(@AuthenticationPrincipal SessionPrincipal actor,@PathVariable long id){return ok(reports.get(actor,id));}
    private <T>ResponseEntity<T> ok(T body){return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(body);}
}
