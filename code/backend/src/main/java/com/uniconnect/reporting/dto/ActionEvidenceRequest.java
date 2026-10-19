package com.uniconnect.reporting.dto;
import com.uniconnect.reporting.domain.ActionEvidenceSource;
import jakarta.validation.constraints.*;
public record ActionEvidenceRequest(@NotNull ActionEvidenceSource source, @Positive long id) {}
