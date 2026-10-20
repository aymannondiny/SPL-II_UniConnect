package com.uniconnect.club.domain;
public enum ClubStatus {
    ACTIVE, PUBLISHING_SUSPENDED, ARCHIVED, REMOVED;

    public boolean unavailableToMembers() {
        return this == ARCHIVED || this == REMOVED;
    }
}
