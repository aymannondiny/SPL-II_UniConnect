package com.spl2.uniconnect.dto.response.auth;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.spl2.uniconnect.domain.user.UserRole;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "User information response")
public class UserResponse {


    @Schema(description = "User ID", example = "1")
    private Long userId;

    @Schema(description = "User email", example = "user@iut-dhaka.edu")
    private String email;

    @Schema(description = "User full name", example = "John Doe")
    private String fullName;

    @Schema(description = "User role", example = "STUDENT")
    private String role;

    @Schema(description = "User profile photo URL")
    private String profilePhoto;

    @Schema(description = "Email verification status", example = "true")
    private Boolean emailVerified;

    @Schema(description = "Account creation date", example = "2024-05-21T10:30:00")
    private LocalDateTime createdAt;
}