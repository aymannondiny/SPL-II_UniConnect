package com.uniconnect.mentorship.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.service.ProfileAccountService;
import com.uniconnect.mentorship.domain.*;
import com.uniconnect.mentorship.dto.*;
import com.uniconnect.mentorship.repository.*;
import com.uniconnect.notification.service.MentorshipNotificationService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.PlatformRole;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import jakarta.validation.Validator;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
@Transactional
public class MentorshipSlotService {
    private static final ZoneId SCHEDULE_ZONE = ZoneId.of("Asia/Dhaka");

    private final MentorshipSlotRepository slots;
    private final MentorshipEnrollmentRepository enrollments;
    private final MentorshipOccurrenceRepository occurrences;
    private final MentorProfileRepository mentors;
    private final ProfileAccountService accounts;
    private final MentorshipNotificationService notifications;
    private final MentorshipRecurrenceCalculator recurrence;
    private final Validator validator;
    private final Clock clock;

    public MentorshipSlotService(
            MentorshipSlotRepository slots,
            MentorshipEnrollmentRepository enrollments,
            MentorshipOccurrenceRepository occurrences,
            MentorProfileRepository mentors,
            ProfileAccountService accounts,
            MentorshipNotificationService notifications,
            MentorshipRecurrenceCalculator recurrence,
            Validator validator,
            Clock clock) {
        this.slots = slots;
        this.enrollments = enrollments;
        this.occurrences = occurrences;
        this.mentors = mentors;
        this.accounts = accounts;
        this.notifications = notifications;
        this.recurrence = recurrence;
        this.validator = validator;
        this.clock = clock;
    }

    public MentorshipSlotResponse createSlot(SessionPrincipal actor, CreateSlotRequest request) {
        validate(request);

        // Hosted-schedule lock order: account, host mentor, then series when one exists.
        User user = accounts.lockActiveAccount(actor);
        MentorProfile mentor = lockMentorForCreate(user);
        int meetingCount = resolvedCount(
                request.scheduleType(), request.startDate(), request.recurrenceEndDate(), request.meetingCount());
        List<MeetingWindow> schedule = proposedSchedule(
                request.scheduleType(), request.startDate(), request.startTime(), request.endTime(),
                request.recurrenceEndDate(), meetingCount);
        if (schedule.stream().noneMatch(window -> window.startsAt().isAfter(scheduleNow()))) {
            throw bad("NO_FUTURE_MEETING", "The series must contain a meeting that has not started.");
        }
        assertNoHostedConflicts(mentor.getId(), schedule, null);

        LocalDateTime now = nowUtc();
        MentorshipSlot slot = new MentorshipSlot(
                mentor, request.topic().strip(), request.description().strip(), request.scheduleType(),
                request.startDate(), request.startTime(), request.endTime(), request.recurrenceEndDate(),
                meetingCount, request.mode(), clean(request.location()), clean(request.meetingLink()),
                request.capacity(), now);
        slot = slots.saveAndFlush(slot);
        insertOccurrences(slot, schedule);
        return mapSlot(slot, user.getUserId());
    }

    @Transactional(readOnly = true)
    public MentorshipSlotResponse getSlot(SessionPrincipal actor, Long slotId) {
        User viewer = accounts.activeAccount(actor);
        return mapSlot(visibleSlot(slotId), viewer.getUserId());
    }

    @Transactional(readOnly = true)
    public PageResponse<MentorshipSlotSummaryResponse> browseSlots(
            SessionPrincipal actor, String topic, SlotStatus status, int page, int size) {
        User viewer = accounts.activeAccount(actor);
        PageValidation.check(page, size);
        String normalizedTopic = topic == null || topic.isBlank() ? null : topic.strip();
        Set<SlotStatus> requested = status == null
                ? Set.of(SlotStatus.OPEN, SlotStatus.FULL)
                : Set.of(status);

        // Derive and filter lifecycle state before slicing so totals and pages agree.
        List<MentorshipSlotSummaryResponse> matching = slots.findAllVisible(normalizedTopic).stream()
                .map(slot -> mapSummary(slot, viewer.getUserId()))
                .filter(summary -> requested.contains(summary.status()))
                .toList();
        int from = Math.min(page * size, matching.size());
        int to = Math.min(from + size, matching.size());
        return new PageResponse<>(matching.subList(from, to), page, size, matching.size());
    }

