package com.uniconnect.mentorship.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "mentorship_occurrences")
public class MentorshipOccurrence {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "occurrence_id")
    private Long occurrenceId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "slot_id", nullable = false)
    private MentorshipSlot slot;

    @Column(name = "starts_at", nullable = false)
    private LocalDateTime startsAt;

    @Column(name = "ends_at", nullable = false)
    private LocalDateTime endsAt;

    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;

    protected MentorshipOccurrence() {}

    public MentorshipOccurrence(MentorshipSlot slot, LocalDateTime startsAt, LocalDateTime endsAt) {
        this.slot = slot;
        this.startsAt = startsAt;
        this.endsAt = endsAt;
    }

    public void cancel(LocalDateTime nowUtc) { if (cancelledAt == null) cancelledAt = nowUtc; }
    public Long getId() { return occurrenceId; }
    public MentorshipSlot getSlot() { return slot; }
    public LocalDateTime getStartsAt() { return startsAt; }
    public LocalDateTime getEndsAt() { return endsAt; }
    public LocalDateTime getCancelledAt() { return cancelledAt; }
    public boolean isCancelled() { return cancelledAt != null; }
}
