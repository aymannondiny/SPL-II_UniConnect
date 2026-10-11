package com.uniconnect.club.dto;
import com.uniconnect.club.domain.ClubRole;
import com.uniconnect.shared.security.ContextType;
public record ContextResponse(ContextType contextType, Long assignmentId, Long clubId, String clubName, ClubRole clubRole) {}