    public MentorshipEnrollmentResponse joinSlot(
            SessionPrincipal actor, Long slotId, EnrollSlotRequest request) {
        if (request != null && !validator.validate(request).isEmpty()) {
            throw bad("INVALID_ENROLLMENT_DATA", "Invalid enrollment data.");
        }

        // Join lock order: applicant account, applicant mentor (when any), target series.
        User applicant = accounts.lockActiveAccount(actor);
        requireEligible(applicant);
        MentorProfile applicantMentor = mentors.findLockedByUserId(applicant.getUserId()).orElse(null);
        MentorshipSlot slot = slots.findLockedById(slotId)
                .filter(candidate -> candidate.getMentorProfile().getUser().canPerformProtectedAction())
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship slot", slotId));
        validateJoinState(slot, applicant);

        List<MentorshipOccurrence> futureMeetings = activeOccurrences(slotId).stream()
                .filter(occurrence -> occurrence.getStartsAt().isAfter(scheduleNow()))
                .toList();
        if (futureMeetings.isEmpty()) {
            throw conflict("NO_FUTURE_MEETING", "No future meeting remains in this series.");
        }
        if (enrollments.existsBySlotSlotIdAndMenteeUserIdAndStatus(
                slotId, applicant.getUserId(), EnrollmentStatus.ACTIVE)) {
            throw conflict("ALREADY_ENROLLED", "You are already enrolled in this series.");
        }
        long activeCount = enrollments.countActiveBySlotId(slotId);
        if (activeCount >= slot.getCapacity()) {
            throw conflict("SLOT_CAPACITY_FULL", "Mentorship series capacity has been reached.");
        }
        assertApplicantHasNoHostedConflicts(applicantMentor, futureMeetings);

        LocalDateTime now = nowUtc();
        MentorshipEnrollment enrollment = enrollments.saveAndFlush(new MentorshipEnrollment(
                slot, applicant,
                request == null ? null : clean(request.joinMessage()),
                request == null ? null : clean(request.learningGoal()), now));
        slot.synchronizeActiveCount((int) activeCount + 1, now);
        notifications.slotJoined(
                slot.getMentorProfile().getUser().getUserId(), applicant.getUserId(), slotId,
                enrollment.getId(), applicant.getFullName(), slot.getTopic(), now);
        return mapEnrollment(enrollment, applicant.getUserId());
    }

    public MentorshipEnrollmentResponse leaveSlot(SessionPrincipal actor, Long slotId) {
        User user = accounts.lockActiveAccount(actor);
        MentorshipSlot slot = lockedSlot(slotId);
        MentorshipEnrollment enrollment = enrollments
                .findBySlotSlotIdAndMenteeUserIdAndStatus(slotId, user.getUserId(), EnrollmentStatus.ACTIVE)
                .orElseThrow(() -> conflict("NOT_ENROLLED", "You are not actively enrolled in this series."));
        LocalDateTime now = nowUtc();
        enrollment.leave(now);
        enrollments.flush();
        slot.synchronizeActiveCount((int) enrollments.countActiveBySlotId(slotId), now);
        notifications.slotLeft(
                slot.getMentorProfile().getUser().getUserId(), slotId, enrollment.getId(),
                user.getFullName(), slot.getTopic(), now);
        return mapEnrollment(enrollment, user.getUserId());
    }

