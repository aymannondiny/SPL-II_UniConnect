package com.uniconnect.club.publication.dto;
import com.uniconnect.club.publication.domain.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
public record PublicationActionRequest(@NotNull @AssertTrue Boolean confirm, @NotBlank @Size(max = 1000) String reason) {}
