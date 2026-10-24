package com.uniconnect.mentorship.service;

import com.uniconnect.mentorship.domain.ScheduleType;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Component
public class MentorshipRecurrenceCalculator {

    public static final int DEFAULT_MAX_OCCURRENCES = 12;
    public static final int MAX_OCCURRENCES = 52;

    public List<LocalDate> calculateOccurrences(
            ScheduleType scheduleType,
            LocalDate startDate,
            LocalDate recurrenceEndDate
    ) {
        return calculateOccurrences(scheduleType, startDate, recurrenceEndDate, null);
    }

    public List<LocalDate> calculateOccurrences(
            ScheduleType scheduleType, LocalDate startDate, LocalDate recurrenceEndDate, Integer meetingCount) {
        if (startDate == null) return Collections.emptyList();
        if (scheduleType == null || scheduleType == ScheduleType.ONE_TIME) {
            return List.of(startDate);
        }

        List<LocalDate> occurrences = new ArrayList<>();
        LocalDate current = startDate;
        int stepWeeks = (scheduleType == ScheduleType.BIWEEKLY) ? 2 : 1;

        int limitCount = meetingCount != null ? meetingCount
                : recurrenceEndDate != null ? MAX_OCCURRENCES : DEFAULT_MAX_OCCURRENCES;
        limitCount = Math.min(limitCount, MAX_OCCURRENCES);
        LocalDate limitDate = recurrenceEndDate;

        while ((limitDate == null || !current.isAfter(limitDate)) && occurrences.size() < limitCount) {
            occurrences.add(current);
            current = current.plusWeeks(stepWeeks);
        }

        return Collections.unmodifiableList(occurrences);
    }
}
