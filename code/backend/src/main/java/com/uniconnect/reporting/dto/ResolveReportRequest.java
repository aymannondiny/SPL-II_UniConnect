package com.uniconnect.reporting.dto;
import com.uniconnect.reporting.domain.ReportStatus;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
public record ResolveReportRequest(@NotNull ReportStatus outcome,
        @NotBlank @Size(max=1000) String resolutionSummary,
        @Size(max=2000) String internalNotes,
        @Valid ActionEvidenceRequest actionEvidence) {}
