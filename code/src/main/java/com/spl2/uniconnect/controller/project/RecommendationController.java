package com.spl2.uniconnect.controller.project;

import com.spl2.uniconnect.dto.request.project.SkillSearchRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.project.TeammateRecommendation;
import com.spl2.uniconnect.service.project.TeammateMatchingService;

import java.util.List;

@RestController
@RequestMapping("/api/recommendations")
@RequiredArgsConstructor
@Tag(name = "Recommendations", description = "Teammate and project recommendation APIs")
public class RecommendationController {

    private final TeammateMatchingService matchingService;

    // =====================================================
    // TEAMMATE RECOMMENDATIONS FOR PROJECT
    // =====================================================

    @GetMapping("/projects/{projectId}/teammates")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(
            summary = "Get teammate recommendations for project",
            description = "Get top 10 recommended teammates for a specific project using graph-based matching algorithm"
    )
    public ResponseEntity<ApiResponse<List<TeammateRecommendation>>> getTeammateRecommendations(
            @PathVariable Long projectId,
            @RequestParam(defaultValue = "10") int topN) {

        // ✅ Validate topN
        if (topN < 1 || topN > 50) {
            topN = 10;
        }

        List<TeammateRecommendation> recommendations = matchingService.getTeammateRecommendations(projectId, topN);

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Top " + topN + " teammate recommendations retrieved",
                        recommendations
                )
        );
    }

    // =====================================================
    // SEARCH TEAMMATES BY SKILLS
    // =====================================================

    @PostMapping("/teammates/by-skills")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(
            summary = "Search teammates by skills",
            description = "Find potential teammates matching required and optional skills"
    )
    public ResponseEntity<ApiResponse<List<TeammateRecommendation>>> searchTeammatesBySkills(
            @RequestBody SkillSearchRequest request,
            @RequestParam(defaultValue = "10") int topN) {

        // ✅ Validate
        if (request.getRequiredSkills() == null || request.getRequiredSkills().isEmpty()) {
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("At least one required skill is needed", 400)  // ✅ Use new error method
            );
        }

        if (topN < 1 || topN > 50) {
            topN = 10;
        }

        List<TeammateRecommendation> results = matchingService.searchTeammatesBySkills(
                request.getRequiredSkills(),
                request.getOptionalSkills(),
                topN
        );

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Found " + results.size() + " matching teammates",
                        results
                )
        );
    }
}