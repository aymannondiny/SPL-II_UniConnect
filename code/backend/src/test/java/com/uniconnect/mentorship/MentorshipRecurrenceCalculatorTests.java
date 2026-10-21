package com.uniconnect.mentorship;

import com.uniconnect.mentorship.domain.ScheduleType;
import com.uniconnect.mentorship.service.MentorshipRecurrenceCalculator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class MentorshipRecurrenceCalculatorTests {

    private MentorshipRecurrenceCalculator calculator;
    private final LocalDate start = LocalDate.of(2026, 10, 20);

    @BeforeEach
    void setUp() {
        calculator = new MentorshipRecurrenceCalculator();
    }

    @Test
    void oneOffReturnsSingleStartDate() {
        List<LocalDate> dates = calculator.calculateOccurrences(ScheduleType.ONE_TIME, start, null);
        assertThat(dates).containsExactly(start);
    }

    @Test
    void weeklyGeneratesWeeklyIntervalsUpToMax() {
        List<LocalDate> dates = calculator.calculateOccurrences(ScheduleType.WEEKLY, start, null);
        assertThat(dates).hasSize(MentorshipRecurrenceCalculator.DEFAULT_MAX_OCCURRENCES);
        assertThat(dates.get(0)).isEqualTo(start);
        assertThat(dates.get(1)).isEqualTo(start.plusWeeks(1));
        assertThat(dates.get(2)).isEqualTo(start.plusWeeks(2));
    }

    @Test
    void biweeklyGeneratesBiweeklyIntervals() {
        List<LocalDate> dates = calculator.calculateOccurrences(ScheduleType.BIWEEKLY, start, null);
        assertThat(dates).hasSize(MentorshipRecurrenceCalculator.DEFAULT_MAX_OCCURRENCES);
        assertThat(dates.get(0)).isEqualTo(start);
        assertThat(dates.get(1)).isEqualTo(start.plusWeeks(2));
        assertThat(dates.get(2)).isEqualTo(start.plusWeeks(4));
    }

    @Test
    void recurrenceEndDateTruncatesOccurrences() {
        LocalDate endDate = start.plusWeeks(3);
        List<LocalDate> dates = calculator.calculateOccurrences(ScheduleType.WEEKLY, start, endDate);
        assertThat(dates).containsExactly(
                start,
                start.plusWeeks(1),
                start.plusWeeks(2),
                start.plusWeeks(3)
        );
    }

    @Test
    void nullStartDateReturnsEmpty() {
        List<LocalDate> dates = calculator.calculateOccurrences(ScheduleType.WEEKLY, null, null);
        assertThat(dates).isEmpty();
    }
}
