package com.uniconnect.mentorship.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.service.ProfileAccountService;
import com.uniconnect.mentorship.domain.*;
import com.uniconnect.mentorship.dto.*;
import com.uniconnect.mentorship.repository.MentorProfileRepository;
import com.uniconnect.mentorship.repository.MentorshipEnrollmentRepository;
import com.uniconnect.mentorship.repository.MentorshipSlotRepository;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.exception.ConflictException;
import com.uniconnect.shared.exception.ForbiddenException;
import com.uniconnect.shared.exception.ResourceNotFoundException;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import jakarta.validation.Validator;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;

@Service
@Transactional
public class MentorshipSlotService {

    private final MentorshipSlotRepository slotRepository;
    private final MentorshipEnrollmentRepository enrollmentRepository;
    private final MentorProfileRepository mentorProfiles;
    private final ProfileAccountService accounts;
    private final Validator validator;
    private final Clock clock;

    public MentorshipSlotService(
            MentorshipSlotRepository slotRepository,
            MentorshipEnrollmentRepository enrollmentRepository,
            MentorProfileRepository mentorProfiles,
            ProfileAccountService accounts,
            Validator validator,
            Clock clock
    ) {
        this.slotRepository = slotRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.mentorProfiles = mentorProfiles;
        this.accounts = accounts;
        this.validator = validator;
        this.clock = clock;
    }

    public MentorshipSlotResponse createSlot(SessionPrincipal actor, CreateSlotRequest request) {
        if (request == null || !validator.validate(request).isEmpty()) {
            throw new BadRequestException("INVALID_SLOT_DATA", "Invalid mentorship slot data.");
        }

        if (!request.endTime().isAfter(request.startTime())) {
            throw new BadRequestException("INVALID_SLOT_TIME", "End time must be after start time.");
        }

        if (request.recurrenceEndDate() != null && request.recurrenceEndDate().isBefore(request.startDate())) {
            throw new BadRequestException("INVALID_SLOT_DATE", "Recurrence end date must be on or after start date.");
        }

        User user = accounts.lockActiveAccount(actor);
        if (!user.canPerformProtectedAction()) {
            throw new ForbiddenException("Account cannot perform protected actions.");
        }

        MentorProfile mentorProfile = mentorProfiles.findByUserUserId(user.getUserId())
                .orElseThrow(() -> new ForbiddenException("Only registered mentors can create mentorship slots."));

        if (mentorProfile.getStatus() != MentorStatus.AVAILABLE) {
            throw new ConflictException("MENTOR_UNAVAILABLE", "Mentor must be available to create mentorship slots.");
        }

        List<MentorshipSlot> conflicts = slotRepository.findConflictingSlots(
                mentorProfile.getId(),
                request.startDate(),
                request.startTime(),
                request.endTime()
        );
        if (!conflicts.isEmpty()) {
            throw new ConflictException("SLOT_SCHEDULE_CONFLICT", "You already have a slot scheduled at this time.");
        }

        LocalDateTime now = now();
        MentorshipSlot slot = new MentorshipSlot(
                mentorProfile,
                request.topic().strip(),
                request.description().strip(),
                request.scheduleType(),
                request.startDate(),
                request.startTime(),
                request.endTime(),
                request.recurrenceEndDate(),
                request.mode(),
                request.location() != null ? request.location().strip() : null,
                request.meetingLink() != null ? request.meetingLink().strip() : null,
                request.capacity(),
                now
        );

        slot = slotRepository.saveAndFlush(slot);
        return toSlotResponse(slot);
    }

    public MentorshipSlotResponse getSlot(SessionPrincipal actor, Long slotId) {
        accounts.lockActiveAccount(actor);
        MentorshipSlot slot = slotRepository.findById(slotId)
                .filter(s -> s.getMentorProfile().getUser().canPerformProtectedAction())
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship slot", slotId));
        return toSlotResponse(slot);
    }

    public PageResponse<MentorshipSlotSummaryResponse> browseSlots(
            SessionPrincipal actor,
            String topic,
            SlotStatus status,
            int page,
            int size
    ) {
        accounts.lockActiveAccount(actor);
        PageValidation.check(page, size);

        Pageable pageable = PageRequest.of(page, size, Sort.by(
                Sort.Order.asc("startDate"),
                Sort.Order.asc("startTime"),
                Sort.Order.asc("slotId")
        ));

        List<SlotStatus> statuses = (status != null) ? List.of(status) : List.of(SlotStatus.OPEN, SlotStatus.FULL);
        Page<MentorshipSlot> resultPage;

        if (topic != null && !topic.isBlank()) {
            resultPage = slotRepository.findActiveSlotsByStatusInAndTopicContaining(statuses, topic.strip(), pageable);
        } else {
            resultPage = slotRepository.findActiveSlotsByStatusIn(statuses, pageable);
        }

        List<MentorshipSlotSummaryResponse> items = resultPage.getContent().stream()
                .map(this::toSlotSummaryResponse)
                .toList();

        return new PageResponse<>(items, page, size, resultPage.getTotalElements());
    }

