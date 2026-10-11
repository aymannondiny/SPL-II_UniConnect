package com.uniconnect.club.dto;
import jakarta.validation.constraints.*;
import com.uniconnect.shared.security.ContextType;
public record ReplaceAdministratorRequest(@NotNull @Positive Long userId, @NotBlank @Size(max=1000) String reason, @NotNull @AssertTrue Boolean confirmed) {}
