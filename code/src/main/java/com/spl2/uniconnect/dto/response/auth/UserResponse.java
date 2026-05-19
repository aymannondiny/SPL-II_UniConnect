package com.spl2.uniconnect.dto.response.auth;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.spl2.uniconnect.domain.user.UserRole;
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
public class UserResponse {

    private Long userId;
    private String email;
    private String fullName;
    private UserRole role;
    private String profilePhoto;
    private Boolean emailVerified;
    private LocalDateTime createdAt;
}