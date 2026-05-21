package com.spl2.uniconnect.dto.request.auth;

import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.validation.ValidUniversityEmail;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "User registration request")

public class RegisterRequest {

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    @ValidUniversityEmail  //  Only @iut-dhaka.edu allowed
    @Size(max = 255, message = "Email cannot exceed 255 characters")
    @Schema(description = "User email address", example = "user@iut-dhaka.edu")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 8, max = 100, message = "Password must be between 8 and 100 characters")
    @Schema(description = "User password", example = "password123")
    private String password;

    @NotBlank(message = "Full name is required")
    @Size(min = 2, max = 255, message = "Full name must be between 2 and 255 characters")
    @Schema(description = "User full name", example = "John Doe")
    private String fullName;

    @NotNull(message = "Role is required")
    @Schema(description = "User role", example = "STUDENT", allowableValues = {"STUDENT", "ALUMNI", "CLUB_ADMIN"})
    private UserRole role;
}