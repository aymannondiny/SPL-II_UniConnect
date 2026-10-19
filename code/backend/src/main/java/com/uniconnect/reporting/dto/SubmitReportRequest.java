package com.uniconnect.reporting.dto;
import com.uniconnect.reporting.domain.ReportTargetType;
import jakarta.validation.constraints.*;
public record SubmitReportRequest(@NotNull ReportTargetType targetType, @NotNull @Positive Long targetId,
        @NotBlank @Size(max=1000) String reason) {}
