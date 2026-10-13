package com.uniconnect.club.dto;
import jakarta.validation.constraints.*;
import com.uniconnect.shared.security.ContextType;
public record RevokeRepresentativeRequest(@NotBlank @Size(max=1000) String reason, @NotNull @AssertTrue Boolean confirmed) {}
