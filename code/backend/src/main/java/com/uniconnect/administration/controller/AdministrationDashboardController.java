package com.uniconnect.administration.controller;

import com.uniconnect.administration.dto.AdministrationDashboardSummaryResponse;
import com.uniconnect.administration.service.AdministrationDashboardService;
import com.uniconnect.shared.exception.ApiError;
import com.uniconnect.shared.security.SessionPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/dashboard")
@Tag(name = "Administration dashboard")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "401", description = "Invalid session",
        content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Administration context required",
        content = @Content(schema = @Schema(implementation = ApiError.class)))
public class AdministrationDashboardController {
    private final AdministrationDashboardService dashboard;

    public AdministrationDashboardController(AdministrationDashboardService dashboard) {
        this.dashboard = dashboard;
    }

    @GetMapping("/summary")
    @Operation(summary = "Read administrator dashboard counts",
            description = "Requires an active system administrator with SYSTEM_ADMINISTRATION selected.")
    @ApiResponse(responseCode = "200", description = "Current dashboard counts", useReturnTypeSchema = true)
    public ResponseEntity<AdministrationDashboardSummaryResponse> summary(
            @AuthenticationPrincipal SessionPrincipal actor) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(dashboard.summary(actor));
    }
}
