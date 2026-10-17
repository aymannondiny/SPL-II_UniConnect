package com.uniconnect.profile.dto;

import jakarta.validation.constraints.*;

public record DepartmentRequest(@NotBlank @Size(max = 150) String name, @NotBlank @Pattern(regexp = "[A-Za-z0-9_-]{1,30}") String code) {
    @Override public String toString() { return "DepartmentRequest[REDACTED]"; }
}