    public MentorshipSlotResponse updateSlot(
            SessionPrincipal actor, Long slotId, UpdateSlotRequest request) {
        validate(request);

        // Keep create/update ordering identical: account, host mentor, target series.
        User user = accounts.lockActiveAccount(actor);
        MentorProfile mentor = mentors.findLockedByUserId(user.getUserId())
                .orElseThrow(() -> new ForbiddenException("Only registered mentors can update a series."));
        MentorshipSlot slot = lockedSlot(slotId);
        requireHost(slot, user);
        if (slot.getStatus() == SlotStatus.CANCELLED) {
            throw conflict("SLOT_CANCELLED", "Cancelled series cannot be updated.");
        }

        long activeCount = enrollments.countActiveBySlotId(slotId);
        if (request.capacity() < activeCount) {
            throw bad("INVALID_CAPACITY", "Capacity cannot be below active enrollment (" + activeCount + ").");
        }
        int requestedCount = resolvedCount(
                request.scheduleType(), request.startDate(), request.recurrenceEndDate(), request.meetingCount());
        boolean scheduleChanged = scheduleChanged(slot, request, requestedCount);
        boolean materialChange = materiallyChanged(slot, request, requestedCount);

        if (!materialChange) {
            return mapSlot(slot, user.getUserId());
        }

        if (scheduleChanged) {
            List<MeetingWindow> replacement = replacementFutureSchedule(slotId, request, requestedCount);
            assertNoHostedConflicts(mentor.getId(), replacement, slotId);
            reconcileFutureOccurrences(slot, replacement);
        }

        LocalDateTime now = nowUtc();
        slot.updateDetails(
                request.topic().strip(), request.description().strip(), request.scheduleType(),
                request.startDate(), request.startTime(), request.endTime(), request.recurrenceEndDate(),
                requestedCount, request.mode(), clean(request.location()), clean(request.meetingLink()),
                request.capacity(), now);
        slot.synchronizeActiveCount((int) activeCount, now);
        slots.flush();
        if (materialChange) {
            notifications.slotUpdated(
                    activeMenteeIds(slotId), slotId, slot.getTopic(), UUID.randomUUID().toString(), now);
        }
        return mapSlot(slot, user.getUserId());
    }

    public MentorshipSlotResponse closeSlot(SessionPrincipal actor, Long slotId) {
        User user = accounts.lockActiveAccount(actor);
        MentorshipSlot slot = lockedSlot(slotId);
        requireHost(slot, user);
        if (slot.getStatus() == SlotStatus.CANCELLED) {
            throw conflict("SLOT_CANCELLED", "Cancelled series cannot be closed.");
        }
        if (slot.isEnrollmentOpen()) {
            slot.close(nowUtc());
        }
        return mapSlot(slot, user.getUserId());
    }

    public MentorshipSlotResponse reopenSlot(SessionPrincipal actor, Long slotId) {
        User user = accounts.lockActiveAccount(actor);
        MentorshipSlot slot = lockedSlot(slotId);
        requireHost(slot, user);
        if (slot.getStatus() == SlotStatus.CANCELLED) {
            throw conflict("SLOT_CANCELLED", "Cancelled series cannot be reopened.");
        }
        if (slot.isEnrollmentOpen()) {
            return mapSlot(slot, user.getUserId());
        }
        if (!occurrences.hasFuture(slotId, scheduleNow())) {
            throw conflict("NO_FUTURE_MEETING", "No future meeting remains.");
        }
        if (enrollments.countActiveBySlotId(slotId) >= slot.getCapacity()) {
            throw conflict("SLOT_CAPACITY_FULL", "No vacancy remains.");
        }
        slot.reopen(nowUtc());
        return mapSlot(slot, user.getUserId());
    }

    public MentorshipSlotResponse cancelSlot(SessionPrincipal actor, Long slotId) {
        User user = accounts.lockActiveAccount(actor);
        MentorshipSlot slot = lockedSlot(slotId);
        requireHost(slot, user);
        if (slot.getStatus() == SlotStatus.CANCELLED) {
            return mapSlot(slot, user.getUserId());
        }

        LocalDateTime now = nowUtc();
        LocalDateTime localNow = scheduleNow();
        activeOccurrences(slotId).stream()
                .filter(occurrence -> occurrence.getStartsAt().isAfter(localNow))
                .forEach(occurrence -> occurrence.cancel(now));
        List<MentorshipEnrollment> active = enrollments
                .findBySlotSlotIdAndStatus(slotId, EnrollmentStatus.ACTIVE);
        active.forEach(enrollment -> enrollment.cancel(now));
        slot.cancel(now);
        slot.synchronizeActiveCount(0, now);
        notifications.slotCancelled(
                active.stream().map(enrollment -> enrollment.getMentee().getUserId()).toList(),
                slotId, slot.getTopic(), now);
        return mapSlot(slot, user.getUserId());
    }

    @Transactional(readOnly = true)
    public List<MentorshipSlotResponse> getMyMentoringSlots(SessionPrincipal actor) {
        User user = accounts.activeAccount(actor);
        return slots.findByMentorProfileUserUserIdOrderByStartDateAscStartTimeAsc(user.getUserId()).stream()
                .map(slot -> mapSlot(slot, user.getUserId()))
                .toList();
    }

