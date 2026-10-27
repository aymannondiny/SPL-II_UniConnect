package com.uniconnect.administration;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.club.dto.CreateClubRequest;
import com.uniconnect.club.dto.SelectContextRequest;
import com.uniconnect.club.service.ClubContextService;
import com.uniconnect.club.service.ClubService;
import com.uniconnect.shared.security.ContextType;
import com.uniconnect.shared.security.PlatformRole;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:admin_dashboard;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE")
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(AdministrationDashboardIntegrationTests.FixedClockConfiguration.class)
class AdministrationDashboardIntegrationTests {
    private static final Instant NOW = Instant.parse("2026-10-28T12:00:00Z");

    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired SessionService sessions;
    @Autowired ClubContextService contexts;
    @Autowired ClubService clubs;
    @Autowired JdbcTemplate jdbc;

    private String administratorToken;
    private String studentToken;
    private String alumniToken;
    private long administratorId;
    private long memberId;

    @TestConfiguration
    static class FixedClockConfiguration {
        @Bean @Primary Clock fixedClock() { return Clock.fixed(NOW, ZoneOffset.UTC); }
    }

    @BeforeEach
    void setup() {
        clean();
        administratorToken = account("Dashboard Admin", PlatformRole.SYSTEM_ADMIN);
        var administrator = sessions.authenticate(administratorToken);
        administratorId = administrator.userId();
        studentToken = account("Dashboard Member", PlatformRole.STUDENT);
        memberId = sessions.authenticate(studentToken).userId();
        alumniToken = account("Dashboard Alumni", PlatformRole.ALUMNI);
        contexts.select(administrator, new SelectContextRequest(ContextType.SYSTEM_ADMINISTRATION, null));
    }

    @AfterEach
    void clean() {
        for (String table : List.of("report_action_links", "report_audit_logs", "content_reports",
                "club_publication_audit", "club_announcements", "club_events", "club_audit",
                "club_role_assignments", "clubs", "authenticated_sessions", "notifications", "connections",
                "profiles", "email_verification_tokens", "password_reset_tokens", "users")) {
            try { jdbc.update("delete from " + table); } catch (RuntimeException ignored) { }
        }
    }

    @Test
    void returnsAuthoritativeCountsAndDocumentsTheEndpoint() throws Exception {
        var administrator = sessions.authenticate(administratorToken);
        long clubId = clubs.create(administrator, new CreateClubRequest(
                "Dashboard Club", "Technology", "Dashboard statistics", null, null, memberId)).id();
        long assignmentId = jdbc.queryForObject(
                "select assignment_id from club_role_assignments where club_id=? and user_id=?",
                Long.class, clubId, memberId);
        LocalDateTime now = LocalDateTime.ofInstant(NOW, ZoneOffset.UTC);

        jdbc.update("insert into club_announcements(club_id,author_user_id,author_assignment_id,title,content,priority,status,created_at,updated_at,published_at,expires_at) "
                        + "values (?,?,?,?,?,'NORMAL','PUBLISHED',?,?,?,?)",
                clubId, memberId, assignmentId, "Current", "Visible", now, now, now, now.plusDays(1));
        jdbc.update("insert into club_announcements(club_id,author_user_id,author_assignment_id,title,content,priority,status,created_at,updated_at,published_at,expires_at) "
                        + "values (?,?,?,?,?,'NORMAL','PUBLISHED',?,?,?,?)",
                clubId, memberId, assignmentId, "Expired", "No longer visible", now, now, now.minusDays(2), now.minusDays(1));
        jdbc.update("insert into club_events(club_id,author_user_id,author_assignment_id,title,description,starts_at,ends_at,status,published_at,updated_at) "
                        + "values (?,?,?,?,?,?,?,'PUBLISHED',?,?)",
                clubId, memberId, assignmentId, "Published event", "Visible event", now.plusDays(1),
                now.plusDays(2), now, now);

        insertReport("SUBMITTED", memberId, null, null, null, 101);
        insertReport("UNDER_REVIEW", memberId, administratorId, now.minusMinutes(5), null, 102);
        insertReport("NO_ACTION", memberId, administratorId, now.minusMinutes(10), now.minusMinutes(1), 103);

        mvc.perform(get("/api/v1/admin/dashboard/summary")
                        .header("Authorization", "Bearer " + administratorToken))
                .andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.totalUsers").value(3))
                .andExpect(jsonPath("$.activeClubs").value(1))
                .andExpect(jsonPath("$.publishedPosts").value(2))
                .andExpect(jsonPath("$.openReports").value(2));
        mvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/admin/dashboard/summary'].get.responses['200']").exists());
    }

    @Test
    void returnsLegitimateZerosAndRejectsMissingOrWrongAdministrationContext() throws Exception {
        mvc.perform(get("/api/v1/admin/dashboard/summary"))
                .andExpect(status().isUnauthorized());

        mvc.perform(get("/api/v1/admin/dashboard/summary")
                        .header("Authorization", "Bearer " + administratorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalUsers").value(3))
                .andExpect(jsonPath("$.activeClubs").value(0))
                .andExpect(jsonPath("$.publishedPosts").value(0))
                .andExpect(jsonPath("$.openReports").value(0));

        var administrator = sessions.authenticate(administratorToken);
        contexts.select(administrator, new SelectContextRequest(ContextType.PERSONAL, null));
        mvc.perform(get("/api/v1/admin/dashboard/summary")
                        .header("Authorization", "Bearer " + administratorToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("ACCESS_DENIED"));
    }

    @Test
    void rejectsStudentAndAlumniAuthorities() throws Exception {
        for (String token : List.of(studentToken, alumniToken)) {
            mvc.perform(get("/api/v1/admin/dashboard/summary")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("ACCESS_DENIED"));
        }
    }

    private void insertReport(String status, long reporter, Long reviewer, LocalDateTime reviewStarted,
            LocalDateTime resolved, long targetId) {
        boolean open = status.equals("SUBMITTED") || status.equals("UNDER_REVIEW");
        jdbc.update("insert into content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,"
                        + "target_owner_user_id,reviewer_id,submitted_at,review_started_at,resolved_at,resolution_summary,"
                        + "open_reporter_id,open_target_type,open_target_id) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                reporter, "USER", targetId, "Mild fixture report", status, "Synthetic target", "{}", memberId,
                reviewer, LocalDateTime.ofInstant(NOW, ZoneOffset.UTC).minusHours(1), reviewStarted, resolved,
                resolved == null ? null : "Reviewed with no action", open ? reporter : null,
                open ? "USER" : null, open ? targetId : null);
    }

    private String account(String name, PlatformRole role) {
        var user = User.register(name, name.toLowerCase().replace(' ', '.') + "@iut-dhaka.edu",
                passwords.encode("password123"), role);
        user.verifyEmail(LocalDateTime.ofInstant(NOW, ZoneOffset.UTC));
        users.saveAndFlush(user);
        return sessions.login(new LoginRequest(user.getEmail(), "password123")).accessToken();
    }
}
