\set ON_ERROR_STOP on
\pset pager off
SET statement_timeout = '60s';
SET lock_timeout = '5s';
SET TIME ZONE 'UTC';

DO $verify$
DECLARE failures text := '';
BEGIN
 IF NOT EXISTS(SELECT 1 FROM uniconnect_presentation_seed_manifest WHERE dataset_key='presentation-2026-v1' AND seed_version=5 AND account_count=36)
   THEN failures:=failures||' manifest'; END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1' AND entity_type='USER')<>36
   THEN failures:=failures||' account-map-count'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN users u ON u.user_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='USER'
   AND (u.email<>lower(u.email) OR u.email NOT LIKE '%@iut-dhaka.edu' OR u.account_status<>'ACTIVE' OR u.anonymized_at IS NOT NULL))
   THEN failures:=failures||' account-eligibility'; END IF;
 IF (SELECT count(*) FROM users WHERE lower(email) IN ('ayman@iut-dhaka.edu','sayma@iut-dhaka.edu')
   AND platform_role='SYSTEM_ADMIN' AND account_status='ACTIVE' AND anonymized_at IS NULL)<>2
   THEN failures:=failures||' named-administrators'; END IF;
 -- Reused Ayman may retain historical verification audit rows. The seeder creates no
 -- challenge for any newly inserted presentation account.
 IF EXISTS(SELECT 1 FROM email_verification_tokens t JOIN uniconnect_presentation_seed_keys k ON k.entity_id=t.user_id
   JOIN users u ON u.user_id=k.entity_id WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='USER'
   AND lower(u.email)<>'ayman@iut-dhaka.edu')
   THEN failures:=failures||' verification-token'; END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1' AND entity_type='PROFILE')<>34
   THEN failures:=failures||' profile-count'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN mentor_profiles mp ON mp.mentor_profile_id=k.entity_id
   JOIN personal_profiles p ON p.user_id=mp.user_id WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='MENTOR_PROFILE'
   AND p.profile_type='STUDENT' AND p.year_of_study<>4)
   THEN failures:=failures||' student-mentor-year'; END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1' AND entity_type='CONNECTION')<>9
   THEN failures:=failures||' connection-count'; END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1' AND entity_type='CONVERSATION')<>4
   THEN failures:=failures||' conversation-count'; END IF;
 IF EXISTS(SELECT user_low,user_high FROM chat_conversations GROUP BY user_low,user_high HAVING count(*)>1)
   THEN failures:=failures||' conversation-pair-unique'; END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1' AND entity_type='PROJECT')<>6
   THEN failures:=failures||' project-count'; END IF;
 IF EXISTS(SELECT 1 FROM teammate_project_applications a JOIN teammate_project_memberships m
   ON m.project_id=a.project_id AND m.member_user_id=a.applicant_user_id WHERE a.status='PENDING')
   THEN failures:=failures||' member-pending-application'; END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1' AND entity_type='CAREER_POST')<>5
   THEN failures:=failures||' career-count'; END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1' AND entity_type='MENTORSHIP_SLOT')<>6
   THEN failures:=failures||' mentorship-count'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN mentorship_slots s ON s.slot_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='MENTORSHIP_SLOT'
   AND (s.current_mentee_count<>(SELECT count(*) FROM mentorship_enrollments e WHERE e.slot_id=s.slot_id AND e.status='ACTIVE')
        OR s.current_mentee_count>s.capacity))
   THEN failures:=failures||' mentorship-capacity'; END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1' AND entity_type='CLUB')<>3
   THEN failures:=failures||' club-count'; END IF;
 IF NOT EXISTS(SELECT 1 FROM club_creation_requests WHERE status='PENDING' AND name_key='sustainable design collective')
   THEN failures:=failures||' pending-club-request'; END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1' AND entity_type='REPORT')<>10
   THEN failures:=failures||' report-count'; END IF;
 IF (SELECT count(DISTINCT r.target_type) FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT')<>7
   THEN failures:=failures||' report-target-coverage'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
   AND (r.reporter_id IN (SELECT entity_id FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1'
       AND entity_type='USER' AND logical_key IN ('admin_ayman','admin_sayma'))
     OR r.target_owner_user_id IN (SELECT entity_id FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1'
       AND entity_type='USER' AND logical_key IN ('admin_ayman','admin_sayma'))))
   THEN failures:=failures||' named-admin-report'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
   AND NOT EXISTS(SELECT 1 FROM report_audit_logs a WHERE a.report_id=r.report_id AND a.event_type='SUBMITTED'
     AND a.previous_status IS NULL AND a.new_status='SUBMITTED' AND a.occurred_at=r.submitted_at))
   THEN failures:=failures||' report-submission-audit'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
   JOIN report_action_links l ON l.report_id=r.report_id
   LEFT JOIN club_publication_audit a ON l.evidence_source='PUBLICATION' AND a.audit_id=l.evidence_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
   AND (a.audit_id IS NULL OR a.action<>'REMOVED' OR l.action_type<>'REMOVED'
     OR l.subject_id<>COALESCE(a.announcement_id,a.event_id) OR l.action_occurred_at<>a.created_at
     OR l.action_occurred_at<r.submitted_at))
   THEN failures:=failures||' report-action-evidence'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
   AND k.logical_key IN ('announcement-action-taken','event-action-taken')
   AND (r.status<>'ACTION_TAKEN' OR NOT EXISTS(SELECT 1 FROM report_action_links l WHERE l.report_id=r.report_id)
     OR NOT EXISTS(SELECT 1 FROM notifications n WHERE n.recipient_id=r.reporter_id AND n.type='REPORT_RESOLVED'
       AND n.reference_type='REPORT' AND n.reference_id=r.report_id AND n.event_key='report-resolution:'||r.report_id)))
   THEN failures:=failures||' action-resolution'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
   AND k.logical_key IN ('user-no-action','club-no-action')
   AND (r.status<>'NO_ACTION' OR EXISTS(SELECT 1 FROM report_action_links l WHERE l.report_id=r.report_id)
     OR NOT EXISTS(SELECT 1 FROM notifications n WHERE n.recipient_id=r.reporter_id AND n.type='REPORT_RESOLVED'
       AND n.reference_type='REPORT' AND n.reference_id=r.report_id AND n.event_key='report-resolution:'||r.report_id)))
   THEN failures:=failures||' no-action-resolution'; END IF;
 IF NOT EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
   JOIN chat_messages m ON r.target_type='CHAT_MESSAGE' AND m.message_id=r.target_id
   JOIN chat_participants p ON p.conversation_id=m.conversation_id AND p.user_id=r.reporter_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT' AND k.logical_key='chat-submitted')
   THEN failures:=failures||' report-chat-access'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
     AND r.status='UNDER_REVIEW' AND r.internal_notes IS NOT NULL)
   THEN failures:=failures||' under-review-notes'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN report_audit_logs a ON a.report_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
     AND a.event_type='UNDER_REVIEW' AND a.internal_note IS NOT NULL)
   THEN failures:=failures||' under-review-audit-notes'; END IF;
 IF failures<>'' THEN RAISE EXCEPTION 'Presentation verification failed:%',failures; END IF;
