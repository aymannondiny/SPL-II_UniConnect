package com.uniconnect.mentorship.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "mentorship_slots")
public class MentorshipSlot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "slot_id")
    private Long slotId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "mentor_profile_id", nullable = false)
    private MentorProfile mentorProfile;

    @Column(nullable = false, length = 200)
    private String topic;

    @Column(nullable = false, length = 2000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "schedule_type", nullable = false, length = 20)
    private ScheduleType scheduleType;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "recurrence_end_date")
    private LocalDate recurrenceEndDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SlotMode mode;

    @Column(length = 255)
    private String location;

    @Column(name = "meeting_link", length = 500)
    private String meetingLink;

    @Column(nullable = false)
    private Integer capacity;

    @Column(name = "current_mentee_count", nullable = false)
    private Integer currentMenteeCount = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SlotStatus status = SlotStatus.OPEN;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    protected MentorshipSlot() {}

    public MentorshipSlot(
            MentorProfile mentorProfile,
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
            LocalDateTime now
    ) {
        this.mentorProfile = mentorProfile;
        this.topic = topic;
        this.description = description;
        this.scheduleType = scheduleType;
        this.startDate = startDate;
        this.startTime = startTime;
        this.endTime = endTime;
        this.recurrenceEndDate = recurrenceEndDate;
        this.mode = mode;
        this.location = location;
        this.meetingLink = meetingLink;
        this.capacity = capacity;
        this.currentMenteeCount = 0;
        this.status = SlotStatus.OPEN;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public boolean hasAvailableCapacity() {
        return currentMenteeCount < capacity;
    }

    public void incrementMenteeCount(LocalDateTime now) {
        this.currentMenteeCount++;
        if (this.currentMenteeCount >= this.capacity) {
            this.status = SlotStatus.FULL;
        }
        this.updatedAt = now;
    }

    public void decrementMenteeCount(LocalDateTime now) {
        if (this.currentMenteeCount > 0) {
            this.currentMenteeCount--;
        }
        if (this.status == SlotStatus.FULL && this.currentMenteeCount < this.capacity) {
            this.status = SlotStatus.OPEN;
        }
        this.updatedAt = now;
    }

    public void updateDetails(
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
            Integer newCapacity,
            LocalDateTime now
    ) {
        this.topic = topic;
        this.description = description;
        this.scheduleType = scheduleType;
        this.startDate = startDate;
        this.startTime = startTime;
        this.endTime = endTime;
        this.recurrenceEndDate = recurrenceEndDate;
        this.mode = mode;
        this.location = location;
        this.meetingLink = meetingLink;
        if (newCapacity != null) {
            this.capacity = newCapacity;
            if (this.currentMenteeCount >= this.capacity) {
                this.status = SlotStatus.FULL;
            } else if (this.status == SlotStatus.FULL) {
                this.status = SlotStatus.OPEN;
            }
        }
        this.updatedAt = now;
    }

    public void close(LocalDateTime now) {
        this.status = SlotStatus.CLOSED;
        this.updatedAt = now;
    }

    public void cancel(LocalDateTime now) {
        this.status = SlotStatus.CANCELLED;
        this.updatedAt = now;
    }

    public Long getId() {
        return slotId;
    }

    public MentorProfile getMentorProfile() {
        return mentorProfile;
    }

    public String getTopic() {
        return topic;
    }

    public String getDescription() {
        return description;
    }

    public ScheduleType getScheduleType() {
        return scheduleType;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public LocalTime getStartTime() {
        return startTime;
    }

    public LocalTime getEndTime() {
        return endTime;
    }

    public LocalDate getRecurrenceEndDate() {
        return recurrenceEndDate;
    }

    public SlotMode getMode() {
        return mode;
    }

    public String getLocation() {
        return location;
    }

    public String getMeetingLink() {
        return meetingLink;
    }

    public Integer getCapacity() {
        return capacity;
    }

    public Integer getCurrentMenteeCount() {
        return currentMenteeCount;
    }

    public SlotStatus getStatus() {
        return status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
}
