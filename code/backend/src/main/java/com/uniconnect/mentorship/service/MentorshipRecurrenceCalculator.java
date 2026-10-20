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

    public List<LocalDate> calculateOccurrences(
            ScheduleType scheduleType,
            LocalDate startDate,
            LocalDate recurrenceEndDate
    ) {
        if (startDate == null) return Collections.emptyList();
        if (scheduleType == null || scheduleType == ScheduleType.ONE_TIME) {
            return List.of(startDate);
        }

        List<LocalDate> occurrences = new ArrayList<>();
        LocalDate current = startDate;
        int stepWeeks = (scheduleType == ScheduleType.BIWEEKLY) ? 2 : 1;

        LocalDate limitDate = (recurrenceEndDate != null)
                ? recurrenceEndDate
                : startDate.plusWeeks((long) DEFAULT_MAX_OCCURRENCES * stepWeeks);

        while (!current.isAfter(limitDate) && occurrences.size() < DEFAULT_MAX_OCCURRENCES) {
            occurrences.add(current);
            current = current.plusWeeks(stepWeeks);
        }

        return Collections.unmodifiableList(occurrences);
    }
}
