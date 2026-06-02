package com.spl2.uniconnect.dto.request.notification;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data

// Optional Admin Create
public class NotificationCreateRequest {

    @NotNull
    private Long userId;

    @NotNull
    private String type;

    @NotBlank
    private String content;

    private Long referenceId;
    private String referenceType;
}