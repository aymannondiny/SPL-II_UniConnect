package com.spl2.uniconnect.domain.notification;

import lombok.Getter;

@Getter
public enum NotificationType {
    // Connection notifications
    CONNECTION_REQUEST("Someone sent you a connection request"),
    CONNECTION_ACCEPTED("Your connection request was accepted"),
    CONNECTION_REJECTED("Your connection request was rejected"),  // ✅ ADD THIS

    // Project notifications
    PROJECT_APPLICATION("Someone applied to your project"),
    PROJECT_APPLICATION_ACCEPTED("Your project application was accepted"),
    PROJECT_APPLICATION_REJECTED("Your project application was rejected"),

    // Mentorship notifications
    MENTORSHIP_ENROLLMENT("Someone enrolled in your mentorship slot"),
    MENTORSHIP_SLOT_FULL("Your mentorship slot is now full"),
    MENTORSHIP_SLOT_CLOSED("A mentorship slot you joined has been closed"),

    // Chat notifications
    NEW_MESSAGE("You have a new message"),

    // Event notifications
    EVENT_REMINDER("Upcoming event reminder"),
    EVENT_CANCELLED("An event you RSVP'd to has been cancelled"),

    // Career notifications
    NEW_JOB_POSTING("A new job matching your skills was posted"),

    // Announcement notifications
    NEW_ANNOUNCEMENT("A new announcement has been posted"),

    // Admin notifications
    ACCOUNT_WARNING("Your account has received a warning"),
    ACCOUNT_SUSPENDED("Your account has been suspended"),
    CONTENT_REMOVED("Your content has been removed");

    private final String defaultMessage;

    NotificationType(String defaultMessage) {
        this.defaultMessage = defaultMessage;
    }
}