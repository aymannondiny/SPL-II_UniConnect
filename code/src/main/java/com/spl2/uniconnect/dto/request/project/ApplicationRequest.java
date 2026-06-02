package com.spl2.uniconnect.dto.request.project;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApplicationRequest {

    @Size(max = 500, message = "Message cannot exceed 500 characters")
    private String message;  // Optional message with application
}