    /** Preserves the original endpoint contract: enrollment records, not slot summaries. */
    @Transactional(readOnly = true)
    public List<MentorshipEnrollmentResponse> getMyEnrolledSlots(SessionPrincipal actor) {
        User user = accounts.activeAccount(actor);
        return enrollments
                .findByMenteeUserIdAndStatusOrderByJoinedAtDesc(user.getUserId(), EnrollmentStatus.ACTIVE).stream()
                .filter(enrollment -> hasCurrentParticipation(enrollment.getSlot()))
                .map(enrollment -> mapEnrollment(enrollment, user.getUserId()))
                .toList();
    }

    /** Additive card-ready representation for current participation. */
    @Transactional(readOnly = true)
    public List<MentorshipSlotSummaryResponse> getMyCurrentSeries(SessionPrincipal actor) {
        User user = accounts.activeAccount(actor);
        return enrollments
                .findByMenteeUserIdAndStatusOrderByJoinedAtDesc(user.getUserId(), EnrollmentStatus.ACTIVE).stream()
                .map(MentorshipEnrollment::getSlot)
                .distinct()
                .filter(this::hasCurrentParticipation)
                .map(slot -> mapSummary(slot, user.getUserId()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<MentorshipEnrollmentResponse> getMyParticipation(SessionPrincipal actor) {
        User user = accounts.activeAccount(actor);
        return enrollments.findByMenteeUserIdOrderByJoinedAtDescEnrollmentIdDesc(user.getUserId()).stream()
                .map(enrollment -> mapEnrollment(enrollment, user.getUserId()))
                .toList();
    }

    @Transactional(readOnly = true)
    public MentorshipEnrollmentResponse getEnrollment(SessionPrincipal actor, Long enrollmentId) {
        User user = accounts.activeAccount(actor);
        MentorshipEnrollment enrollment = enrollments.findById(enrollmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship enrollment", enrollmentId));
        boolean host = enrollment.getSlot().getMentorProfile().getUser().getUserId().equals(user.getUserId());
        boolean participant = enrollment.getMentee().getUserId().equals(user.getUserId());
        if (!host && !participant) {
            throw new ForbiddenException("Only the hosting mentor or enrolled person may view this enrollment.");
        }
        return mapEnrollment(enrollment, user.getUserId());
    }

    @Transactional(readOnly = true)
    public List<MentorshipEnrollmentResponse> getSlotEnrollments(SessionPrincipal actor, Long slotId) {
        User user = accounts.activeAccount(actor);
        MentorshipSlot slot = slots.findById(slotId)
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship slot", slotId));
        requireHost(slot, user);
        return enrollments.findBySlotSlotIdAndStatus(slotId, EnrollmentStatus.ACTIVE).stream()
                .map(enrollment -> mapEnrollment(enrollment, user.getUserId()))
                .toList();
    }

    private MentorProfile lockMentorForCreate(User user) {
        MentorProfile mentor = mentors.findLockedByUserId(user.getUserId())
                .orElseThrow(() -> new ForbiddenException("Only registered mentors can create mentorship slots."));
        if (mentor.getStatus() != MentorStatus.AVAILABLE) {
            throw conflict("MENTOR_UNAVAILABLE", "Mentor must be available to create mentorship slots.");
        }
        return mentor;
    }

    private void validateJoinState(MentorshipSlot slot, User applicant) {
        if (slot.getMentorProfile().getUser().getUserId().equals(applicant.getUserId())) {
            throw new ForbiddenException("Mentors cannot enroll in their own series.");
        }
        if (slot.getMentorProfile().getStatus() != MentorStatus.AVAILABLE) {
            throw conflict("MENTOR_UNAVAILABLE", "The mentor is not accepting new enrollments.");
        }
        if (!slot.isEnrollmentOpen() || slot.getStatus() == SlotStatus.CANCELLED) {
            throw conflict("ENROLLMENT_CLOSED", "Enrollment is closed for this series.");
        }
    }

    private void assertApplicantHasNoHostedConflicts(
            MentorProfile applicantMentor, List<MentorshipOccurrence> futureMeetings) {
        if (applicantMentor == null) {
            return;
        }
        for (MentorshipOccurrence meeting : futureMeetings) {
            if (!occurrences.findHostedConflicts(
                    applicantMentor.getId(), meeting.getStartsAt(), meeting.getEndsAt(), null).isEmpty()) {
                throw conflict("HOSTED_SCHEDULE_CONFLICT", "A future meeting overlaps a meeting you host.");
            }
        }
    }

    private List<MeetingWindow> replacementFutureSchedule(
            Long slotId, UpdateSlotRequest request, int requestedCount) {
        List<MeetingWindow> proposed = proposedSchedule(
                request.scheduleType(), request.startDate(), request.startTime(), request.endTime(),
                request.recurrenceEndDate(), requestedCount);
        LocalDateTime localNow = scheduleNow();
        List<MentorshipOccurrence> preserved = activeOccurrences(slotId).stream()
                .filter(occurrence -> !occurrence.getStartsAt().isAfter(localNow))
                .toList();
        Set<LocalDate> preservedDates = preserved.stream()
                .map(occurrence -> occurrence.getStartsAt().toLocalDate())
                .collect(java.util.stream.Collectors.toSet());
        int remaining = Math.max(0, requestedCount - preserved.size());
        List<MeetingWindow> future = proposed.stream()
                .filter(window -> window.startsAt().isAfter(localNow))
                .filter(window -> !preservedDates.contains(window.startsAt().toLocalDate()))
                .limit(remaining)
                .toList();
        if (future.isEmpty()) {
            throw bad("NO_FUTURE_MEETING", "The edited schedule must retain a meeting that has not started.");
        }
        if (future.size() < remaining) {
            throw bad("SERIES_BOUND_BEFORE_HISTORY",
                    "The requested bound does not provide enough future meetings after preserved history.");
        }
        return future;
    }

    private void reconcileFutureOccurrences(MentorshipSlot slot, List<MeetingWindow> desiredFuture) {
        LocalDateTime localNow = scheduleNow();
        List<MentorshipOccurrence> existingFuture = activeOccurrences(slot.getId()).stream()
                .filter(occurrence -> occurrence.getStartsAt().isAfter(localNow))
                .toList();
        Set<MeetingWindow> desired = new HashSet<>(desiredFuture);
        List<MentorshipOccurrence> obsolete = existingFuture.stream()
                .filter(occurrence -> !desired.contains(MeetingWindow.from(occurrence)))
                .toList();
        if (!obsolete.isEmpty()) {
            occurrences.deleteAll(obsolete);
            occurrences.flush();
        }
        Set<MeetingWindow> retained = existingFuture.stream()
                .filter(occurrence -> !obsolete.contains(occurrence))
                .map(MeetingWindow::from)
                .collect(java.util.stream.Collectors.toSet());
        List<MeetingWindow> missing = desiredFuture.stream()
                .filter(window -> !retained.contains(window))
                .toList();
        insertOccurrences(slot, missing);
    }

    private void assertNoHostedConflicts(
            Long mentorId, List<MeetingWindow> schedule, Long excludedSlotId) {
        for (MeetingWindow window : schedule) {
            if (!occurrences.findHostedConflicts(
                    mentorId, window.startsAt(), window.endsAt(), excludedSlotId).isEmpty()) {
                throw conflict("SLOT_SCHEDULE_CONFLICT",
                        "A meeting overlaps another series hosted by this mentor.");
            }
        }
    }

    private void insertOccurrences(MentorshipSlot slot, List<MeetingWindow> schedule) {
        if (schedule.isEmpty()) {
            return;
        }
        occurrences.saveAll(schedule.stream()
                .map(window -> new MentorshipOccurrence(slot, window.startsAt(), window.endsAt()))
                .toList());
        occurrences.flush();
    }

    private List<MeetingWindow> proposedSchedule(
            ScheduleType type, LocalDate startDate, LocalTime startTime, LocalTime endTime,
            LocalDate recurrenceEndDate, int meetingCount) {
        return recurrence.calculateOccurrences(type, startDate, recurrenceEndDate, meetingCount).stream()
                .map(date -> new MeetingWindow(date.atTime(startTime), date.atTime(endTime)))
                .toList();
    }

    private void validate(CreateSlotRequest request) {
        if (request == null || !validator.validate(request).isEmpty()) {
            throw bad("INVALID_SLOT_DATA", "Invalid mentorship slot data.");
        }
        validateSchedule(request.scheduleType(), request.startDate(), request.startTime(), request.endTime(),
                request.recurrenceEndDate(), request.meetingCount());
    }

    private void validate(UpdateSlotRequest request) {
        if (request == null || !validator.validate(request).isEmpty()) {
            throw bad("INVALID_SLOT_DATA", "Invalid mentorship slot data.");
        }
        validateSchedule(request.scheduleType(), request.startDate(), request.startTime(), request.endTime(),
                request.recurrenceEndDate(), request.meetingCount());
    }

    private void validateSchedule(
            ScheduleType type, LocalDate startDate, LocalTime startTime, LocalTime endTime,
            LocalDate recurrenceEndDate, Integer meetingCount) {
        if (!endTime.isAfter(startTime)) {
            throw bad("INVALID_SLOT_TIME", "End time must be after start time.");
        }
        if (recurrenceEndDate != null && recurrenceEndDate.isBefore(startDate)) {
            throw bad("INVALID_SLOT_DATE", "Recurrence end date must not precede start date.");
        }
        if (type == ScheduleType.ONE_TIME
                && (recurrenceEndDate != null || (meetingCount != null && meetingCount != 1))) {
            throw bad("INVALID_SERIES_BOUND", "A one-time schedule contains exactly one meeting.");
        }
        if (type != ScheduleType.ONE_TIME && recurrenceEndDate != null && meetingCount != null) {
            throw bad("AMBIGUOUS_SERIES_BOUND", "Use either recurrenceEndDate or meetingCount, not both.");
        }
    }

    private int resolvedCount(
            ScheduleType type, LocalDate startDate, LocalDate recurrenceEndDate, Integer requestedCount) {
        if (type == ScheduleType.ONE_TIME) {
            return 1;
        }
        int count = requestedCount != null
                ? requestedCount
                : recurrenceEndDate == null
                        ? MentorshipRecurrenceCalculator.DEFAULT_MAX_OCCURRENCES
                        : recurrence.calculateOccurrences(type, startDate, recurrenceEndDate,
                                MentorshipRecurrenceCalculator.MAX_OCCURRENCES).size();
        if (recurrenceEndDate != null) {
            int step = type == ScheduleType.BIWEEKLY ? 2 : 1;
            long possible = ChronoUnit.WEEKS.between(startDate, recurrenceEndDate) / step + 1;
            if (possible > MentorshipRecurrenceCalculator.MAX_OCCURRENCES) {
                throw bad("SERIES_TOO_LONG", "A series may contain at most 52 meetings.");
            }
        }
        return count;
    }

    private boolean scheduleChanged(MentorshipSlot slot, UpdateSlotRequest request, int count) {
        return slot.getScheduleType() != request.scheduleType()
                || !Objects.equals(slot.getStartDate(), request.startDate())
                || !Objects.equals(slot.getStartTime(), request.startTime())
                || !Objects.equals(slot.getEndTime(), request.endTime())
                || !Objects.equals(slot.getRecurrenceEndDate(), request.recurrenceEndDate())
                || !Objects.equals(slot.getMeetingCount(), count);
    }

    private boolean materiallyChanged(MentorshipSlot slot, UpdateSlotRequest request, int count) {
        return scheduleChanged(slot, request, count)
                || !Objects.equals(slot.getTopic(), request.topic().strip())
                || !Objects.equals(slot.getDescription(), request.description().strip())
                || slot.getMode() != request.mode()
                || !Objects.equals(slot.getLocation(), clean(request.location()))
                || !Objects.equals(slot.getMeetingLink(), clean(request.meetingLink()))
                || !Objects.equals(slot.getCapacity(), request.capacity());
    }

    private MentorshipSlotResponse mapSlot(MentorshipSlot slot, Long viewerId) {
        List<MentorshipOccurrence> all = occurrences.findBySlotSlotIdOrderByStartsAtAsc(slot.getId());
        List<MentorshipOccurrence> active = all.stream()
                .filter(occurrence -> !occurrence.isCancelled()).toList();
        int activeCount = (int) enrollments.countActiveBySlotId(slot.getId());
        return new MentorshipSlotResponse(
                slot.getId(), slot.getMentorProfile().getId(),
                slot.getMentorProfile().getUser().getUserId(),
                slot.getMentorProfile().getUser().getFullName(),
                slot.getTopic(), slot.getDescription(), slot.getScheduleType(), slot.getStartDate(),
                slot.getStartTime(), slot.getEndTime(), slot.getRecurrenceEndDate(), slot.getMode(),
                slot.getLocation(), maySeeSeriesLink(slot, viewerId) ? slot.getMeetingLink() : null,
                slot.getCapacity(), activeCount, effectiveStatus(slot, activeCount, active),
                all.stream().map(occurrence -> occurrence.getStartsAt().toLocalDate()).toList(),
                slot.getCreatedAt(), slot.getUpdatedAt(), slot.getMeetingCount(), slot.isEnrollmentOpen(),
                Math.max(0, slot.getCapacity() - activeCount), ongoingStart(active), nextStart(active),
                all.stream().map(this::mapOccurrence).toList());
    }

    private MentorshipSlotSummaryResponse mapSummary(MentorshipSlot slot, Long viewerId) {
        List<MentorshipOccurrence> meetings = activeOccurrences(slot.getId());
        int activeCount = (int) enrollments.countActiveBySlotId(slot.getId());
        return new MentorshipSlotSummaryResponse(
                slot.getId(), slot.getMentorProfile().getId(),
                slot.getMentorProfile().getUser().getUserId(),
                slot.getMentorProfile().getUser().getFullName(),
                slot.getTopic(), slot.getDescription(), slot.getScheduleType(), slot.getStartDate(),
                slot.getStartTime(), slot.getEndTime(), slot.getMode(), slot.getLocation(),
                maySeeSeriesLink(slot, viewerId) ? slot.getMeetingLink() : null,
                slot.getCapacity(), activeCount, effectiveStatus(slot, activeCount, meetings),
                slot.getRecurrenceEndDate(), slot.getMeetingCount(), slot.isEnrollmentOpen(),
                Math.max(0, slot.getCapacity() - activeCount), ongoingStart(meetings), nextStart(meetings),
                slot.getTopic());
    }

    private MentorshipEnrollmentResponse mapEnrollment(MentorshipEnrollment enrollment, Long viewerId) {
        MentorshipSlot slot = enrollment.getSlot();
        List<MentorshipOccurrence> meetings = activeOccurrences(slot.getId());
        EnrollmentStatus responseStatus = effectiveEnrollmentStatus(enrollment, meetings);
        boolean currentPeriod = enrollment.getStatus() == EnrollmentStatus.ACTIVE
                && responseStatus == EnrollmentStatus.ACTIVE;
        String meetingLink = currentPeriod && maySeeSeriesLink(slot, viewerId)
                ? slot.getMeetingLink()
                : null;
        return new MentorshipEnrollmentResponse(
                enrollment.getId(), slot.getId(), slot.getTopic(), enrollment.getMentee().getUserId(),
                enrollment.getMentee().getFullName(), enrollment.getJoinMessage(), enrollment.getLearningGoal(),
                responseStatus, enrollment.getJoinedAt(), enrollment.getLeftAt(),
                slot.getMentorProfile().getUser().getUserId(),
                slot.getMentorProfile().getUser().getFullName(), meetingLink,
                ongoingStart(meetings), nextStart(meetings));
    }

    private MentorshipOccurrenceResponse mapOccurrence(MentorshipOccurrence occurrence) {
        LocalDateTime now = scheduleNow();
        boolean active = !occurrence.isCancelled();
        return new MentorshipOccurrenceResponse(
                occurrence.getId(), occurrence.getStartsAt(), occurrence.getEndsAt(),
                occurrence.getCancelledAt(),
                active && !occurrence.getStartsAt().isAfter(now) && occurrence.getEndsAt().isAfter(now),
                active && occurrence.getStartsAt().isAfter(now));
    }

    private EnrollmentStatus effectiveEnrollmentStatus(
            MentorshipEnrollment enrollment, List<MentorshipOccurrence> meetings) {
        if (enrollment.getStatus() != EnrollmentStatus.ACTIVE) {
            return enrollment.getStatus();
        }
        boolean current = meetings.stream()
                .anyMatch(occurrence -> occurrence.getEndsAt().isAfter(scheduleNow()));
        return current ? EnrollmentStatus.ACTIVE : EnrollmentStatus.COMPLETED;
    }

    private SlotStatus effectiveStatus(
            MentorshipSlot slot, int activeCount, List<MentorshipOccurrence> meetings) {
        if (slot.getStatus() == SlotStatus.CANCELLED) {
            return SlotStatus.CANCELLED;
        }
        if (meetings.stream().noneMatch(meeting -> meeting.getEndsAt().isAfter(scheduleNow()))) {
            return SlotStatus.COMPLETED;
        }
        if (!slot.isEnrollmentOpen()) {
            return SlotStatus.CLOSED;
        }
        return activeCount >= slot.getCapacity() ? SlotStatus.FULL : SlotStatus.OPEN;
    }

    private boolean maySeeSeriesLink(MentorshipSlot slot, Long viewerId) {
        if (slot.getMentorProfile().getUser().getUserId().equals(viewerId)) {
            return true;
        }
        return hasCurrentParticipation(slot)
                && enrollments.existsBySlotSlotIdAndMenteeUserIdAndStatus(
                        slot.getId(), viewerId, EnrollmentStatus.ACTIVE);
    }

    private boolean hasCurrentParticipation(MentorshipSlot slot) {
        LocalDateTime now = scheduleNow();
        return activeOccurrences(slot.getId()).stream()
                .anyMatch(occurrence -> occurrence.getEndsAt().isAfter(now));
    }

    private LocalDateTime ongoingStart(List<MentorshipOccurrence> meetings) {
        LocalDateTime now = scheduleNow();
        return meetings.stream()
                .filter(meeting -> !meeting.getStartsAt().isAfter(now) && meeting.getEndsAt().isAfter(now))
                .map(MentorshipOccurrence::getStartsAt).findFirst().orElse(null);
    }

    private LocalDateTime nextStart(List<MentorshipOccurrence> meetings) {
        LocalDateTime now = scheduleNow();
        return meetings.stream().filter(meeting -> meeting.getStartsAt().isAfter(now))
                .map(MentorshipOccurrence::getStartsAt).findFirst().orElse(null);
    }

    private List<MentorshipOccurrence> activeOccurrences(Long slotId) {
        return occurrences.findBySlotSlotIdOrderByStartsAtAsc(slotId).stream()
                .filter(occurrence -> !occurrence.isCancelled()).toList();
    }

    private List<Long> activeMenteeIds(Long slotId) {
        return enrollments.findBySlotSlotIdAndStatus(slotId, EnrollmentStatus.ACTIVE).stream()
                .map(enrollment -> enrollment.getMentee().getUserId()).toList();
    }

    private MentorshipSlot lockedSlot(Long slotId) {
        return slots.findLockedById(slotId)
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship slot", slotId));
    }

    private MentorshipSlot visibleSlot(Long slotId) {
        return slots.findById(slotId)
                .filter(slot -> slot.getMentorProfile().getUser().canPerformProtectedAction())
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship slot", slotId));
    }

    private void requireHost(MentorshipSlot slot, User user) {
        if (!slot.getMentorProfile().getUser().getUserId().equals(user.getUserId())) {
            throw new ForbiddenException("Only the mentor hosting this series may perform this action.");
        }
    }

    private void requireEligible(User user) {
        boolean eligibleRole = user.getPlatformRole() == PlatformRole.STUDENT
                || user.getPlatformRole() == PlatformRole.ALUMNI;
        if (!user.canPerformProtectedAction() || !eligibleRole) {
            throw new ForbiddenException("Only active, non-anonymized students and alumni may enroll.");
        }
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.strip();
    }

    private BadRequestException bad(String code, String message) {
        return new BadRequestException(code, message);
    }

    private ConflictException conflict(String code, String message) {
        return new ConflictException(code, message);
    }

    private LocalDateTime nowUtc() {
        return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
    }

    private LocalDateTime scheduleNow() {
        return LocalDateTime.ofInstant(clock.instant(), SCHEDULE_ZONE);
    }

    private record MeetingWindow(LocalDateTime startsAt, LocalDateTime endsAt) {
        private static MeetingWindow from(MentorshipOccurrence occurrence) {
            return new MeetingWindow(occurrence.getStartsAt(), occurrence.getEndsAt());
        }
    }
}
