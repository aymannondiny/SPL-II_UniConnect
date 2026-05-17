package com.spl2.uniconnect.domain.event;

import lombok.Getter;

@Getter
public enum AnnouncementPriority {
    NORMAL("Normal"),
    IMPORTANT("Important"),
    URGENT("Urgent");

    private final String displayName;

    AnnouncementPriority(String displayName) {
        this.displayName = displayName;
    }
}