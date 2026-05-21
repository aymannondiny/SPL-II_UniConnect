package com.spl2.uniconnect.dto.request.auth;

import com.spl2.uniconnect.validation.ValidUniversityEmail;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    @ValidUniversityEmail  //  Only @iut-dhaka.edu allowed
    private String email;

    @NotBlank(message = "Password is required")
    private String password;
}