package com.uniconnect.project.dto;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
public record ProjectSkillRequest(@NotBlank @Size(max = 60) String name, boolean required) {}
