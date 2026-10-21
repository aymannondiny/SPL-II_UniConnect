package com.uniconnect.discovery.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.uniconnect.connection.dto.ConnectionSummary;
import com.uniconnect.profile.dto.AcademicCatalogResponse.DepartmentOption;
import com.uniconnect.profile.dto.AcademicCatalogResponse.ProgrammeOption;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProjectCandidateResponse(
        long userId,
        String fullName,
        String profilePhotoUrl,
        DepartmentOption department,
        ProgrammeOption programme,
        Integer yearOfStudy,
        Boolean projectAvailable,
        List<CandidateSkillResponse> relevantSkills,
        ConnectionSummary connection
) {}
