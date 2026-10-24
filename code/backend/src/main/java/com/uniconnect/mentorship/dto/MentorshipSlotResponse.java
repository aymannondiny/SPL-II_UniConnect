package com.uniconnect.mentorship.dto;

import com.uniconnect.mentorship.domain.ScheduleType;
import com.uniconnect.mentorship.domain.SlotMode;
import com.uniconnect.mentorship.domain.SlotStatus;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

public record MentorshipSlotResponse(
        Long slotId,
        Long mentorProfileId,
        Long mentorUserId,
        String mentorName,
        String topic,
        String description,
        ScheduleType scheduleType,
        LocalDate startDate,
        LocalTime startTime,
        LocalTime endTime,
        LocalDate recurrenceEndDate,
        SlotMode mode,
        String location,
        String meetingLink,
        Integer capacity,
        Integer currentMenteeCount,
        SlotStatus status,
        List<LocalDate> occurrences,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        Integer meetingCount,
        boolean enrollmentOpen,
        Integer vacancies,
        LocalDateTime ongoingOccurrenceStartsAt,
        LocalDateTime nextOccurrenceStartsAt,
        List<MentorshipOccurrenceResponse> occurrenceDetails
) {
    public MentorshipSlotResponse(
            Long slotId,
            Long mentorProfileId,
            Long mentorUserId,
            String mentorName,
            String topic,
            String description,
            ScheduleType scheduleType,
            LocalDate startDate,
            LocalTime startTime,
            LocalTime endTime,
            LocalDate recurrenceEndDate,
            SlotMode mode,
            String location,
            String meetingLink,
            Integer capacity,
            Integer currentMenteeCount,
            SlotStatus status,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) {
        this(slotId, mentorProfileId, mentorUserId, mentorName, topic, description,
                scheduleType, startDate, startTime, endTime, recurrenceEndDate, mode,
                location, meetingLink, capacity, currentMenteeCount, status, List.of(startDate),
                createdAt, updatedAt, 1, status == SlotStatus.OPEN || status == SlotStatus.FULL,
                Math.max(0, capacity - currentMenteeCount), null, null, List.of());
    }
}
