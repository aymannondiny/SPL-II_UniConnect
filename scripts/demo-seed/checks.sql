-- Pristine-only assertions: run before login or manual changes. No password/token values selected.
DO $verify$
BEGIN
    IF (SELECT count(*) FROM users) <> 26 THEN
        RAISE EXCEPTION 'Fixture count mismatch: users (expected 26).';
    END IF;
    IF (SELECT count(*) FROM departments) <> 3 THEN
        RAISE EXCEPTION 'Fixture count mismatch: departments (expected 3).';
    END IF;
    IF (SELECT count(*) FROM programmes) <> 4 THEN
        RAISE EXCEPTION 'Fixture count mismatch: programmes (expected 4).';
    END IF;
    IF (SELECT count(*) FROM programme_degrees) <> 4 THEN
        RAISE EXCEPTION 'Fixture count mismatch: programme_degrees (expected 4).';
    END IF;
    IF (SELECT count(*) FROM skills) <> 16 THEN
        RAISE EXCEPTION 'Fixture count mismatch: skills (expected 16).';
    END IF;
    IF (SELECT count(*) FROM interests) <> 8 THEN
        RAISE EXCEPTION 'Fixture count mismatch: interests (expected 8).';
    END IF;
    IF (SELECT count(*) FROM personal_profiles) <> 23 THEN
        RAISE EXCEPTION 'Fixture count mismatch: personal_profiles (expected 23).';
    END IF;
    IF (SELECT count(*) FROM profile_skills) <> 52 THEN
        RAISE EXCEPTION 'Fixture count mismatch: profile_skills (expected 52).';
    END IF;
    IF (SELECT count(*) FROM profile_interests) <> 28 THEN
        RAISE EXCEPTION 'Fixture count mismatch: profile_interests (expected 28).';
    END IF;
    IF (SELECT count(*) FROM connections) <> 9 THEN
        RAISE EXCEPTION 'Fixture count mismatch: connections (expected 9).';
    END IF;
    IF (SELECT count(*) FROM chat_conversations) <> 2 THEN
        RAISE EXCEPTION 'Fixture count mismatch: chat_conversations (expected 2).';
    END IF;
    IF (SELECT count(*) FROM chat_participants) <> 4 THEN
        RAISE EXCEPTION 'Fixture count mismatch: chat_participants (expected 4).';
    END IF;
    IF (SELECT count(*) FROM chat_messages) <> 6 THEN
        RAISE EXCEPTION 'Fixture count mismatch: chat_messages (expected 6).';
    END IF;
    IF (SELECT count(*) FROM chat_message_states) <> 12 THEN
        RAISE EXCEPTION 'Fixture count mismatch: chat_message_states (expected 12).';
    END IF;
    IF (SELECT count(*) FROM clubs) <> 4 THEN
        RAISE EXCEPTION 'Fixture count mismatch: clubs (expected 4).';
    END IF;
    IF (SELECT count(*) FROM club_role_assignments) <> 8 THEN
        RAISE EXCEPTION 'Fixture count mismatch: club_role_assignments (expected 8).';
    END IF;
    IF (SELECT count(*) FROM club_audit) <> 12 THEN
        RAISE EXCEPTION 'Fixture count mismatch: club_audit (expected 12).';
    END IF;
    IF (SELECT count(*) FROM club_creation_requests) <> 3 THEN
        RAISE EXCEPTION 'Fixture count mismatch: club_creation_requests (expected 3).';
    END IF;
    IF (SELECT count(*) FROM club_announcements) <> 6 THEN
        RAISE EXCEPTION 'Fixture count mismatch: club_announcements (expected 6).';
    END IF;
    IF (SELECT count(*) FROM club_events) <> 4 THEN
        RAISE EXCEPTION 'Fixture count mismatch: club_events (expected 4).';
    END IF;
    IF (SELECT count(*) FROM club_publication_audit) <> 16 THEN
        RAISE EXCEPTION 'Fixture count mismatch: club_publication_audit (expected 16).';
    END IF;
    IF (SELECT count(*) FROM mentor_profiles) <> 3 THEN
        RAISE EXCEPTION 'Fixture count mismatch: mentor_profiles (expected 3).';
    END IF;
    IF (SELECT count(*) FROM mentor_expertise) <> 5 THEN
        RAISE EXCEPTION 'Fixture count mismatch: mentor_expertise (expected 5).';
    END IF;
    IF (SELECT count(*) FROM mentorship_slots) <> 8 THEN
        RAISE EXCEPTION 'Fixture count mismatch: mentorship_slots (expected 8).';
    END IF;
    IF (SELECT count(*) FROM mentorship_occurrences) <> 14 THEN
        RAISE EXCEPTION 'Fixture count mismatch: mentorship_occurrences (expected 14).';
    END IF;
    IF (SELECT count(*) FROM mentorship_enrollments) <> 9 THEN
        RAISE EXCEPTION 'Fixture count mismatch: mentorship_enrollments (expected 9).';
    END IF;
    IF (SELECT count(*) FROM teammate_projects) <> 7 THEN
        RAISE EXCEPTION 'Fixture count mismatch: teammate_projects (expected 7).';
    END IF;
    IF (SELECT count(*) FROM teammate_project_skills) <> 13 THEN
        RAISE EXCEPTION 'Fixture count mismatch: teammate_project_skills (expected 13).';
    END IF;
    IF (SELECT count(*) FROM teammate_project_memberships) <> 9 THEN
        RAISE EXCEPTION 'Fixture count mismatch: teammate_project_memberships (expected 9).';
    END IF;
    IF (SELECT count(*) FROM teammate_project_applications) <> 6 THEN
        RAISE EXCEPTION 'Fixture count mismatch: teammate_project_applications (expected 6).';
    END IF;
    IF (SELECT count(*) FROM teammate_project_audits) <> 19 THEN
        RAISE EXCEPTION 'Fixture count mismatch: teammate_project_audits (expected 19).';
    END IF;
    IF (SELECT count(*) FROM career_job_posts) <> 6 THEN
        RAISE EXCEPTION 'Fixture count mismatch: career_job_posts (expected 6).';
    END IF;
    IF (SELECT count(*) FROM career_job_skills) <> 12 THEN
        RAISE EXCEPTION 'Fixture count mismatch: career_job_skills (expected 12).';
    END IF;
    IF (SELECT count(*) FROM career_saved_jobs) <> 5 THEN
        RAISE EXCEPTION 'Fixture count mismatch: career_saved_jobs (expected 5).';
    END IF;
    IF (SELECT count(*) FROM moderation_actions) <> 1 THEN
        RAISE EXCEPTION 'Fixture count mismatch: moderation_actions (expected 1).';
    END IF;
    IF (SELECT count(*) FROM audit_logs) <> 1 THEN
        RAISE EXCEPTION 'Fixture count mismatch: audit_logs (expected 1).';
    END IF;
    IF (SELECT count(*) FROM content_reports) <> 7 THEN
        RAISE EXCEPTION 'Fixture count mismatch: content_reports (expected 7).';
    END IF;
    IF (SELECT count(*) FROM report_audit_logs) <> 13 THEN
        RAISE EXCEPTION 'Fixture count mismatch: report_audit_logs (expected 13).';
    END IF;
    IF (SELECT count(*) FROM report_action_links) <> 1 THEN
        RAISE EXCEPTION 'Fixture count mismatch: report_action_links (expected 1).';
    END IF;
    IF (SELECT count(*) FROM notifications) <> 59 THEN
        RAISE EXCEPTION 'Fixture count mismatch: notifications (expected 59).';
    END IF;
    IF EXISTS (SELECT 1 FROM authenticated_sessions) THEN
        RAISE EXCEPTION 'Pristine fixture must have no rows in authenticated_sessions.';
    END IF;
    IF EXISTS (SELECT 1 FROM email_verification_tokens) THEN
        RAISE EXCEPTION 'Pristine fixture must have no rows in email_verification_tokens.';
    END IF;
    IF EXISTS (SELECT 1 FROM password_reset_tokens) THEN
        RAISE EXCEPTION 'Pristine fixture must have no rows in password_reset_tokens.';
    END IF;
    IF EXISTS (SELECT 1 FROM users WHERE email NOT LIKE '%@iut-dhaka.edu' OR email <> lower(email)) THEN
        RAISE EXCEPTION 'Unexpected fixture account email.';
    END IF;
    IF EXISTS (SELECT 1 FROM skills WHERE name <> lower(trim(name))) OR EXISTS (SELECT lower(name) FROM skills GROUP BY lower(name) HAVING count(*)>1) THEN
        RAISE EXCEPTION 'Skill vocabulary is not canonical.';
    END IF;
    IF EXISTS (SELECT 1 FROM interests WHERE name <> lower(trim(name))) THEN
        RAISE EXCEPTION 'Interest vocabulary is not canonical.';
    END IF;
    IF EXISTS (SELECT 1 FROM personal_profiles p JOIN users u USING(user_id) WHERE p.profile_type <> u.platform_role) THEN
        RAISE EXCEPTION 'Profile subtype does not match account role.';
    END IF;
    IF EXISTS (SELECT 1 FROM mentorship_slots s WHERE s.current_mentee_count <> (SELECT count(*) FROM mentorship_enrollments e WHERE e.slot_id=s.slot_id AND e.status='ACTIVE')) THEN
        RAISE EXCEPTION 'Mentorship active count mismatch.';
    END IF;
    IF EXISTS (SELECT 1 FROM mentorship_slots s WHERE s.meeting_count <> (SELECT count(*) FROM mentorship_occurrences o WHERE o.slot_id=s.slot_id)) THEN
        RAISE EXCEPTION 'Mentorship occurrence count mismatch.';
    END IF;
    IF EXISTS (SELECT 1 FROM mentorship_enrollments WHERE (status='ACTIVE' AND (active_marker IS DISTINCT FROM TRUE OR left_at IS NOT NULL)) OR (status<>'ACTIVE' AND (active_marker IS NOT NULL OR left_at IS NULL))) THEN
        RAISE EXCEPTION 'Mentorship enrollment-period invariant failed.';
    END IF;
    IF EXISTS (SELECT 1 FROM mentorship_enrollments e JOIN mentorship_slots s USING(slot_id) JOIN mentor_profiles m USING(mentor_profile_id) WHERE e.mentee_id=m.user_id) THEN
        RAISE EXCEPTION 'A mentor enrolled in their own series.';
    END IF;
    IF EXISTS (SELECT 1 FROM mentorship_occurrences a JOIN mentorship_slots sa ON sa.slot_id=a.slot_id JOIN mentorship_occurrences b ON a.occurrence_id<b.occurrence_id JOIN mentorship_slots sb ON sb.slot_id=b.slot_id WHERE sa.mentor_profile_id=sb.mentor_profile_id AND a.cancelled_at IS NULL AND b.cancelled_at IS NULL AND a.starts_at<b.ends_at AND b.starts_at<a.ends_at) THEN
        RAISE EXCEPTION 'A mentor has overlapping hosted meetings.';
    END IF;
    IF EXISTS (SELECT 1 FROM teammate_projects p WHERE (SELECT count(*) FROM teammate_project_memberships m WHERE m.project_id=p.project_id)>p.team_size_limit) THEN
        RAISE EXCEPTION 'Project capacity exceeded.';
    END IF;
    IF EXISTS (SELECT 1 FROM teammate_projects p WHERE (SELECT count(*) FROM teammate_project_memberships m WHERE m.project_id=p.project_id AND m.role='CREATOR' AND m.member_user_id=p.creator_user_id)<>1) THEN
        RAISE EXCEPTION 'Project must have exactly its matching creator membership.';
    END IF;
    IF EXISTS (SELECT 1 FROM teammate_project_applications a WHERE a.status='ACCEPTED' AND NOT EXISTS (SELECT 1 FROM teammate_project_memberships m WHERE m.project_id=a.project_id AND m.member_user_id=a.applicant_user_id AND m.role='TEAMMATE')) THEN
        RAISE EXCEPTION 'Accepted application has no matching membership.';
    END IF;
    IF EXISTS (SELECT 1 FROM teammate_project_applications WHERE project_id=1) THEN
        RAISE EXCEPTION 'Recommendation control project must have no applications.';
    END IF;
    IF EXISTS (SELECT 1 FROM connections WHERE (user_low=2 AND user_high=7) AND status='ACCEPTED') THEN
        RAISE EXCEPTION 'Hidden Student must not be connected to Project Creator.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM career_saved_jobs WHERE student_user_id=17 AND job_post_id=2) OR NOT EXISTS (SELECT 1 FROM career_saved_jobs WHERE student_user_id=17 AND job_post_id=3) THEN
        RAISE EXCEPTION 'Reporter retained-access fixtures missing.';
    END IF;
    IF EXISTS (SELECT 1 FROM career_saved_jobs WHERE student_user_id=18) THEN
        RAISE EXCEPTION 'Outsider must not have saved career-post access.';
    END IF;
    IF EXISTS (SELECT 1 FROM report_action_links l JOIN content_reports r USING(report_id) JOIN moderation_actions a ON a.action_id=l.evidence_id WHERE l.evidence_source='ACCOUNT_MODERATION' AND (a.target_user_id IS DISTINCT FROM r.target_owner_user_id OR a.created_at<r.submitted_at OR a.reversed_at IS NOT NULL OR a.action_type<>'SUSPEND_ACCOUNT')) THEN
        RAISE EXCEPTION 'Report action evidence does not qualify.';
    END IF;
    IF EXISTS (SELECT 1 FROM content_reports WHERE jsonb_typeof(target_snapshot::jsonb)<>'object') THEN
        RAISE EXCEPTION 'Report evidence must be a JSON object.';
    END IF;
    IF EXISTS (SELECT 1 FROM content_reports r WHERE (SELECT count(*) FROM report_audit_logs h WHERE h.report_id=r.report_id AND h.new_status=r.status)<>1) THEN
        RAISE EXCEPTION 'Report terminal/current history mismatch.';
    END IF;
    IF EXISTS (SELECT 1 FROM chat_conversations c WHERE NOT EXISTS (SELECT 1 FROM connections n WHERE n.user_low=c.user_low AND n.user_high=c.user_high AND n.status='ACCEPTED')) THEN
        RAISE EXCEPTION 'Chat fixture requires an accepted connection.';
    END IF;
    IF EXISTS (SELECT 1 FROM notifications n WHERE NOT CASE n.reference_type WHEN 'CONNECTION' THEN EXISTS (SELECT 1 FROM connections x WHERE x.connection_id=n.reference_id) WHEN 'CLUB' THEN EXISTS (SELECT 1 FROM clubs x WHERE x.club_id=n.reference_id) WHEN 'CONVERSATION' THEN EXISTS (SELECT 1 FROM chat_conversations x WHERE x.conversation_id=n.reference_id) WHEN 'USER' THEN EXISTS (SELECT 1 FROM users x WHERE x.user_id=n.reference_id) WHEN 'REPORT' THEN EXISTS (SELECT 1 FROM content_reports x WHERE x.report_id=n.reference_id) WHEN 'PROJECT' THEN EXISTS (SELECT 1 FROM teammate_projects x WHERE x.project_id=n.reference_id) WHEN 'MENTORSHIP_SLOT' THEN EXISTS (SELECT 1 FROM mentorship_slots x WHERE x.slot_id=n.reference_id) ELSE FALSE END) THEN
        RAISE EXCEPTION 'Notification target missing.';
    END IF;
    IF (WITH scores AS (
        SELECT p.user_id,
          round(70::numeric * (3*(SELECT count(*) FROM profile_skills k WHERE k.profile_id=p.profile_id AND k.skill_id IN(1,2))
             +(SELECT count(*) FROM profile_skills k WHERE k.profile_id=p.profile_id AND k.skill_id IN(3,4)))/8
             +20::numeric*(SELECT count(*) FROM profile_interests i WHERE i.profile_id=p.profile_id AND i.interest_id IN(1,2))/2
             +CASE WHEN EXISTS(SELECT 1 FROM connections c WHERE c.user_low=2 AND c.user_high=p.user_id AND c.status='ACCEPTED') THEN 10 ELSE 0 END,2) AS score
        FROM personal_profiles p JOIN users u USING(user_id)
        WHERE u.account_status='ACTIVE' AND u.anonymized_at IS NULL AND p.profile_type='STUDENT'
          AND p.project_availability=TRUE AND p.user_id<>2
          AND (p.details_visibility='ALL_MEMBERS' OR EXISTS(SELECT 1 FROM connections c WHERE c.user_low=2 AND c.user_high=p.user_id AND c.status='ACCEPTED'))
          AND EXISTS(SELECT 1 FROM profile_skills k WHERE k.profile_id=p.profile_id AND k.skill_id IN(1,2))
    ) SELECT array_agg(user_id ORDER BY score DESC,user_id) FROM scores) IS DISTINCT FROM ARRAY[3,4,5]::bigint[] THEN
        RAISE EXCEPTION 'Recommendation candidate exclusion/order failed.';
    END IF;
    IF (WITH scores AS (
        SELECT p.user_id,
          round(70::numeric * (3*(SELECT count(*) FROM profile_skills k WHERE k.profile_id=p.profile_id AND k.skill_id IN(1,2))
             +(SELECT count(*) FROM profile_skills k WHERE k.profile_id=p.profile_id AND k.skill_id IN(3,4)))/8
             +20::numeric*(SELECT count(*) FROM profile_interests i WHERE i.profile_id=p.profile_id AND i.interest_id IN(1,2))/2
             +CASE WHEN EXISTS(SELECT 1 FROM connections c WHERE c.user_low=2 AND c.user_high=p.user_id AND c.status='ACCEPTED') THEN 10 ELSE 0 END,2) AS score
        FROM personal_profiles p JOIN users u USING(user_id)
        WHERE u.account_status='ACTIVE' AND u.anonymized_at IS NULL AND p.profile_type='STUDENT'
          AND p.project_availability=TRUE AND p.user_id<>2
          AND (p.details_visibility='ALL_MEMBERS' OR EXISTS(SELECT 1 FROM connections c WHERE c.user_low=2 AND c.user_high=p.user_id AND c.status='ACCEPTED'))
          AND EXISTS(SELECT 1 FROM profile_skills k WHERE k.profile_id=p.profile_id AND k.skill_id IN(1,2))
    ) SELECT array_agg(score ORDER BY score DESC,user_id) FROM scores) IS DISTINCT FROM ARRAY[100.00,45.00,36.25]::numeric[] THEN
        RAISE EXCEPTION 'Recommendation fixture scores failed.';
    END IF;
    RAISE NOTICE 'Pristine demo fixture checks passed.';
END
$verify$;
