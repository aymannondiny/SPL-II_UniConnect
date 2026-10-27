package com.uniconnect.administration.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Authoritative system-administration dashboard counts")
public record AdministrationDashboardSummaryResponse(
        @Schema(description = "Non-anonymized registered accounts") long totalUsers,
        @Schema(description = "Clubs whose lifecycle status is ACTIVE") long activeClubs,
        @Schema(description = "Currently public club announcements and published club events") long publishedPosts,
        @Schema(description = "Reports in SUBMITTED or UNDER_REVIEW status") long openReports
) {}
