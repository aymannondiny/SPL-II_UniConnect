package com.spl2.uniconnect.dto.request.auth;

import com.spl2.uniconnect.validation.ValidUniversityEmail;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Admin account creation request")
public class CreateAdminRequest {

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    @ValidUniversityEmail  // Only @iut-dhaka.edu allowed
    @Size(max = 255, message = "Email cannot exceed 255 characters")
    @Schema(description = "Admin email address", example = "admin@iut-dhaka.edu")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 8, max = 100, message = "Password must be between 8 and 100 characters")
    @Schema(description = "Admin password", example = "AdminPassword123")
    private String password;

    @NotBlank(message = "Full name is required")
    @Size(min = 2, max = 255, message = "Full name must be between 2 and 255 characters")
    @Schema(description = "Admin full name", example = "John Admin")
    private String fullName;

    @NotBlank(message = "Admin role is required")
    @Size(min = 3, max = 100, message = "Admin role must be between 3 and 100 characters")
    @Schema(
            description = "Admin role/title",
            example = "Super Admin",
            allowableValues = {"Super Admin", "Content Moderator", "User Manager", "System Administrator"}
    )
    private String adminRole;
}