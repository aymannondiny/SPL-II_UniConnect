package com.uniconnect.reporting;

import com.uniconnect.administration.dto.AccountModerationRequest;
import com.uniconnect.administration.service.AccountModerationService;
import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.chat.dto.SendMessageRequest;
import com.uniconnect.chat.service.ChatService;
import com.uniconnect.club.domain.ClubStatus;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.publication.domain.*;
import com.uniconnect.club.publication.dto.*;
import com.uniconnect.club.publication.service.PublicationService;
import com.uniconnect.club.service.*;
import com.uniconnect.connection.dto.ConnectionRequest;
import com.uniconnect.connection.service.ConnectionService;
import com.uniconnect.reporting.domain.*;
import com.uniconnect.reporting.dto.*;
import com.uniconnect.reporting.service.*;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
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
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.json.JsonMapper;

import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties={
        "spring.datasource.url=${content.reporting.integration.url:jdbc:h2:mem:content_reporting;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE}",
        "spring.datasource.driver-class-name=${content.reporting.integration.driver:org.h2.Driver}",
        "spring.datasource.username=${content.reporting.integration.username:sa}",
        "spring.datasource.password=${content.reporting.integration.password:}"
})
@AutoConfigureMockMvc @ActiveProfiles("test") @Import(ContentReportingIntegrationTests.ClockConfiguration.class)
class ContentReportingIntegrationTests {
    @Autowired ReportingService reporting; @Autowired ReportReviewService review;
    @Autowired AccountModerationService accountModeration; @Autowired ClubLifecycleService clubLifecycle;
    @Autowired PublicationService publications; @Autowired ClubService clubs; @Autowired ClubContextService contexts;
    @Autowired ChatService chats; @Autowired ConnectionService connections; @Autowired SessionService sessions;
    @Autowired UserRepository users; @Autowired PasswordEncoder passwords; @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc; @Autowired JsonMapper json; @Autowired MutableClock clock;
    private static final Instant NOW=Instant.parse("2026-10-19T06:00:00Z");
    private static final LocalDateTime TIME=LocalDateTime.ofInstant(NOW,ZoneOffset.UTC);
    private SessionPrincipal system,secondSystem,reporter,target,clubAdmin,outsider;
    private String systemToken,reporterToken,outsiderToken;private long club,announcement,event;

