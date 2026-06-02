package com.spl2.uniconnect.dto.request.connection;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConnectionRequest {

    @NotNull(message = "Receiver ID is required")
    private Long receiverId;

    @Size(max = 500, message = "Message cannot exceed 500 characters")
    private String message;  // ✅ Optional connection request message
}