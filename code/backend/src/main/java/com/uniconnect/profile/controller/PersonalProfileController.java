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

@RestController
@RequestMapping("/api/v1/profile")
@Tag(name = "Personal profiles")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Authentication required", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Operation not permitted", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Profile or academic option not found", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting data", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class PersonalProfileController {
    private final PersonalProfileService profiles;
    private final AcademicCatalogService catalog;
    public PersonalProfileController(PersonalProfileService profiles, AcademicCatalogService catalog) {
        this.profiles = profiles; this.catalog = catalog;
    }
    @GetMapping("/me")
    @Operation(summary = "Read your own personal profile")
    @ApiResponse(responseCode = "200", description = "Successful response", content = @Content(mediaType = "application/json", schema = @Schema(implementation = ProfileResponse.class)))
    public ResponseEntity<ProfileResponse> mine(@AuthenticationPrincipal SessionPrincipal actor) {
        return response(profiles.mine(actor));
    }
    @PutMapping("/me/student")
    @Operation(summary = "Create or fully replace your Student profile", description = "Full replacement of editable fields; empty skill/interest arrays clear them. Returns 200 for both creation and update.")
    @ApiResponse(responseCode = "200", description = "Successful response", content = @Content(mediaType = "application/json", schema = @Schema(implementation = ProfileResponse.class)))
    public ResponseEntity<ProfileResponse> student(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody StudentProfileRequest request) {
        return response(profiles.saveStudent(actor, request));
    }
    @PutMapping("/me/alumni")
    @Operation(summary = "Create or fully replace your Alumni profile")
    @ApiResponse(responseCode = "200", description = "Successful response", content = @Content(mediaType = "application/json", schema = @Schema(implementation = ProfileResponse.class)))
    public ResponseEntity<ProfileResponse> alumni(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody AlumniProfileRequest request) {
        return response(profiles.saveAlumni(actor, request));
    }
    @PatchMapping("/me/availability")
    @Operation(summary = "Update Student availability without replacing the profile")
    @ApiResponse(responseCode = "200", description = "Successful response", content = @Content(mediaType = "application/json", schema = @Schema(implementation = ProfileResponse.class)))
    public ResponseEntity<ProfileResponse> availability(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody AvailabilityRequest request) {
        return response(profiles.availability(actor, request));
    }
    @GetMapping("/academic-options")
    @Operation(summary = "List academic departments, programmes, and active degree options")
    @ApiResponse(responseCode = "200", description = "Successful response", content = @Content(mediaType = "application/json", schema = @Schema(implementation = AcademicCatalogResponse.class)))
    public ResponseEntity<AcademicCatalogResponse> options(@AuthenticationPrincipal SessionPrincipal actor) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(catalog.list(actor, false));
    }
    private ResponseEntity<ProfileResponse> response(ProfileResponse profile) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(profile);
    }
}
