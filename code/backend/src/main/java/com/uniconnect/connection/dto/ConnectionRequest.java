package com.uniconnect.connection.dto;
import jakarta.validation.constraints.*;
public record ConnectionRequest(@NotNull @Positive Long receiverId, @Size(max = 1000) String introductoryMessage) {}
