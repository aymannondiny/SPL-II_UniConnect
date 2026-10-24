package com.uniconnect.mentorship.dto;

import com.uniconnect.mentorship.domain.ScheduleType;
import com.uniconnect.mentorship.domain.SlotMode;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.time.LocalTime;

public record UpdateSlotRequest(
        @NotBlank(message = "Topic is required")
        @Size(min = 2, max = 200, message = "Topic must be between 2 and 200 characters")
        String topic,

        @NotBlank(message = "Description is required")
        @Size(min = 5, max = 2000, message = "Description must be between 5 and 2000 characters")
        String description,

        @NotNull(message = "Schedule type is required")
        ScheduleType scheduleType,

        @NotNull(message = "Start date is required")
        LocalDate startDate,

        @NotNull(message = "Start time is required")
        LocalTime startTime,

        @NotNull(message = "End time is required")
        LocalTime endTime,

        LocalDate recurrenceEndDate,

        @NotNull(message = "Mode is required")
        SlotMode mode,

        @Size(max = 255, message = "Location must be at most 255 characters")
        String location,

        @Size(max = 500, message = "Meeting link must be at most 500 characters")
        String meetingLink,

        @NotNull(message = "Capacity is required")
        @Min(value = 1, message = "Capacity must be at least 1")
        @Max(value = 50, message = "Capacity must be at most 50")
        Integer capacity,

        @Min(value = 1, message = "Meeting count must be at least 1")
        @Max(value = 52, message = "Meeting count must be at most 52")
        Integer meetingCount
) {
    public UpdateSlotRequest(String topic, String description, ScheduleType scheduleType,
            LocalDate startDate, LocalTime startTime, LocalTime endTime, LocalDate recurrenceEndDate,
            SlotMode mode, String location, String meetingLink, Integer capacity) {
        this(topic, description, scheduleType, startDate, startTime, endTime, recurrenceEndDate,
                mode, location, meetingLink, capacity, null);
    }
}
