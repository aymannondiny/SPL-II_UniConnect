package com.uniconnect.club.dto;

import java.util.List;

public record ClubAdminOverviewResponse(ClubResponse club, List<AssignmentResponse> administrators) {}
