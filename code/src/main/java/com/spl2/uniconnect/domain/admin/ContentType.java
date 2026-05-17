package com.spl2.uniconnect.domain.admin;

import lombok.Getter;

@Getter
public enum ContentType {
    USER("User profile"),
    PROJECT("Project"),
    EVENT("Event"),
    MESSAGE("Message"),
    JOB("Job posting"),
    ANNOUNCEMENT("Announcement");

    private final String displayName;

    ContentType(String displayName) {
        this.displayName = displayName;
    }
}