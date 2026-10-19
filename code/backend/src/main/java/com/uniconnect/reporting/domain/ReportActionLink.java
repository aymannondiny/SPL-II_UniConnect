package com.uniconnect.reporting.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import org.hibernate.annotations.Immutable;

@Entity @Immutable
@Table(name = "report_action_links")
public class ReportActionLink {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long linkId;
    @Column(nullable=false,updatable=false) private Long reportId;
    @Enumerated(EnumType.STRING) @Column(nullable=false,length=30,updatable=false) private ActionEvidenceSource evidenceSource;
    @Column(nullable=false,updatable=false) private Long evidenceId;
    @Column(nullable=false,length=50,updatable=false) private String actionType;
    @Column(nullable=false,length=30,updatable=false) private String subjectType;
    @Column(nullable=false,updatable=false) private Long subjectId;
    @Column(nullable=false,updatable=false) private LocalDateTime actionOccurredAt;
    @Column(nullable=false,updatable=false) private Long linkedBy;
    @Column(nullable=false,updatable=false) private LocalDateTime linkedAt;
    protected ReportActionLink() {}
    public ReportActionLink(long reportId, ActionEvidenceSource source, long evidenceId, String actionType,
            String subjectType, long subjectId, LocalDateTime actionOccurredAt, long linkedBy, LocalDateTime linkedAt) {
        this.reportId=reportId; evidenceSource=source; this.evidenceId=evidenceId; this.actionType=actionType;
        this.subjectType=subjectType; this.subjectId=subjectId; this.actionOccurredAt=actionOccurredAt;
        this.linkedBy=linkedBy; this.linkedAt=linkedAt;
    }
    public Long getId(){return linkId;} public ActionEvidenceSource getEvidenceSource(){return evidenceSource;}
    public Long getEvidenceId(){return evidenceId;} public String getActionType(){return actionType;}
    public String getSubjectType(){return subjectType;} public Long getSubjectId(){return subjectId;}
    public LocalDateTime getActionOccurredAt(){return actionOccurredAt;} public Long getLinkedBy(){return linkedBy;}
    public LocalDateTime getLinkedAt(){return linkedAt;}
}
