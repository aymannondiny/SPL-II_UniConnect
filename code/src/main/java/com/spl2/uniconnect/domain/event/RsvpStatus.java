package com.spl2.uniconnect.domain.event;

import lombok.Getter;

@Getter
public enum RsvpStatus {
    GOING("Going"),
    INTERESTED("Interested"),
    NOT_GOING("Not Going");

    private final String displayName;

    RsvpStatus(String displayName) {
        this.displayName = displayName;
    }
}