package com.uniconnect.mentorship.dto;

import com.uniconnect.mentorship.domain.ScheduleType;
import com.uniconnect.mentorship.domain.SlotMode;
import com.uniconnect.mentorship.domain.SlotStatus;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

public record MentorshipSlotSummaryResponse(
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
        SlotMode mode,
        String location,
        String meetingLink,
        Integer capacity,
        Integer currentMenteeCount,
        SlotStatus status,
        LocalDate recurrenceEndDate,
        Integer meetingCount,
        boolean enrollmentOpen,
        Integer vacancies,
        LocalDateTime ongoingOccurrenceStartsAt,
        LocalDateTime nextOccurrenceStartsAt,
        String slotTopic
) {}
