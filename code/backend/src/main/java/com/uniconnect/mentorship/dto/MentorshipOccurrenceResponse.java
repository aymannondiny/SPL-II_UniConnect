package com.uniconnect.mentorship.dto;

import java.time.LocalDateTime;

public record MentorshipOccurrenceResponse(
        Long occurrenceId,
        LocalDateTime startsAt,
        LocalDateTime endsAt,
        LocalDateTime cancelledAt,
        boolean ongoing,
        boolean future
) {}
