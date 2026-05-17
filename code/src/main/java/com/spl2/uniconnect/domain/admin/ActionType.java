package com.spl2.uniconnect.domain.admin;

import lombok.Getter;

@Getter
public enum ActionType {
    WARN("Warning issued to user"),
    SUSPEND("User account suspended"),
    BAN("User account permanently banned"),
    DELETE_CONTENT("Content deleted by admin");

    private final String displayName;

    ActionType(String displayName) {
        this.displayName = displayName;
    }
}