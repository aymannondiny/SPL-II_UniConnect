package com.spl2.uniconnect.dto.response.project;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProjectSkillResponse {

    private Long skillId;

    private String skillName;

    private String category;

    private Boolean isRequired;
}