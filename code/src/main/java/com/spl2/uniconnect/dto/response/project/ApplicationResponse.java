package com.spl2.uniconnect.dto.response.project;

import com.spl2.uniconnect.dto.response.user.UserResponse;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApplicationResponse {

    private Long id;

    private Long projectId;

    private String projectTitle;

    private UserResponse applicant;

    private String message;

    private String status;  // "Pending", "Accepted", "Rejected"

    private LocalDateTime appliedAt;

    private LocalDateTime respondedAt;
}