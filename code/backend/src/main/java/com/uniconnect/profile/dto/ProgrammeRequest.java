package com.uniconnect.profile.dto;

import jakarta.validation.constraints.*;

public record ProgrammeRequest(@NotBlank @Size(max = 150) String name, @NotBlank @Pattern(regexp = "[A-Za-z0-9_-]{1,30}") String code, @NotNull @Positive Long departmentId) {
    @Override public String toString() { return "ProgrammeRequest[REDACTED]"; }
}
