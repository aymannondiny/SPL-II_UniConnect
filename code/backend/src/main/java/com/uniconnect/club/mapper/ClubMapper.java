package com.uniconnect.club.mapper;
import com.uniconnect.club.domain.*;
import com.uniconnect.club.dto.*;
import org.springframework.stereotype.Component;
@Component
public class ClubMapper {
    public ClubResponse club(Club c) {
        return new ClubResponse(c.getId(), c.getClubName(), c.getCategory(), c.getDescription(), c.getLogoUrl(), c.getContactEmail(), c.getStatus(), c.getCreatedAt(), c.getUpdatedAt());
    }
    public AssignmentResponse assignment(ClubRoleAssignment a, String name) {
        return new AssignmentResponse(a.getId(), a.getClubId(), a.getUserId(), name, a.getRole(), a.isCurrent(), a.getAssignedBy(), a.getAssignedAt(), a.getRevokedBy(), a.getRevokedAt());
    }
    public ClubAuditResponse audit(ClubAudit a) {
        return new ClubAuditResponse(a.getId(), a.getClubId(), a.getActorId(), a.getActorAssignmentId(), a.getTargetAssignmentId(), a.getAction(), a.getReason(), a.getCreatedAt());
    }
}
