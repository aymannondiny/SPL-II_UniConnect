package com.spl2.uniconnect.domain.event;

import com.spl2.uniconnect.domain.user.User;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "events", indexes = {
        @Index(name = "idx_event_creator", columnList = "creator_id"),
        @Index(name = "idx_event_category", columnList = "category"),
        @Index(name = "idx_event_date", columnList = "event_date")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "event_id")
    private Long eventId;

    @NotNull(message = "Event creator is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id", nullable = false)
    private User creator;

    @NotBlank(message = "Event title is required")
    @Size(max = 255, message = "Title cannot exceed 255 characters")
    @Column(name = "title", nullable = false)
    private String title;

    @NotNull(message = "Event category is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 50)
    private EventCategory category;

    @NotBlank(message = "Event description is required")
    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    @NotNull(message = "Event date is required")
    @Column(name = "event_date", nullable = false)
    private LocalDate eventDate;

    @NotNull(message = "Event time is required")
    @Column(name = "event_time", nullable = false)
    private LocalTime eventTime;

    @NotBlank(message = "Event location is required")
    @Size(max = 255, message = "Location cannot exceed 255 characters")
    @Column(name = "location", nullable = false)
    private String location;

    @Size(max = 500, message = "Meeting link cannot exceed 500 characters")
    @Column(name = "meeting_link", length = 500)
    private String meetingLink;

    @Min(value = 1, message = "Maximum attendees must be at least 1")
    @Column(name = "max_attendees")
    private Integer maxAttendees;

    @Column(name = "rsvp_required", nullable = false)
    @Builder.Default
    private Boolean rsvpRequired = false;

    @Size(max = 500, message = "Poster image URL cannot exceed 500 characters")
    @Column(name = "poster_image", length = 500)
    private String posterImage;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Relationships
    @OneToMany(mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private Set<EventRsvp> rsvps = new HashSet<>();

    // Helper methods
    public void addRsvp(EventRsvp rsvp) {
        rsvps.add(rsvp);
        rsvp.setEvent(this);
    }

    public void removeRsvp(EventRsvp rsvp) {
        rsvps.remove(rsvp);
        rsvp.setEvent(null);
    }

    public long getGoingCount() {
        return rsvps.stream()
                .filter(r -> r.getStatus() == RsvpStatus.GOING)
                .count();
    }

    public boolean isAtCapacity() {
        return maxAttendees != null && getGoingCount() >= maxAttendees;
    }
}
