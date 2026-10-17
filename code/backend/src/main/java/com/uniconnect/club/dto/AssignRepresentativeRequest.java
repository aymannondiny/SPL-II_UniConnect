package com.uniconnect.club.dto;
import jakarta.validation.constraints.*;
import com.uniconnect.shared.security.ContextType;
public record AssignRepresentativeRequest(@NotNull @Positive Long userId) {}
