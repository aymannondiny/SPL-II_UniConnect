package com.uniconnect.profile.dto;
import com.uniconnect.profile.domain.ProfileVisibility;
import jakarta.validation.constraints.NotNull;
public record PrivacyRequest(@NotNull ProfileVisibility detailsVisibility) {}
