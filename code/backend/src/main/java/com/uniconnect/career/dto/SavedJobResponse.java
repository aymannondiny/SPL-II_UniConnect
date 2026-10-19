package com.uniconnect.career.dto;

import java.time.LocalDateTime;

public record SavedJobResponse(
        long id,
        String note,
        LocalDateTime savedAt,
        LocalDateTime updatedAt,
        CareerPostResponse post
) {}
