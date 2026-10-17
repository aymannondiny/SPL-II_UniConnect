package com.uniconnect.profile.controller;

import com.uniconnect.profile.dto.*;
import com.uniconnect.profile.service.*;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.exception.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import com.uniconnect.profile.dto.AcademicCatalogResponse.*;

@RestController
@RequestMapping("/api/v1/admin/academics")
@Tag(name = "Academic catalog administration")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Authentication required", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Operation not permitted", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Profile or academic option not found", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting data", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class AcademicCatalogController {
    private final AcademicCatalogService catalog;
    public AcademicCatalogController(AcademicCatalogService catalog) { this.catalog = catalog; }
    @GetMapping
    @Operation(summary = "List the complete academic catalog, including inactive degrees")
    @ApiResponse(responseCode = "200", description = "Successful response", content = @Content(mediaType = "application/json", schema = @Schema(implementation = AcademicCatalogResponse.class)))
    public ResponseEntity<AcademicCatalogResponse> list(@AuthenticationPrincipal SessionPrincipal actor) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(catalog.list(actor, true));
    }
    @PostMapping("/departments")
    @Operation(summary = "Create department")
    @ApiResponse(responseCode = "201", description = "Created")
    public ResponseEntity<DepartmentOption> createDepartment(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody DepartmentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(catalog.createDepartment(actor, request));
    }
    @PutMapping("/departments/{id}")
    @Operation(summary = "Update department")
    @ApiResponse(responseCode = "200", description = "Successful response", content = @Content(mediaType = "application/json", schema = @Schema(implementation = DepartmentOption.class)))
    public DepartmentOption updateDepartment(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable Long id, @Valid @RequestBody DepartmentRequest request) {
        return catalog.updateDepartment(actor, id, request);
    }
    @PostMapping("/programmes")
    @Operation(summary = "Create programme")
    @ApiResponse(responseCode = "201", description = "Created")
    public ResponseEntity<ProgrammeOption> createProgramme(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody ProgrammeRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(catalog.createProgramme(actor, request));
    }
    @PutMapping("/programmes/{id}")
    @Operation(summary = "Update programme")
    @ApiResponse(responseCode = "200", description = "Successful response", content = @Content(mediaType = "application/json", schema = @Schema(implementation = ProgrammeOption.class)))
    public ProgrammeOption updateProgramme(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable Long id, @Valid @RequestBody ProgrammeRequest request) {
        return catalog.updateProgramme(actor, id, request);
    }
    @PostMapping("/degrees")
    @Operation(summary = "Create degree")
    @ApiResponse(responseCode = "201", description = "Created")
    public ResponseEntity<DegreeOption> createDegree(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody DegreeRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(catalog.createDegree(actor, request));
    }
    @PutMapping("/degrees/{id}")
    @Operation(summary = "Update degree")
    @ApiResponse(responseCode = "200", description = "Successful response", content = @Content(mediaType = "application/json", schema = @Schema(implementation = DegreeOption.class)))
    public DegreeOption updateDegree(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable Long id, @Valid @RequestBody DegreeRequest request) {
        return catalog.updateDegree(actor, id, request);
    }
}
