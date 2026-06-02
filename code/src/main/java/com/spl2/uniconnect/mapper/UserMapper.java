package com.spl2.uniconnect.mapper;

import org.springframework.stereotype.Component;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.response.user.UserResponse;

@Component
public class UserMapper {

    /**
     * Convert User entity to UserResponse for connections
     */
    public UserResponse toUserResponse(User user) {
        if (user == null) {
            return null;
        }

        return UserResponse.builder()
                .userId(user.getUserId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .role(user.getRole())
                .profilePhoto(user.getProfilePhoto())
                .build();
    }
}