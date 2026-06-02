package com.spl2.uniconnect.dto.response.user;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.spl2.uniconnect.domain.user.UserRole;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserResponse {

    private Long userId;
    private String fullName;
    private String email;
    private UserRole role;
    private String profilePhoto;  // ✅ This exists in User entity
}