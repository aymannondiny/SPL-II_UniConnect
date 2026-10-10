package com.uniconnect.chat.dto;
import jakarta.validation.constraints.*;
import java.util.UUID;
public record SendMessageRequest(@NotNull @Positive Long receiverId, @NotNull UUID clientMessageId,
        @NotBlank @Size(max=5000) String content) {}
