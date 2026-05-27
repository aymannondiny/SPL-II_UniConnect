package com.spl2.uniconnect.dto.request.user;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class UpdateAdminProfileRequest {

    // Required fields
    @NotBlank(message = "Admin role is required")
    @Size(min = 3, max = 100, message = "Admin role must be between 3 and 100 characters")
    private String adminRole;

    // Profile photo URL (from Supabase storage)
    @Size(max = 500, message = "Profile photo URL cannot exceed 500 characters")
    private String profilePhoto;
}