package com.spl2.uniconnect.domain.event;

import lombok.Getter;

@Getter
public enum EventCategory {
    ACADEMIC("Academic"),
    CULTURAL("Cultural"),
    SPORTS("Sports"),
    TECH("Tech"),
    WORKSHOP("Workshop"),
    SOCIAL("Social"),
    OTHER("Other");

    private final String displayName;

    EventCategory(String displayName) {
        this.displayName = displayName;
    }
}