    public MentorshipEnrollmentResponse joinSlot(SessionPrincipal actor, Long slotId, EnrollSlotRequest request) {
        User user = accounts.lockActiveAccount(actor);
        if (!user.canPerformProtectedAction()) {
            throw new ForbiddenException("Account cannot perform protected actions.");
        }

        MentorshipSlot slot = slotRepository.findById(slotId)
                .filter(s -> s.getMentorProfile().getUser().canPerformProtectedAction())
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship slot", slotId));

        if (slot.getMentorProfile().getUser().getUserId().equals(user.getUserId())) {
            throw new ForbiddenException("Mentors cannot enroll in their own slot.");
        }

        if (slot.getStatus() != SlotStatus.OPEN) {
            throw new ConflictException("SLOT_NOT_OPEN", "Slot is not currently open for enrollment.");
        }

        if (!slot.hasAvailableCapacity()) {
            throw new ConflictException("SLOT_CAPACITY_FULL", "Mentorship slot capacity has been reached.");
        }

        var existingOpt = enrollmentRepository.findBySlotSlotIdAndMenteeUserId(slotId, user.getUserId());
        if (existingOpt.isPresent() && existingOpt.get().getStatus() == EnrollmentStatus.ACTIVE) {
            throw new ConflictException("ALREADY_ENROLLED", "You are already enrolled in this slot.");
        }

        LocalDateTime now = now();
        MentorshipEnrollment enrollment;
        if (existingOpt.isPresent()) {
            enrollment = existingOpt.get();
            enrollment.reEnroll(
                    request != null && request.joinMessage() != null ? request.joinMessage().strip() : null,
                    request != null && request.learningGoal() != null ? request.learningGoal().strip() : null,
                    now
            );
        } else {
            enrollment = new MentorshipEnrollment(
                    slot,
                    user,
                    request != null && request.joinMessage() != null ? request.joinMessage().strip() : null,
                    request != null && request.learningGoal() != null ? request.learningGoal().strip() : null,
                    now
            );
        }

        slot.incrementMenteeCount(now);
        enrollment = enrollmentRepository.saveAndFlush(enrollment);
        return toEnrollmentResponse(enrollment);
    }

    public MentorshipEnrollmentResponse leaveSlot(SessionPrincipal actor, Long slotId) {
        User user = accounts.lockActiveAccount(actor);
        MentorshipSlot slot = slotRepository.findById(slotId)
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship slot", slotId));

        MentorshipEnrollment enrollment = enrollmentRepository.findBySlotSlotIdAndMenteeUserId(slotId, user.getUserId())
                .filter(e -> e.getStatus() == EnrollmentStatus.ACTIVE)
                .orElseThrow(() -> new ConflictException("NOT_ENROLLED", "You are not actively enrolled in this slot."));

        LocalDateTime now = now();
        enrollment.leave(now);
        slot.decrementMenteeCount(now);
        enrollment = enrollmentRepository.saveAndFlush(enrollment);
        return toEnrollmentResponse(enrollment);
    }

    public MentorshipSlotResponse updateSlot(SessionPrincipal actor, Long slotId, UpdateSlotRequest request) {
        if (request == null || !validator.validate(request).isEmpty()) {
            throw new BadRequestException("INVALID_SLOT_DATA", "Invalid mentorship slot data.");
        }

        if (!request.endTime().isAfter(request.startTime())) {
            throw new BadRequestException("INVALID_SLOT_TIME", "End time must be after start time.");
        }

        if (request.recurrenceEndDate() != null && request.recurrenceEndDate().isBefore(request.startDate())) {
            throw new BadRequestException("INVALID_SLOT_DATE", "Recurrence end date must be on or after start date.");
        }

        User user = accounts.lockActiveAccount(actor);
        MentorshipSlot slot = slotRepository.findById(slotId)
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship slot", slotId));

        if (!slot.getMentorProfile().getUser().getUserId().equals(user.getUserId())) {
            throw new ForbiddenException("Only the mentor who created this slot can update it.");
        }

        if (slot.getStatus() == SlotStatus.CANCELLED) {
            throw new ConflictException("SLOT_CANCELLED", "Cancelled slots cannot be updated.");
        }

        if (request.capacity() < slot.getCurrentMenteeCount()) {
            throw new BadRequestException("INVALID_CAPACITY", "Capacity cannot be less than current enrolled mentees (" + slot.getCurrentMenteeCount() + ").");
        }

        List<MentorshipSlot> conflicts = slotRepository.findConflictingSlots(
                slot.getMentorProfile().getId(),
                request.startDate(),
                request.startTime(),
                request.endTime()
        ).stream().filter(s -> !s.getId().equals(slotId)).toList();

        if (!conflicts.isEmpty()) {
            throw new ConflictException("SLOT_SCHEDULE_CONFLICT", "Schedule conflicts with another existing slot.");
        }

        LocalDateTime now = now();
        slot.updateDetails(
                request.topic().strip(),
                request.description().strip(),
                request.scheduleType(),
                request.startDate(),
                request.startTime(),
                request.endTime(),
                request.recurrenceEndDate(),
                request.mode(),
                request.location() != null ? request.location().strip() : null,
                request.meetingLink() != null ? request.meetingLink().strip() : null,
                request.capacity(),
                now
        );

        slotRepository.flush();
        return toSlotResponse(slot);
    }

