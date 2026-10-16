package com.uniconnect.club.publication.dto;
import com.uniconnect.club.publication.domain.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
public record EventRequest(@NotBlank @Size(max = 200) String title, @NotBlank @Size(max = 10000) String description,
        @Size(max = 500) String location, @Size(max = 2048) String registrationUrl, LocalDateTime registrationDeadline,
        @NotNull LocalDateTime startsAt, @NotNull LocalDateTime endsAt) {}