    @BeforeEach void setup(){
        clean();clock.set(NOW);
        systemToken=account("System One",PlatformRole.SYSTEM_ADMIN);system=sessions.authenticate(systemToken);
        secondSystem=sessions.authenticate(account("System Two",PlatformRole.SYSTEM_ADMIN));
        reporterToken=account("Reporter",PlatformRole.STUDENT);reporter=sessions.authenticate(reporterToken);
        target=sessions.authenticate(account("Target",PlatformRole.STUDENT));
        clubAdmin=sessions.authenticate(account("Club Admin",PlatformRole.STUDENT));
        outsiderToken=account("Outsider",PlatformRole.STUDENT);outsider=sessions.authenticate(outsiderToken);
        contexts.select(system,new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION,null));
        contexts.select(secondSystem,new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION,null));
        seedProfile(target.userId());
        club=clubs.create(system,new CreateClubRequest("Reporting Club","Technology","Club evidence",null,null,clubAdmin.userId())).id();
        selectClub(clubAdmin,club);
        announcement=publications.createAnnouncement(clubAdmin,club,new AnnouncementRequest("Original title","Original announcement",
                AnnouncementPriority.NORMAL,AnnouncementStatus.PUBLISHED,null)).id();
        event=publications.createEvent(clubAdmin,club,new EventRequest("Original event","Original event description",null,null,null,
                TIME.plusHours(1),TIME.plusHours(2))).id();
        contexts.select(clubAdmin,new SelectContextRequest(ContextType.PERSONAL,null));
        long connection=connections.send(reporter,new ConnectionRequest(target.userId(),null)).id();connections.accept(target,connection);
    }
    @AfterEach void clean(){
        for(String table:List.of("report_action_links","report_audit_logs","content_reports","audit_logs","moderation_actions",
                "club_publication_audit","club_announcements","club_events","chat_message_states","chat_messages","chat_participants","chat_conversations",
                "notifications","connections","profile_skills","profile_interests","personal_profiles","skills","interests","programme_degrees",
                "programmes","departments","authenticated_sessions","club_audit","club_role_assignments","clubs","email_verification_tokens",
                "password_reset_tokens","users"))try{jdbc.update("delete from "+table);}catch(RuntimeException ignored){}
    }
    private String account(String name,PlatformRole role){var user=User.register(name,name.toLowerCase(Locale.ROOT).replace(' ','.')+"@iut-dhaka.edu",
            passwords.encode("password123"),role);user.verifyEmail(TIME);users.saveAndFlush(user);
        return sessions.login(new LoginRequest(user.getEmail(),"password123")).accessToken();}
    private void seedProfile(long user){jdbc.update("insert into departments(department_id,department_name,department_code) values (1,'CSE','CSE')");
        jdbc.update("insert into programmes(programme_id,department_id,programme_name,programme_code) values (1,1,'Software','SWE')");
        jdbc.update("insert into programme_degrees(programme_degree_id,programme_id,degree_level,duration_years,minimum_year,maximum_year,active) values (1,1,'BACHELOR',4,1,4,true)");
        jdbc.update("insert into personal_profiles(user_id,profile_type,programme_degree_id,bio,created_at,updated_at,student_number,year_of_study,project_availability,mentorship_availability) values (?,?,?,?,?,?,?,?,?,?)",
                user,"STUDENT",1,"Visible target bio",TIME,TIME,"S-"+user,2,true,false);}
    private long selectClub(SessionPrincipal actor,long clubId){var c=contexts.get(actor).availableContexts().stream().filter(x->Objects.equals(x.clubId(),clubId)).findFirst().orElseThrow();
        contexts.select(actor,new SelectContextRequest(ContextType.CLUB,c.assignmentId()));return c.assignmentId();}
    private SubmitReportRequest submit(ReportTargetType type,long id){return new SubmitReportRequest(type,id,"Policy concern");}
    private ResolveReportRequest noAction(){return new ResolveReportRequest(ReportStatus.NO_ACTION,"Reviewed; no action was required.","Internal review complete",null);}
    private ResolveReportRequest action(ActionEvidenceSource source,long id){return new ResolveReportRequest(ReportStatus.ACTION_TAKEN,
            "Reviewed and an appropriate action was completed.","Verified against retained audit evidence",new ActionEvidenceRequest(source,id));}
    private int count(String table){return jdbc.queryForObject("select count(*) from "+table,Integer.class);}

    @Test void supportedTargetsCaptureOnlyAccessibleEvidenceAndReporterDtosStayPrivate() throws Exception {
        var user=reporting.submit(reporter,submit(ReportTargetType.USER,target.userId()));
        reporting.submit(reporter,submit(ReportTargetType.CLUB,club));
        reporting.submit(reporter,submit(ReportTargetType.ANNOUNCEMENT,announcement));
        reporting.submit(reporter,submit(ReportTargetType.EVENT,event));
        var message=chats.send(target,new SendMessageRequest(reporter.userId(),UUID.randomUUID(),"Retained private text"));
        chats.deleteForEveryone(target,message.id());
        var chat=reporting.submit(reporter,submit(ReportTargetType.CHAT_MESSAGE,message.id()));
        assertThat(review.get(system,chat.id()).targetSnapshot()).contains("Retained private text");
        mvc.perform(get("/api/v1/reports/"+chat.id()).header("Authorization","Bearer "+reporterToken))
                .andExpect(status().isOk()).andExpect(jsonPath("$.targetSnapshot").doesNotExist()).andExpect(jsonPath("$.internalNotes").doesNotExist());
        mvc.perform(get("/api/v1/reports/"+user.id()).header("Authorization","Bearer "+outsiderToken)).andExpect(status().isNotFound());
        assertThat(count("content_reports")).isEqualTo(5);
        var hidden=chats.send(target,new SendMessageRequest(reporter.userId(),UUID.randomUUID(),"Deleted for reporter"));
        chats.deleteForSelf(reporter,hidden.id());
        assertThatThrownBy(()->reporting.submit(reporter,submit(ReportTargetType.CHAT_MESSAGE,hidden.id())))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(()->reporting.submit(outsider,submit(ReportTargetType.ANNOUNCEMENT,999999)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test void privatePublicationUsesAssignmentAuthorityWithoutRequiringSelectedClubContext(){
        selectClub(clubAdmin,club);var draft=publications.createAnnouncement(clubAdmin,club,new AnnouncementRequest("Draft","Private draft",
                AnnouncementPriority.NORMAL,AnnouncementStatus.UNPUBLISHED,null));contexts.select(clubAdmin,new SelectContextRequest(ContextType.PERSONAL,null));
        assertThat(reporting.submit(clubAdmin,submit(ReportTargetType.ANNOUNCEMENT,draft.id())).targetId()).isEqualTo(draft.id());
        assertThatThrownBy(()->reporting.submit(outsider,submit(ReportTargetType.ANNOUNCEMENT,draft.id())))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test void duplicateSubmissionAndConcurrentReviewAreSerialized() throws Exception {
        var gate=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)){
            var a=pool.submit(()->{gate.await();try{return reporting.submit(reporter,submit(ReportTargetType.CLUB,club)).id();}catch(ConflictException e){return -1L;}});
            var b=pool.submit(()->{gate.await();try{return reporting.submit(reporter,submit(ReportTargetType.CLUB,club)).id();}catch(ConflictException e){return -1L;}});
            gate.countDown();var submissions=List.of(a.get(10,TimeUnit.SECONDS),b.get(10,TimeUnit.SECONDS));
            assertThat(submissions).contains(-1L);long reportId=submissions.stream().filter(x->x>0).findFirst().orElseThrow();
            var reviewGate=new CountDownLatch(1);
            var first=pool.submit(()->{reviewGate.await();try{return review.review(system,reportId).reviewerId();}catch(ConflictException e){return -1L;}});
            var second=pool.submit(()->{reviewGate.await();try{return review.review(secondSystem,reportId).reviewerId();}catch(ConflictException e){return -1L;}});
            reviewGate.countDown();assertThat(List.of(first.get(10,TimeUnit.SECONDS),second.get(10,TimeUnit.SECONDS))).contains(-1L).anyMatch(x->x>0);
        }
        assertThat(count("report_audit_logs")).isEqualTo(2);
    }

    @Test void noActionIsAtomicIdempotentReviewerOwnedAndDoesNotChangeTarget() throws Exception {
        var report=reporting.submit(reporter,submit(ReportTargetType.CLUB,club));review.review(system,report.id());
        assertThatThrownBy(()->review.resolve(secondSystem,report.id(),noAction())).isInstanceOf(ForbiddenException.class);
        AdminReportResponse resolved;
        var gate=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)){
            var a=pool.submit(()->{gate.await();return review.resolve(system,report.id(),noAction());});
            var b=pool.submit(()->{gate.await();return review.resolve(system,report.id(),noAction());});
            gate.countDown();resolved=a.get(10,TimeUnit.SECONDS);assertThat(b.get(10,TimeUnit.SECONDS).status()).isEqualTo(ReportStatus.NO_ACTION);
        }
        assertThat(resolved.status()).isEqualTo(ReportStatus.NO_ACTION);assertThat(clubLifecycle.get(system,club).status()).isEqualTo(ClubStatus.ACTIVE);
        assertThat(count("report_audit_logs")).isEqualTo(3);assertThat(jdbc.queryForObject("select count(*) from notifications where type='REPORT_RESOLVED'",Integer.class)).isEqualTo(1);
        String notificationJson=mvc.perform(get("/api/v1/notifications").header("Authorization","Bearer "+reporterToken))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertThat(notificationJson).doesNotContain("Internal review complete","targetSnapshot","internalNotes","actionEvidence");
        assertThatThrownBy(()->review.resolve(system,report.id(),new ResolveReportRequest(ReportStatus.ACTION_TAKEN,"Different",null,
                new ActionEvidenceRequest(ActionEvidenceSource.CLUB_LIFECYCLE,1)))).isInstanceOf(ConflictException.class);
        assertThat(reporting.submit(reporter,submit(ReportTargetType.CLUB,club)).id()).isNotEqualTo(report.id());
    }

    @Test void actionResolutionRacesWithAccountAndClubReversalWithoutLosingHistoryOrAcceptingReversedEvidence() throws Exception {
        var userReport=reporting.submit(reporter,submit(ReportTargetType.USER,target.userId()));review.review(system,userReport.id());
        clock.set(NOW.plusSeconds(1));accountModeration.suspend(system,target.userId(),new AccountModerationRequest("Race suspension",true));
        long accountAction=jdbc.queryForObject("select max(action_id) from moderation_actions",Long.class);
        String accountOutcome=race(
                ()->resolveOutcome(userReport.id(),ActionEvidenceSource.ACCOUNT_MODERATION,accountAction),
                ()->{accountModeration.restore(system,target.userId(),new AccountModerationRequest("Race reversal",true));return "REVERSED";});
        assertConsistentRace(userReport.id(),accountOutcome);

        var clubReport=reporting.submit(reporter,submit(ReportTargetType.CLUB,club));review.review(system,clubReport.id());
        clock.set(NOW.plusSeconds(2));clubLifecycle.suspend(system,club,new ClubLifecycleRequest("Race suspension",true));
        long clubAudit=jdbc.queryForObject("select max(audit_id) from club_audit where action='CLUB_PUBLISHING_SUSPENDED'",Long.class);
        String clubOutcome=race(
                ()->resolveOutcome(clubReport.id(),ActionEvidenceSource.CLUB_LIFECYCLE,clubAudit),
                ()->{clubLifecycle.restore(system,club,new ClubLifecycleRequest("Race reversal",true));return "REVERSED";});
        assertConsistentRace(clubReport.id(),clubOutcome);
    }

    private String race(Callable<String> resolution,Callable<String> reversal)throws Exception{
        var gate=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)){
            var resolve=pool.submit(()->{gate.await();return resolution.call();});
            var reverse=pool.submit(()->{gate.await();return reversal.call();});
            gate.countDown();String outcome=resolve.get(10,TimeUnit.SECONDS);assertThat(reverse.get(10,TimeUnit.SECONDS)).isEqualTo("REVERSED");return outcome;
        }
    }
    private String resolveOutcome(long reportId,ActionEvidenceSource source,long evidenceId){
        try{review.resolve(system,reportId,action(source,evidenceId));return "RESOLVED";}
        catch(ConflictException rejected){assertThat(rejected.code()).isEqualTo("INVALID_ACTION_EVIDENCE");return "REJECTED";}
    }
    private void assertConsistentRace(long reportId,String outcome){
        var report=review.get(system,reportId);
        if(outcome.equals("RESOLVED")){
            assertThat(report.status()).isEqualTo(ReportStatus.ACTION_TAKEN);
            assertThat(report.action()).isNotNull();
            assertThat(jdbc.queryForObject("select count(*) from report_action_links where report_id=?",Integer.class,reportId)).isOne();
        }else{
            assertThat(report.status()).isEqualTo(ReportStatus.UNDER_REVIEW);
            assertThat(report.action()).isNull();
            assertThat(jdbc.queryForObject("select count(*) from report_action_links where report_id=?",Integer.class,reportId)).isZero();
        }
    }

    @Test void userAndClubActionsAreVerifiedAndReversedOrUnrelatedEvidenceIsRejected(){
        var userReport=reporting.submit(reporter,submit(ReportTargetType.USER,target.userId()));review.review(system,userReport.id());
        clock.set(NOW.plusSeconds(1));accountModeration.suspend(system,target.userId(),new AccountModerationRequest("Reported conduct",true));
        long actionId=jdbc.queryForObject("select max(action_id) from moderation_actions",Long.class);
        assertThat(review.resolve(system,userReport.id(),action(ActionEvidenceSource.ACCOUNT_MODERATION,actionId)).status()).isEqualTo(ReportStatus.ACTION_TAKEN);
        clock.set(NOW.plusSeconds(2));accountModeration.restore(system,target.userId(),new AccountModerationRequest("Later reversal",true));
        assertThat(review.get(system,userReport.id()).action().evidenceId()).isEqualTo(actionId);

        var reversedUserReport=reporting.submit(reporter,submit(ReportTargetType.USER,target.userId()));review.review(system,reversedUserReport.id());
        clock.set(NOW.plusSeconds(3));accountModeration.suspend(system,target.userId(),new AccountModerationRequest("Second suspension",true));
        long reversedAction=jdbc.queryForObject("select max(action_id) from moderation_actions",Long.class);
        clock.set(NOW.plusSeconds(4));accountModeration.restore(system,target.userId(),new AccountModerationRequest("Committed reversal",true));
        assertThatThrownBy(()->review.resolve(system,reversedUserReport.id(),action(ActionEvidenceSource.ACCOUNT_MODERATION,reversedAction)))
                .isInstanceOf(ConflictException.class).hasMessageContaining("unreversed");

        var clubReport=reporting.submit(reporter,submit(ReportTargetType.CLUB,club));review.review(system,clubReport.id());
        assertThatThrownBy(()->review.resolve(system,clubReport.id(),action(ActionEvidenceSource.ACCOUNT_MODERATION,actionId)))
                .isInstanceOf(ConflictException.class);
        clock.set(NOW.plusSeconds(2));clubLifecycle.suspend(system,club,new ClubLifecycleRequest("Moderation review",true));
        long clubAudit=jdbc.queryForObject("select max(audit_id) from club_audit where action='CLUB_PUBLISHING_SUSPENDED'",Long.class);
        clock.set(NOW.plusSeconds(3));clubLifecycle.restore(system,club,new ClubLifecycleRequest("Resolved",true));
        assertThatThrownBy(()->review.resolve(system,clubReport.id(),action(ActionEvidenceSource.CLUB_LIFECYCLE,clubAudit)))
                .isInstanceOf(ConflictException.class).hasMessageContaining("reversed");
    }

    @Test void publicationRemovalAndCapturedAuthorOrClubActionsQualify(){
        var removalReport=reporting.submit(reporter,submit(ReportTargetType.ANNOUNCEMENT,announcement));review.review(system,removalReport.id());
        clock.set(NOW.plusSeconds(1));selectClub(clubAdmin,club);
        publications.removeAnnouncement(clubAdmin,club,announcement,new PublicationActionRequest(true,"Operator removed reported content"));
        long removal=jdbc.queryForObject("select max(audit_id) from club_publication_audit where announcement_id=? and action='REMOVED'",Long.class,announcement);
        assertThat(review.resolve(system,removalReport.id(),action(ActionEvidenceSource.PUBLICATION,removal)).status()).isEqualTo(ReportStatus.ACTION_TAKEN);

        var eventReport=reporting.submit(reporter,submit(ReportTargetType.EVENT,event));review.review(system,eventReport.id());
        clock.set(NOW.plusSeconds(2));accountModeration.suspend(system,clubAdmin.userId(),new AccountModerationRequest("Author moderation",true));
        long authorAction=jdbc.queryForObject("select max(action_id) from moderation_actions",Long.class);
        assertThat(review.resolve(system,eventReport.id(),action(ActionEvidenceSource.ACCOUNT_MODERATION,authorAction)).action().subjectId())
                .isEqualTo(clubAdmin.userId());
    }

    @Test void clubAndPublicationParentEvidenceAndChatSenderEvidenceQualify(){
        var clubReport=reporting.submit(reporter,submit(ReportTargetType.CLUB,club));review.review(system,clubReport.id());
        var publicationReport=reporting.submit(reporter,submit(ReportTargetType.ANNOUNCEMENT,announcement));review.review(system,publicationReport.id());
        var message=chats.send(target,new SendMessageRequest(reporter.userId(),UUID.randomUUID(),"Reportable message"));
        var chatReport=reporting.submit(reporter,submit(ReportTargetType.CHAT_MESSAGE,message.id()));review.review(system,chatReport.id());
        clock.set(NOW.plusSeconds(1));clubLifecycle.suspend(system,club,new ClubLifecycleRequest("Qualifying club action",true));
        long clubAudit=jdbc.queryForObject("select max(audit_id) from club_audit where action='CLUB_PUBLISHING_SUSPENDED'",Long.class);
        assertThat(review.resolve(system,clubReport.id(),action(ActionEvidenceSource.CLUB_LIFECYCLE,clubAudit)).status()).isEqualTo(ReportStatus.ACTION_TAKEN);
        assertThat(review.resolve(system,publicationReport.id(),action(ActionEvidenceSource.CLUB_LIFECYCLE,clubAudit)).action().subjectId()).isEqualTo(club);
        clock.set(NOW.plusSeconds(2));clubLifecycle.restore(system,club,new ClubLifecycleRequest("Later reversal",true));
        assertThat(review.get(system,clubReport.id()).action().evidenceId()).isEqualTo(clubAudit);
        assertThat(review.get(system,publicationReport.id()).action().evidenceId()).isEqualTo(clubAudit);
        clock.set(NOW.plusSeconds(3));accountModeration.suspend(system,target.userId(),new AccountModerationRequest("Message sender action",true));
        long senderAction=jdbc.queryForObject("select max(action_id) from moderation_actions",Long.class);
        assertThat(review.resolve(system,chatReport.id(),action(ActionEvidenceSource.ACCOUNT_MODERATION,senderAction)).action().subjectId()).isEqualTo(target.userId());
    }

    @Test void snapshotSurvivesEditAndResolutionRollbackLeavesReviewOpen(){
        var report=reporting.submit(reporter,submit(ReportTargetType.ANNOUNCEMENT,announcement));
        selectClub(clubAdmin,club);publications.editAnnouncement(clubAdmin,club,announcement,
                new AnnouncementEditRequest("Changed title","Changed body",AnnouncementPriority.IMPORTANT,null));
        assertThat(review.get(system,report.id()).targetSnapshot()).contains("Original announcement").doesNotContain("Changed body");
        review.review(system,report.id());clock.set(NOW.plusSeconds(1));
        accountModeration.suspend(system,clubAdmin.userId(),new AccountModerationRequest("Author moderation",true));
        long actionId=jdbc.queryForObject("select max(action_id) from moderation_actions",Long.class);
        jdbc.update("insert into notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) values (?,?,?,?,?,?,?,?)",
                reporter.userId(),"REPORT_RESOLVED","Seed","Seed","REPORT",report.id(),"report-resolution:"+report.id(),TIME);
        assertThatThrownBy(()->review.resolve(system,report.id(),action(ActionEvidenceSource.ACCOUNT_MODERATION,actionId))).isInstanceOf(RuntimeException.class);
        assertThat(review.get(system,report.id()).status()).isEqualTo(ReportStatus.UNDER_REVIEW);
        assertThat(count("report_action_links")).isZero();assertThat(count("report_audit_logs")).isEqualTo(2);
    }

    @Test void restContractsContextsValidationAndOpenApiAreExplicit() throws Exception {
        mvc.perform(post("/api/v1/reports").header("Authorization","Bearer "+reporterToken).contentType(MediaType.APPLICATION_JSON)
                .content("{\"targetType\":\"CLUB\",\"targetId\":"+club+",\"reason\":\"Concern\"}"))
                .andExpect(status().isCreated()).andExpect(header().string("Cache-Control","no-store"))
                .andExpect(jsonPath("$.targetSnapshot").doesNotExist()).andExpect(jsonPath("$.internalNotes").doesNotExist())
                .andExpect(jsonPath("$.action").doesNotExist()).andExpect(jsonPath("$.history").doesNotExist());
        mvc.perform(get("/api/v1/reports").header("Authorization","Bearer "+reporterToken))
                .andExpect(status().isOk()).andExpect(jsonPath("$.items[0].targetSnapshot").doesNotExist())
                .andExpect(jsonPath("$.items[0].internalNotes").doesNotExist()).andExpect(jsonPath("$.items[0].action").doesNotExist());
        mvc.perform(post("/api/v1/reports").header("Authorization","Bearer "+reporterToken).contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        contexts.select(system,new SelectContextRequest(ContextType.PERSONAL,null));
        mvc.perform(get("/api/v1/admin/reports").header("Authorization","Bearer "+systemToken)).andExpect(status().isForbidden());
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/reports'].post.responses['201']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/admin/reports/{id}/resolve'].post.responses['200']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/admin/reports/{id}/resolve'].post.responses['409']").exists());
    }

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
