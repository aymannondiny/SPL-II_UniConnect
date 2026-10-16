package com.uniconnect.club.publication.mapper;
import com.uniconnect.club.domain.Club;
import com.uniconnect.club.publication.domain.*;
import com.uniconnect.club.publication.dto.*;
import java.time.LocalDateTime;
import org.springframework.stereotype.Component;
@Component
public class PublicationMapper {
    public AnnouncementResponse announcement(Announcement a, Club c, LocalDateTime now) {
        return new AnnouncementResponse(a.getId(), c.getId(), c.getClubName(), c.getCategory(), a.getAuthorUserId(), a.getAuthorAssignmentId(),
                a.getTitle(), a.getContent(), a.getPriority(), a.statusAt(now), a.getCreatedAt(), a.getUpdatedAt(), a.getPublishedAt(), a.getExpiresAt(), a.getRemovedAt());
    }
    public EventResponse event(ClubEvent e, Club c, LocalDateTime now) {
        return new EventResponse(e.getId(), c.getId(), c.getClubName(), c.getCategory(), e.getAuthorUserId(), e.getAuthorAssignmentId(),
                e.getTitle(), e.getDescription(), e.getLocation(), e.getRegistrationUrl(), e.getRegistrationDeadline(), e.getStartsAt(), e.getEndsAt(),
                e.getStatus(), e.timingAt(now), e.getPublishedAt(), e.getUpdatedAt(), e.getRemovedAt());
    }
    public PublicationAuditResponse audit(PublicationAudit a) {
        return new PublicationAuditResponse(a.getId(), a.getAnnouncementId(), a.getEventId(), a.getActorUserId(), a.getActorAssignmentId(),
                a.getAction(), a.getReason(), a.getBeforeSnapshot(), a.getAfterSnapshot(), a.getCreatedAt());
    }
}
