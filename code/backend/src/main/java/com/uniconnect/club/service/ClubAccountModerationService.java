package com.uniconnect.club.service;

import com.uniconnect.club.domain.*;
import com.uniconnect.club.repository.ClubRepository;
import com.uniconnect.notification.service.ClubNotificationService;
import java.time.LocalDateTime;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Club-owned half of account suspension orchestration. */
@Service
public class ClubAccountModerationService {
    private final ClubRepository clubs;
    private final ClubNotificationService notifications;

    public ClubAccountModerationService(ClubRepository clubs, ClubNotificationService notifications) {
        this.clubs = clubs;
        this.notifications = notifications;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public List<Long> discover(long targetUserId) {
        return List.copyOf(clubs.administeredClubIds(targetUserId));
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void lockCandidates(Collection<Long> candidateIds) {
        for (long clubId : new TreeSet<>(candidateIds)) clubs.lock(clubId);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void requireNoAdditionalClub(long targetUserId, Collection<Long> lockedCandidates) {
        var locked = new HashSet<>(lockedCandidates);
        if (clubs.administeredClubIds(targetUserId).stream().anyMatch(id -> !locked.contains(id))) {
            throw new ClubAssignmentSetChangedException();
        }
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void suspendAdministeredClubs(long actorId, long targetUserId, Collection<Long> candidateIds,
            String reason, LocalDateTime now) {
        for (long clubId : new TreeSet<>(candidateIds)) {
            var club = clubs.find(clubId);
            var administrator = clubs.administrator(clubId).orElse(null);
            if (club == null || club.getStatus() == ClubStatus.REMOVED || administrator == null
                    || administrator.getUserId() != targetUserId) continue;
            if (club.getStatus() == ClubStatus.PUBLISHING_SUSPENDED) continue;
            club.suspendPublishing(now);
            var audit = clubs.insert(ClubAudit.lifecycle(clubId, actorId,
                    "CLUB_PUBLISHING_SUSPENDED", reason, ClubStatus.ACTIVE,
                    ClubStatus.PUBLISHING_SUSPENDED, now));
            notifications.publishingChanged(targetUserId, clubId, audit.getId(), false);
        }
    }
}
