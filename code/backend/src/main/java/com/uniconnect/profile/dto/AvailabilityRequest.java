package com.uniconnect.profile.dto;

import jakarta.validation.constraints.*;

public record AvailabilityRequest(@NotNull Boolean projectAvailability, @NotNull Boolean mentorshipAvailability) {
    @Override public String toString() { return "AvailabilityRequest[REDACTED]"; }
}
