package com.uniconnect.administration.service;

import com.uniconnect.administration.dto.AdministrationDashboardSummaryResponse;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.AccountAdministrationService;
import com.uniconnect.club.domain.ClubStatus;
import com.uniconnect.club.publication.repository.PublicationRepository;
import com.uniconnect.club.repository.ClubRepository;
import com.uniconnect.reporting.repository.ReportingRepository;
import com.uniconnect.shared.security.SessionPrincipal;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdministrationDashboardService {
    private final AccountAdministrationService accounts;
    private final UserRepository users;
    private final ClubRepository clubs;
    private final PublicationRepository publications;
    private final ReportingRepository reports;
    private final Clock clock;

    public AdministrationDashboardService(AccountAdministrationService accounts, UserRepository users,
            ClubRepository clubs, PublicationRepository publications, ReportingRepository reports, Clock clock) {
        this.accounts = accounts;
        this.users = users;
        this.clubs = clubs;
        this.publications = publications;
        this.reports = reports;
        this.clock = clock;
    }

    @Transactional
    public AdministrationDashboardSummaryResponse summary(SessionPrincipal actor) {
        accounts.requireAdministration(actor);
        LocalDateTime now = LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
        return new AdministrationDashboardSummaryResponse(
                users.countByAnonymizedAtIsNull(),
                clubs.countByStatus(ClubStatus.ACTIVE),
                publications.publishedCount(now),
                reports.openCount()
        );
    }
}
