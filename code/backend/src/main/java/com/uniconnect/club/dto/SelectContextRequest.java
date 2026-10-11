package com.uniconnect.club.dto;
import jakarta.validation.constraints.*;
import com.uniconnect.shared.security.ContextType;
public record SelectContextRequest(@NotNull ContextType contextType, @Positive Long assignmentId) {}
