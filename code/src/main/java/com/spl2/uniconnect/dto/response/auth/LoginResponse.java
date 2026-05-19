package com.spl2.uniconnect.dto.response.auth;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class LoginResponse {

    private String token;
    @Builder.Default
    private String tokenType = "Bearer";
    private Long expiresIn; // seconds
    private UserResponse user;
}