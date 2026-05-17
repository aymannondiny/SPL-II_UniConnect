package com.spl2.uniconnect.domain.admin;

import lombok.Getter;

@Getter
public enum ReportStatus {
    PENDING("Pending"),
    UNDER_REVIEW("Under Review"),
    RESOLVED("Resolved"),
    DISMISSED("Dismissed");

    private final String displayName;

    ReportStatus(String displayName) {
        this.displayName = displayName;
    }
}