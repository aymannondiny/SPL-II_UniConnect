package com.uniconnect.reporting;

import com.uniconnect.administration.dto.AccountModerationRequest;
import com.uniconnect.administration.service.AccountModerationService;
import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.career.domain.EmploymentType;
import com.uniconnect.career.domain.WorkMode;
import com.uniconnect.career.dto.*;
import com.uniconnect.career.service.CareerBoardService;
import com.uniconnect.club.dto.SelectContextRequest;
import com.uniconnect.club.service.ClubContextService;
import com.uniconnect.project.dto.*;
import com.uniconnect.project.service.ProjectTeammateService;
import com.uniconnect.reporting.domain.*;
import com.uniconnect.reporting.dto.*;
import com.uniconnect.reporting.service.ReportReviewService;
import com.uniconnect.reporting.service.ReportingService;
import com.uniconnect.shared.exception.ConflictException;
import com.uniconnect.shared.exception.ResourceNotFoundException;
import com.uniconnect.shared.security.ContextType;
import com.uniconnect.shared.security.PlatformRole;
import com.uniconnect.shared.security.SessionPrincipal;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties={
        "spring.datasource.url=${content.reporting.integration.url:jdbc:h2:mem:project_career_reporting;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE}",
        "spring.datasource.driver-class-name=${content.reporting.integration.driver:org.h2.Driver}",
        "spring.datasource.username=${content.reporting.integration.username:sa}",
        "spring.datasource.password=${content.reporting.integration.password:}"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(ProjectCareerReportingIntegrationTests.ClockConfiguration.class)
class ProjectCareerReportingIntegrationTests {
    private static final Instant NOW=Instant.parse("2026-10-19T06:00:00Z");
    private static final LocalDate FUTURE=LocalDate.of(2026,11,15);

    @Autowired ReportingService reporting;
    @Autowired ReportReviewService review;
    @Autowired ProjectTeammateService projects;
    @Autowired CareerBoardService careers;
    @Autowired AccountModerationService moderation;
    @Autowired ClubContextService contexts;
    @Autowired SessionService sessions;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired MutableClock clock;

    private Access system;
    private Access secondSystem;
    private Access reporter;
    private Access savedStudent;
    private Access projectOwner;
    private Access careerAuthor;
    private Access otherOwner;
    private Access alumniViewer;
    private long projectId;
    private long careerId;

    @BeforeEach
    void setup() {
        clean();
        clock.set(NOW);
        system=account("Reporting System",PlatformRole.SYSTEM_ADMIN);
        secondSystem=account("Second System",PlatformRole.SYSTEM_ADMIN);
        reporter=account("Project Reporter",PlatformRole.STUDENT);
        savedStudent=account("Saved Student",PlatformRole.STUDENT);
        projectOwner=account("Project Owner",PlatformRole.STUDENT);
        careerAuthor=account("Career Author",PlatformRole.ALUMNI);
        otherOwner=account("Other Owner",PlatformRole.STUDENT);
        alumniViewer=account("Alumni Viewer",PlatformRole.ALUMNI);
        contexts.select(system.principal(),new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION,null));
        contexts.select(secondSystem.principal(),new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION,null));
        projectId=projects.create(projectOwner.principal(),projectRequest("Original project","Original project body",FUTURE)).id();
        careerId=careers.create(careerAuthor.principal(),careerRequest("Original career post","Original career body",FUTURE)).id();
    }

    @AfterEach
    void clean() {
        for(String table:List.of("report_action_links","report_audit_logs","content_reports",
                "teammate_project_audits","teammate_project_applications","teammate_project_memberships","teammate_project_skills","teammate_projects",
                "career_saved_jobs","career_job_skills","career_job_posts","audit_logs","moderation_actions","notifications",
                "authenticated_sessions","club_audit","club_role_assignments","clubs","skills","email_verification_tokens",
                "password_reset_tokens","users")) {
            try { jdbc.update("delete from "+table); } catch(RuntimeException ignored) {}
        }
    }

    @Test
    void activeTargetsAllowEveryActiveRoleSelfReportsAndSafeSnapshots() throws Exception {
        var project=reporting.submit(alumniViewer.principal(),submit(ReportTargetType.PROJECT,projectId));
        var career=reporting.submit(system.principal(),submit(ReportTargetType.CAREER_POST,careerId));
        assertThat(reporting.submit(projectOwner.principal(),submit(ReportTargetType.PROJECT,projectId)).targetId()).isEqualTo(projectId);
        assertThat(reporting.submit(careerAuthor.principal(),submit(ReportTargetType.CAREER_POST,careerId)).targetId()).isEqualTo(careerId);

        careers.save(reporter.principal(),careerId,new SaveJobRequest("PRIVATE SAVED NOTE"));
        var savedReport=reporting.submit(reporter.principal(),submit(ReportTargetType.CAREER_POST,careerId));
        var projectAdmin=review.get(system.principal(),project.id());
        var careerAdmin=review.get(system.principal(),savedReport.id());
        assertThat(projectAdmin.targetOwnerUserId()).isEqualTo(projectOwner.principal().userId());
        assertThat(projectAdmin.parentClubId()).isNull();
        assertThat(projectAdmin.targetSnapshot()).contains("Original project body","applicationDeadline")
                .doesNotContain("membershipId","memberUserId","applicationStatus","recommendation","score");
        assertThat(careerAdmin.targetOwnerUserId()).isEqualTo(careerAuthor.principal().userId());
        assertThat(careerAdmin.parentClubId()).isNull();
        assertThat(careerAdmin.targetSnapshot()).contains("Original career body","applicationEmail")
                .doesNotContain("PRIVATE SAVED NOTE","savedJobId","\"saved\"","\"canApply\"");
        mvc.perform(get("/api/v1/reports/"+project.id()).header("Authorization","Bearer "+alumniViewer.token()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.targetSnapshot").doesNotExist())
                .andExpect(jsonPath("$.internalNotes").doesNotExist()).andExpect(jsonPath("$.action").doesNotExist());
        assertThat(career.targetType()).isEqualTo(ReportTargetType.CAREER_POST);
    }

    @Test
    void retainedClosedAndExpiredTargetsRemainReportableOnlyWhenDetailIsAccessible() {
        projects.close(projectOwner.principal(),projectId);
        assertThat(reporting.submit(alumniViewer.principal(),submit(ReportTargetType.PROJECT,projectId)).targetId()).isEqualTo(projectId);
        long expiringProject=projects.create(projectOwner.principal(),projectRequest("Expiring project","Expires",LocalDate.of(2026,10,19))).id();
        long expiringCareer=careers.create(careerAuthor.principal(),careerRequest("Expiring career","Expires",LocalDate.of(2026,10,19))).id();
        careers.save(savedStudent.principal(),expiringCareer,new SaveJobRequest(null));
        careers.close(careerAuthor.principal(),careerId);
        assertThat(reporting.submit(careerAuthor.principal(),submit(ReportTargetType.CAREER_POST,careerId)).targetId()).isEqualTo(careerId);
        assertThatThrownBy(()->reporting.submit(reporter.principal(),submit(ReportTargetType.CAREER_POST,careerId)))
                .isInstanceOf(ResourceNotFoundException.class);
        long deleted=projects.create(projectOwner.principal(),projectRequest("Deleted project","Delete me",FUTURE)).id();
        projects.delete(projectOwner.principal(),deleted);
        clock.set(NOW.plus(Duration.ofDays(1)));
        var freshAlumni=login("alumni.viewer@iut-dhaka.edu");
        var freshSavedStudent=login("saved.student@iut-dhaka.edu");
        var freshReporter=login("project.reporter@iut-dhaka.edu");
        var freshCareerAuthor=login("career.author@iut-dhaka.edu");
        assertThat(reporting.submit(freshAlumni.principal(),submit(ReportTargetType.PROJECT,expiringProject)).targetId()).isEqualTo(expiringProject);
        assertThat(reporting.submit(freshSavedStudent.principal(),submit(ReportTargetType.CAREER_POST,expiringCareer)).targetId()).isEqualTo(expiringCareer);

        assertThatThrownBy(()->reporting.submit(freshReporter.principal(),submit(ReportTargetType.PROJECT,deleted)))
                .isInstanceOf(ResourceNotFoundException.class);
        jdbc.update("update career_job_posts set status='REMOVED',removed_at=current_timestamp where job_post_id=?",careerId);
        assertThatThrownBy(()->reporting.submit(freshCareerAuthor.principal(),submit(ReportTargetType.CAREER_POST,careerId)))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(()->reporting.submit(freshReporter.principal(),submit(ReportTargetType.PROJECT,999999)))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(()->reporting.submit(freshReporter.principal(),submit(ReportTargetType.CAREER_POST,999999)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void duplicateOpenReportsAreSerializedForBothTargets() throws Exception {
        assertOneConcurrentDuplicate(ReportTargetType.PROJECT,projectId);
        assertOneConcurrentDuplicate(ReportTargetType.CAREER_POST,careerId);
        assertThat(jdbc.queryForObject("select count(*) from content_reports",Integer.class)).isEqualTo(2);
        assertThat(jdbc.queryForObject("select count(*) from report_audit_logs",Integer.class)).isEqualTo(2);
    }

    @Test
    void snapshotsSurviveProjectDeletionAndCareerEditWhileResolutionRetriesStayOnceOnly() {
        var projectReport=reporting.submit(reporter.principal(),submit(ReportTargetType.PROJECT,projectId));
        var careerReport=reporting.submit(reporter.principal(),submit(ReportTargetType.CAREER_POST,careerId));
        projects.update(projectOwner.principal(),projectId,projectRequest("Changed project","Changed project body",FUTURE));
        projects.delete(projectOwner.principal(),projectId);
        careers.update(careerAuthor.principal(),careerId,careerRequest("Changed career","Changed career body",FUTURE));
        careers.close(careerAuthor.principal(),careerId);
        assertThat(review.get(system.principal(),projectReport.id()).targetSnapshot())
                .contains("Original project body").doesNotContain("Changed project body");
        assertThat(review.get(system.principal(),careerReport.id()).targetSnapshot())
                .contains("Original career body").doesNotContain("Changed career body");

        review.review(system.principal(),projectReport.id());
        var noAction=noAction();
        review.resolve(system.principal(),projectReport.id(),noAction);
        review.resolve(system.principal(),projectReport.id(),noAction);
        assertThat(countFor("report_audit_logs",projectReport.id())).isEqualTo(3);
        assertThat(countNotification(projectReport.id())).isOne();

        review.review(system.principal(),careerReport.id());
        clock.set(NOW.plusSeconds(1));
        moderation.suspend(system.principal(),careerAuthor.principal().userId(),new AccountModerationRequest("Reported career content",true));
        long actionId=latestAction();
        var taken=action(ActionEvidenceSource.ACCOUNT_MODERATION,actionId);
        assertThat(review.resolve(system.principal(),careerReport.id(),taken).action().subjectId())
                .isEqualTo(careerAuthor.principal().userId());
        review.resolve(system.principal(),careerReport.id(),taken);
        assertThat(countFor("report_audit_logs",careerReport.id())).isEqualTo(3);
        assertThat(countFor("report_action_links",careerReport.id())).isOne();
        assertThat(countNotification(careerReport.id())).isOne();
    }

    @Test
    void projectAndCareerAcceptOnlyUnreversedPostSubmissionOwnerSuspensions() {
        var wrongOwnerReport=reviewed(reporter,ReportTargetType.PROJECT,projectId);
        clock.set(NOW.plusSeconds(1));
        moderation.suspend(system.principal(),otherOwner.principal().userId(),new AccountModerationRequest("Unrelated account",true));
        assertInvalidEvidence(wrongOwnerReport.id(),ActionEvidenceSource.ACCOUNT_MODERATION,latestAction());

        var temporalReportOwner=projectOwner;
        clock.set(NOW.plusSeconds(2));
        moderation.suspend(system.principal(),temporalReportOwner.principal().userId(),new AccountModerationRequest("Earlier owner action",true));
        long earlierSuspension=latestAction();
        clock.set(NOW.plusSeconds(3));
        var temporalReport=reviewed(alumniViewer,ReportTargetType.PROJECT,projectId);
        assertInvalidEvidence(temporalReport.id(),ActionEvidenceSource.ACCOUNT_MODERATION,earlierSuspension);

        var careerReport=reviewed(savedStudent,ReportTargetType.CAREER_POST,careerId);
        assertInvalidEvidence(careerReport.id(),ActionEvidenceSource.CLUB_LIFECYCLE,1);
        clock.set(NOW.plusSeconds(4));
        moderation.suspend(system.principal(),careerAuthor.principal().userId(),new AccountModerationRequest("Career owner action",true));
        long suspension=latestAction();
        clock.set(NOW.plusSeconds(5));
        moderation.restore(system.principal(),careerAuthor.principal().userId(),new AccountModerationRequest("Reversed",true));
        long reactivation=latestAction();
        assertInvalidEvidence(careerReport.id(),ActionEvidenceSource.ACCOUNT_MODERATION,suspension);
        assertInvalidEvidence(careerReport.id(),ActionEvidenceSource.ACCOUNT_MODERATION,reactivation);
        assertThat(review.get(system.principal(),careerReport.id()).status()).isEqualTo(ReportStatus.UNDER_REVIEW);
        assertThat(countFor("report_action_links",careerReport.id())).isZero();
    }

    @Test
    void reversalAndLinkingSerializeForBothNewTargets() throws Exception {
        var projectReport=reviewed(reporter,ReportTargetType.PROJECT,projectId);
        clock.set(NOW.plusSeconds(1));
        moderation.suspend(system.principal(),projectOwner.principal().userId(),new AccountModerationRequest("Project owner suspension",true));
        assertConsistentRace(projectReport.id(),projectOwner.principal().userId(),latestAction());

        var careerReport=reviewed(reporter,ReportTargetType.CAREER_POST,careerId);
        clock.set(NOW.plusSeconds(2));
        moderation.suspend(system.principal(),careerAuthor.principal().userId(),new AccountModerationRequest("Career owner suspension",true));
        assertConsistentRace(careerReport.id(),careerAuthor.principal().userId(),latestAction());
    }

    @Test
    void failedActionResolutionRollsBackProjectAndCareerState() {
        var projectReport=reviewed(reporter,ReportTargetType.PROJECT,projectId);
        clock.set(NOW.plusSeconds(1));
        moderation.suspend(system.principal(),projectOwner.principal().userId(),new AccountModerationRequest("Project owner suspension",true));
        assertResolutionRollback(projectReport.id(),latestAction());

        var careerReport=reviewed(reporter,ReportTargetType.CAREER_POST,careerId);
        clock.set(NOW.plusSeconds(2));
        moderation.suspend(system.principal(),careerAuthor.principal().userId(),new AccountModerationRequest("Career owner suspension",true));
        assertResolutionRollback(careerReport.id(),latestAction());
    }

    private void assertOneConcurrentDuplicate(ReportTargetType type,long id)throws Exception{
        var gate=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)){
            Callable<Long> submit=()->{gate.await();try{return reporting.submit(reporter.principal(),submit(type,id)).id();}
                catch(ConflictException duplicate){assertThat(duplicate.code()).isEqualTo("DUPLICATE_OPEN_REPORT");return -1L;}};
            var first=pool.submit(submit);var second=pool.submit(submit);gate.countDown();
            assertThat(List.of(first.get(10,TimeUnit.SECONDS),second.get(10,TimeUnit.SECONDS)))
                    .contains(-1L).anyMatch(value->value>0);
        }
    }

    private ReportResponse reviewed(Access actor,ReportTargetType type,long id){
        var report=reporting.submit(actor.principal(),submit(type,id));
        review.review(system.principal(),report.id());
        return report;
    }

    private void assertInvalidEvidence(long reportId,ActionEvidenceSource source,long evidenceId){
        assertThatThrownBy(()->review.resolve(system.principal(),reportId,action(source,evidenceId)))
                .isInstanceOf(ConflictException.class)
                .extracting(error->((ConflictException)error).code()).isEqualTo("INVALID_ACTION_EVIDENCE");
    }

    private void assertConsistentRace(long reportId,long ownerId,long actionId)throws Exception{
        var gate=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)){
            var resolve=pool.submit(()->{gate.await();try{review.resolve(system.principal(),reportId,
                    action(ActionEvidenceSource.ACCOUNT_MODERATION,actionId));return "RESOLVED";}
                catch(ConflictException rejected){return "REJECTED";}});
            var reverse=pool.submit(()->{gate.await();moderation.restore(system.principal(),ownerId,
                    new AccountModerationRequest("Concurrent reversal",true));return "REVERSED";});
            gate.countDown();String outcome=resolve.get(10,TimeUnit.SECONDS);
            assertThat(reverse.get(10,TimeUnit.SECONDS)).isEqualTo("REVERSED");
            var report=review.get(system.principal(),reportId);
            if(outcome.equals("RESOLVED")){
                assertThat(report.status()).isEqualTo(ReportStatus.ACTION_TAKEN);
                assertThat(report.action()).isNotNull();
                assertThat(countFor("report_action_links",reportId)).isOne();
            }else{
                assertThat(report.status()).isEqualTo(ReportStatus.UNDER_REVIEW);
                assertThat(report.action()).isNull();
                assertThat(countFor("report_action_links",reportId)).isZero();
            }
        }
    }

    private void assertResolutionRollback(long reportId,long actionId){
        jdbc.update("insert into notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) values (?,?,?,?,?,?,?,?)",
                reporter.principal().userId(),"REPORT_RESOLVED","Seed","Seed","REPORT",reportId,"report-resolution:"+reportId,
                LocalDateTime.ofInstant(clock.instant(),ZoneOffset.UTC));
        assertThatThrownBy(()->review.resolve(system.principal(),reportId,
                action(ActionEvidenceSource.ACCOUNT_MODERATION,actionId))).isInstanceOf(RuntimeException.class);
        assertThat(review.get(system.principal(),reportId).status()).isEqualTo(ReportStatus.UNDER_REVIEW);
        assertThat(countFor("report_action_links",reportId)).isZero();
        assertThat(countFor("report_audit_logs",reportId)).isEqualTo(2);
    }

    private int countFor(String table,long reportId){
        return jdbc.queryForObject("select count(*) from "+table+" where report_id=?",Integer.class,reportId);
    }
    private int countNotification(long reportId){
        return jdbc.queryForObject("select count(*) from notifications where type='REPORT_RESOLVED' and reference_id=?",Integer.class,reportId);
    }
    private long latestAction(){return jdbc.queryForObject("select max(action_id) from moderation_actions",Long.class);}
    private SubmitReportRequest submit(ReportTargetType type,long id){return new SubmitReportRequest(type,id,"Policy concern");}
    private ResolveReportRequest noAction(){return new ResolveReportRequest(ReportStatus.NO_ACTION,"Reviewed; no action required.","Internal note",null);}
    private ResolveReportRequest action(ActionEvidenceSource source,long id){return new ResolveReportRequest(ReportStatus.ACTION_TAKEN,
            "Reviewed and action confirmed.","Verified retained evidence",new ActionEvidenceRequest(source,id));}
    private ProjectRequest projectRequest(String title,String body,LocalDate deadline){return new ProjectRequest(title,body,4,"One semester","CSE 400",
            deadline,List.of(new ProjectSkillRequest("java",true),new ProjectSkillRequest("git",false)));}
    private CareerPostRequest careerRequest(String title,String body,LocalDate deadline){return new CareerPostRequest(title,"Example Ltd",body,
            "Java experience","Dhaka",EmploymentType.FULL_TIME,WorkMode.HYBRID,"BDT 100k",null,"jobs@example.test",deadline,
            List.of(new CareerSkillRequest("java",true)));}

    private Access account(String name,PlatformRole role){
        var user=User.register(name,name.toLowerCase(Locale.ROOT).replace(' ','.')+"@iut-dhaka.edu",passwords.encode("password123"),role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW,ZoneOffset.UTC));users.saveAndFlush(user);
        return login(user.getEmail());
    }

    private Access login(String email){
        String token=sessions.login(new LoginRequest(email,"password123")).accessToken();
        return new Access(token,sessions.authenticate(token));
    }

    private record Access(String token,SessionPrincipal principal) {}

    @TestConfiguration
    static class ClockConfiguration {
        @Bean @Primary MutableClock testClock(){return new MutableClock(NOW);}
    }

    static final class MutableClock extends Clock {
        private volatile Instant current;
        MutableClock(Instant current){this.current=current;}
        void set(Instant value){current=value;}
        @Override public ZoneId getZone(){return ZoneOffset.UTC;}
        @Override public Clock withZone(ZoneId zone){return this;}
        @Override public Instant instant(){return current;}
    }
}
