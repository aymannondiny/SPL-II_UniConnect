package com.uniconnect.profile.dto;

import jakarta.validation.constraints.*;
import com.uniconnect.profile.domain.DegreeLevel;

public record DegreeRequest(@NotNull @Positive Long programmeId, @NotNull DegreeLevel degreeLevel, @NotNull @Min(1) @Max(20) Integer durationYears, @NotNull @Min(1) @Max(20) Integer minimumYear, @NotNull @Min(1) @Max(20) Integer maximumYear, @NotNull Boolean active) {
    @Override public String toString() { return "DegreeRequest[REDACTED]"; }
}
