package com.spl2.uniconnect.dto.request.project;

import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SkillSearchRequest {

    @NotEmpty(message = "At least one required skill is needed")
    private List<String> requiredSkills;  // Skill names

    private List<String> optionalSkills;  // Skill names (optional)
}