    public MentorshipSlotResponse closeSlot(SessionPrincipal actor, Long slotId) {
        User user = accounts.lockActiveAccount(actor);
        MentorshipSlot slot = slotRepository.findById(slotId)
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship slot", slotId));

        if (!slot.getMentorProfile().getUser().getUserId().equals(user.getUserId())) {
            throw new ForbiddenException("Only the mentor who created this slot can close it.");
        }

        if (slot.getStatus() == SlotStatus.CANCELLED) {
            throw new ConflictException("SLOT_CANCELLED", "Cancelled slots cannot be closed.");
        }

        slot.close(now());
        slotRepository.flush();
        return toSlotResponse(slot);
    }

    public MentorshipSlotResponse cancelSlot(SessionPrincipal actor, Long slotId) {
        User user = accounts.lockActiveAccount(actor);
        MentorshipSlot slot = slotRepository.findById(slotId)
                .orElseThrow(() -> new ResourceNotFoundException("Mentorship slot", slotId));

        if (!slot.getMentorProfile().getUser().getUserId().equals(user.getUserId())) {
            throw new ForbiddenException("Only the mentor who created this slot can cancel it.");
        }

        LocalDateTime now = now();
        slot.cancel(now);
        List<MentorshipEnrollment> activeEnrollments = enrollmentRepository.findBySlotSlotIdAndStatus(slotId, EnrollmentStatus.ACTIVE);
        for (MentorshipEnrollment enrollment : activeEnrollments) {
            enrollment.cancel(now);
        }

        slotRepository.flush();
        return toSlotResponse(slot);
    }

    public List<MentorshipSlotResponse> getMyMentoringSlots(SessionPrincipal actor) {
        User user = accounts.lockActiveAccount(actor);
        return slotRepository.findByMentorProfileUserUserIdOrderByStartDateAscStartTimeAsc(user.getUserId())
                .stream()
                .map(this::toSlotResponse)
                .toList();
    }

    public List<MentorshipEnrollmentResponse> getMyEnrolledSlots(SessionPrincipal actor) {
        User user = accounts.lockActiveAccount(actor);
        return enrollmentRepository.findByMenteeUserIdAndStatusOrderByJoinedAtDesc(user.getUserId(), EnrollmentStatus.ACTIVE)
                .stream()
                .map(this::toEnrollmentResponse)
                .toList();
    }

    private MentorshipSlotResponse toSlotResponse(MentorshipSlot slot) {
        return new MentorshipSlotResponse(
                slot.getId(),
                slot.getMentorProfile().getId(),
                slot.getMentorProfile().getUser().getUserId(),
                slot.getMentorProfile().getUser().getFullName(),
                slot.getTopic(),
                slot.getDescription(),
                slot.getScheduleType(),
                slot.getStartDate(),
                slot.getStartTime(),
                slot.getEndTime(),
                slot.getRecurrenceEndDate(),
                slot.getMode(),
                slot.getLocation(),
                slot.getMeetingLink(),
                slot.getCapacity(),
                slot.getCurrentMenteeCount(),
                slot.getStatus(),
                slot.getCreatedAt(),
                slot.getUpdatedAt()
        );
    }

    private MentorshipSlotSummaryResponse toSlotSummaryResponse(MentorshipSlot slot) {
        return new MentorshipSlotSummaryResponse(
                slot.getId(),
                slot.getMentorProfile().getId(),
                slot.getMentorProfile().getUser().getUserId(),
                slot.getMentorProfile().getUser().getFullName(),
                slot.getTopic(),
                slot.getDescription(),
                slot.getScheduleType(),
                slot.getStartDate(),
                slot.getStartTime(),
                slot.getEndTime(),
                slot.getMode(),
                slot.getLocation(),
                slot.getMeetingLink(),
                slot.getCapacity(),
                slot.getCurrentMenteeCount(),
                slot.getStatus()
        );
    }

    private MentorshipEnrollmentResponse toEnrollmentResponse(MentorshipEnrollment enrollment) {
        return new MentorshipEnrollmentResponse(
                enrollment.getId(),
                enrollment.getSlot().getId(),
                enrollment.getSlot().getTopic(),
                enrollment.getMentee().getUserId(),
                enrollment.getMentee().getFullName(),
                enrollment.getJoinMessage(),
                enrollment.getLearningGoal(),
                enrollment.getStatus(),
                enrollment.getJoinedAt(),
                enrollment.getLeftAt()
        );
    }

    private LocalDateTime now() {
        return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
    }
}
