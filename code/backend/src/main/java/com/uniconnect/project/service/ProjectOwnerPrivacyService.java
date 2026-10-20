package com.uniconnect.project.service;

import com.uniconnect.notification.service.ProjectNotificationService;
import com.uniconnect.project.domain.*;
import com.uniconnect.project.repository.*;
import java.time.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Project-owned hook for a future account-anonymization transaction. The caller locks the account first. */
@Service
public class ProjectOwnerPrivacyService {
    private final ProjectRepository projects;
    private final ProjectApplicationRepository applications;
    private final ProjectAuditRepository audits;
    private final ProjectNotificationService notifications;
    private final Clock clock;

    public ProjectOwnerPrivacyService(ProjectRepository projects, ProjectApplicationRepository applications,
            ProjectAuditRepository audits, ProjectNotificationService notifications, Clock clock) {
        this.projects = projects; this.applications = applications; this.audits = audits;
        this.notifications = notifications; this.clock = clock;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void redactOwner(long ownerUserId) {
        LocalDateTime now = LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
        for (Project project : projects.lockAllByCreator(ownerUserId)) {
            if (project.getCreatorRedactedAt() != null) continue;
            if (project.getStatus() != ProjectStatus.DELETED) {
                for (var application : applications.lockByProjectAndStatus(project.getProjectId(),
                        ProjectApplicationStatus.PENDING)) {
                    application.cancel(now);
                    audits.save(new ProjectAudit(project.getProjectId(), ownerUserId, application.getApplicationId(),
                            ProjectAuditEvent.APPLICATION_CANCELLED, now));
                    notifications.projectDeleted(application.getApplicantUserId(), project.getProjectId(),
                            application.getApplicationId(), now);
                }
            }
            project.redactCreator(now);
            audits.save(new ProjectAudit(project.getProjectId(), ownerUserId, null,
                    ProjectAuditEvent.OWNER_ANONYMIZED, now));
        }
        applications.flush(); projects.flush(); audits.flush();
    }
}