END
$verify$;

SELECT 'PASS' AS result, 'presentation structural and semantic checks' AS check_name;
SELECT m.dataset_key,m.seed_version,m.seeded_at,m.base_date,m.date_window_end,m.account_count,
       (SELECT version FROM flyway_schema_history WHERE success AND version IS NOT NULL ORDER BY installed_rank DESC LIMIT 1) migration_version
FROM uniconnect_presentation_seed_manifest m WHERE dataset_key='presentation-2026-v1';
SELECT entity_type,count(*) FROM uniconnect_presentation_seed_keys
WHERE dataset_key='presentation-2026-v1' GROUP BY entity_type ORDER BY entity_type;
SELECT u.full_name,u.email,u.platform_role,p.year_of_study,pr.programme_code
FROM uniconnect_presentation_seed_keys k JOIN users u ON u.user_id=k.entity_id
LEFT JOIN personal_profiles p ON p.user_id=u.user_id
LEFT JOIN programme_degrees pd ON pd.programme_degree_id=p.programme_degree_id
LEFT JOIN programmes pr ON pr.programme_id=pd.programme_id
WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='USER' ORDER BY u.platform_role,u.full_name;

-- Independently calculate the real recommendation formula for the anchor project.
WITH anchor AS (
 SELECT entity_id project_id FROM uniconnect_presentation_seed_keys
 WHERE dataset_key='presentation-2026-v1' AND entity_type='PROJECT' AND logical_key='campus-services'
), project_skills AS (
 SELECT lower(s.name) name,ps.required FROM anchor a JOIN teammate_project_skills ps USING(project_id) JOIN skills s USING(skill_id)
), creator AS (
 SELECT p.creator_user_id FROM anchor a JOIN teammate_projects p USING(project_id)
), candidates AS (
 SELECT u.user_id,u.full_name,pp.profile_id,
   EXISTS(SELECT 1 FROM connections c,creator cr WHERE c.status='ACCEPTED' AND c.user_low=least(cr.creator_user_id,u.user_id) AND c.user_high=greatest(cr.creator_user_id,u.user_id)) connected
 FROM users u JOIN personal_profiles pp ON pp.user_id=u.user_id,creator cr
 WHERE u.platform_role='STUDENT' AND u.account_status='ACTIVE' AND u.anonymized_at IS NULL
   AND pp.project_availability AND u.user_id<>cr.creator_user_id
   AND NOT EXISTS(SELECT 1 FROM anchor a JOIN teammate_project_memberships m USING(project_id) WHERE m.member_user_id=u.user_id)
   AND NOT EXISTS(SELECT 1 FROM anchor a JOIN teammate_project_applications x USING(project_id) WHERE x.applicant_user_id=u.user_id)
   AND (pp.details_visibility='ALL_MEMBERS' OR EXISTS(SELECT 1 FROM connections c WHERE c.status='ACCEPTED'
      AND c.user_low=least(cr.creator_user_id,u.user_id) AND c.user_high=greatest(cr.creator_user_id,u.user_id)))
), scored AS (
 SELECT c.user_id,c.full_name,
  70.0*(3*(SELECT count(*) FROM project_skills ps WHERE ps.required AND EXISTS(SELECT 1 FROM profile_skills x JOIN skills s USING(skill_id) WHERE x.profile_id=c.profile_id AND lower(s.name)=ps.name))
       +(SELECT count(*) FROM project_skills ps WHERE NOT ps.required AND EXISTS(SELECT 1 FROM profile_skills x JOIN skills s USING(skill_id) WHERE x.profile_id=c.profile_id AND lower(s.name)=ps.name)))
      /(3*(SELECT count(*) FROM project_skills WHERE required)+(SELECT count(*) FROM project_skills WHERE NOT required))
  +20.0*(SELECT count(*) FROM profile_interests ci JOIN interests i USING(interest_id) WHERE ci.profile_id=c.profile_id AND lower(i.name) IN
      (SELECT lower(i2.name) FROM creator cr JOIN personal_profiles cp ON cp.user_id=cr.creator_user_id JOIN profile_interests pi ON pi.profile_id=cp.profile_id JOIN interests i2 USING(interest_id)))
      /greatest(1,(SELECT count(*) FROM creator cr JOIN personal_profiles cp ON cp.user_id=cr.creator_user_id JOIN profile_interests pi ON pi.profile_id=cp.profile_id))
  +CASE WHEN connected THEN 10 ELSE 0 END score
 FROM candidates c WHERE EXISTS(SELECT 1 FROM project_skills ps WHERE ps.required AND EXISTS(
   SELECT 1 FROM profile_skills x JOIN skills s USING(skill_id) WHERE x.profile_id=c.profile_id AND lower(s.name)=ps.name))
)
SELECT row_number() OVER(ORDER BY score DESC,lower(full_name),user_id) expected_rank,full_name,round(score,2) expected_score
FROM scored ORDER BY expected_rank LIMIT 10;
