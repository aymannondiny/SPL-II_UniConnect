package com.spl2.uniconnect.domain.career;

import lombok.Getter;

@Getter
public enum JobType {
    FULL_TIME("Full-time"),
    PART_TIME("Part-time"),
    INTERNSHIP("Internship"),
    CO_OP("Co-op");

    private final String displayName;

    JobType(String displayName) {
        this.displayName = displayName;
    }
}