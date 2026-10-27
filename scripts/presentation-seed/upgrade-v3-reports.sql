-- Additive presentation report scenarios. This script runs inside seed.sql's
-- transaction and advances only an intact presentation-2026-v1 revision 3.
DO $guard$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM uniconnect_presentation_seed_manifest
   WHERE dataset_key='presentation-2026-v1' AND seed_version=3) THEN
  RAISE EXCEPTION 'The v3 presentation manifest is required for the report upgrade';
 END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys
   WHERE dataset_key='presentation-2026-v1' AND entity_type='REPORT')<>2 THEN
  RAISE EXCEPTION 'Expected exactly two mapped reports before the v4 report upgrade';
 END IF;
 IF EXISTS (SELECT 1 FROM uniconnect_presentation_seed_keys
   WHERE dataset_key='presentation-2026-v1' AND entity_type IN ('ANNOUNCEMENT','EVENT')) THEN
  RAISE EXCEPTION 'Unexpected mapped publication target before the v4 report upgrade';
 END IF;
END
$guard$;

CREATE OR REPLACE FUNCTION pg_temp.presentation_uid(key text) RETURNS bigint LANGUAGE sql STABLE AS $$
 SELECT entity_id FROM uniconnect_presentation_seed_keys
 WHERE dataset_key='presentation-2026-v1' AND entity_type='USER' AND logical_key=key
$$;
CREATE OR REPLACE FUNCTION pg_temp.presentation_eid(kind text,key text) RETURNS bigint LANGUAGE sql STABLE AS $$
 SELECT entity_id FROM uniconnect_presentation_seed_keys
 WHERE dataset_key='presentation-2026-v1' AND entity_type=kind AND logical_key=key
$$;

-- These two publication targets exist only to demonstrate real, committed
-- moderation evidence. Removing them does not disturb the public demo feed.
DO $moderated_publications$
DECLARE
 now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
 club_id_value bigint;
 assignment_id_value bigint;
 target_id_value bigint;
 created_audit_id bigint;
 removal_audit_id bigint;
 report_id_value bigint;
BEGIN
 club_id_value:=pg_temp.presentation_eid('CLUB','innovation');
 assignment_id_value:=pg_temp.presentation_eid('CLUB_ASSIGNMENT','innovation-admin');
 INSERT INTO club_announcements(club_id,author_user_id,author_assignment_id,title,content,priority,status,
   created_at,updated_at,published_at,expires_at,removed_at)
 VALUES(club_id_value,pg_temp.presentation_uid('sadia_afrin'),assignment_id_value,
   'Repeated prototype registration reminder',
   'A fictional duplicate reminder retained only as a moderation-history example.',
   'NORMAL','REMOVED',now_utc-interval '8 days',now_utc-interval '2 days',
   now_utc-interval '8 days',now_utc+interval '12 days',now_utc-interval '2 days')
 RETURNING announcement_id INTO target_id_value;
 INSERT INTO uniconnect_presentation_seed_keys(dataset_key,entity_type,logical_key,entity_id,created_at)
 VALUES('presentation-2026-v1','ANNOUNCEMENT','moderated-duplicate-reminder',target_id_value,now_utc);
 INSERT INTO club_publication_audit(club_id,announcement_id,actor_user_id,actor_assignment_id,action,
   before_snapshot,after_snapshot,created_at)
 VALUES(club_id_value,target_id_value,pg_temp.presentation_uid('sadia_afrin'),assignment_id_value,'CREATED',NULL,
   jsonb_build_object('announcementId',target_id_value,'title','Repeated prototype registration reminder','status','UNPUBLISHED')::text,
   now_utc-interval '8 days') RETURNING audit_id INTO created_audit_id;
 INSERT INTO club_publication_audit(club_id,announcement_id,actor_user_id,actor_assignment_id,action,
   before_snapshot,after_snapshot,created_at)
 VALUES(club_id_value,target_id_value,pg_temp.presentation_uid('sadia_afrin'),assignment_id_value,'PUBLISHED',
   jsonb_build_object('announcementId',target_id_value,'status','UNPUBLISHED')::text,
   jsonb_build_object('announcementId',target_id_value,'status','PUBLISHED')::text,now_utc-interval '8 days'+interval '5 minutes');
 INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,
   target_owner_user_id,parent_club_id,reviewer_id,submitted_at,review_started_at,resolved_at,resolution_summary,internal_notes)
 VALUES(pg_temp.presentation_uid('nabila_sultana'),'ANNOUNCEMENT',target_id_value,
   'This appears to duplicate the earlier prototype registration promotion.','ACTION_TAKEN',
   'Repeated prototype registration reminder',
   jsonb_build_object('id',target_id_value,'clubId',club_id_value,'title','Repeated prototype registration reminder',
     'content','A fictional duplicate reminder retained only as a moderation-history example.',
     'priority','NORMAL','status','PUBLISHED','authorUserId',pg_temp.presentation_uid('sadia_afrin'))::text,
   pg_temp.presentation_uid('sadia_afrin'),club_id_value,pg_temp.presentation_uid('admin_ayman'),
   now_utc-interval '5 days',now_utc-interval '4 days',now_utc-interval '2 days',
   'The duplicate announcement was removed after comparison with the original post.',
   'Confirmed that the earlier registration announcement remains available.')
 RETURNING report_id INTO report_id_value;
 INSERT INTO uniconnect_presentation_seed_keys VALUES
   ('presentation-2026-v1','REPORT','announcement-action-taken',report_id_value,now_utc);
 INSERT INTO report_audit_logs(report_id,actor_id,event_type,previous_status,new_status,internal_note,occurred_at) VALUES
   (report_id_value,pg_temp.presentation_uid('nabila_sultana'),'SUBMITTED',NULL,'SUBMITTED',NULL,now_utc-interval '5 days'),
   (report_id_value,pg_temp.presentation_uid('admin_ayman'),'UNDER_REVIEW','SUBMITTED','UNDER_REVIEW',
     'Comparing the two fictional registration announcements.',now_utc-interval '4 days');
 INSERT INTO club_publication_audit(club_id,announcement_id,actor_user_id,actor_assignment_id,action,reason,
   before_snapshot,after_snapshot,created_at)
 VALUES(club_id_value,target_id_value,pg_temp.presentation_uid('sadia_afrin'),assignment_id_value,'REMOVED',
   'Removed a duplicate fictional promotional reminder after administrator review.',
   jsonb_build_object('announcementId',target_id_value,'status','PUBLISHED')::text,
   jsonb_build_object('announcementId',target_id_value,'status','REMOVED')::text,now_utc-interval '2 days')
 RETURNING audit_id INTO removal_audit_id;
 INSERT INTO report_action_links(report_id,evidence_source,evidence_id,action_type,subject_type,subject_id,
   action_occurred_at,linked_by,linked_at)
 VALUES(report_id_value,'PUBLICATION',removal_audit_id,'REMOVED','ANNOUNCEMENT',target_id_value,
   now_utc-interval '2 days',pg_temp.presentation_uid('admin_ayman'),now_utc-interval '2 days'+interval '1 minute');
 INSERT INTO report_audit_logs(report_id,actor_id,event_type,previous_status,new_status,internal_note,occurred_at)
 VALUES(report_id_value,pg_temp.presentation_uid('admin_ayman'),'ACTION_TAKEN','UNDER_REVIEW','ACTION_TAKEN',
   'Linked the committed announcement removal audit.',now_utc-interval '2 days'+interval '1 minute');
 INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at)
 VALUES(pg_temp.presentation_uid('nabila_sultana'),'REPORT_RESOLVED','Report resolved',
   'Your report was reviewed and action was taken.','REPORT',report_id_value,
   'report-resolution:'||report_id_value,now_utc-interval '2 days'+interval '1 minute');

 club_id_value:=pg_temp.presentation_eid('CLUB','career');
 assignment_id_value:=pg_temp.presentation_eid('CLUB_ASSIGNMENT','career-admin');
 INSERT INTO club_events(club_id,author_user_id,author_assignment_id,title,description,location,registration_url,
   registration_deadline,starts_at,ends_at,status,published_at,updated_at,removed_at)
 VALUES(club_id_value,pg_temp.presentation_uid('sabrina_haque'),assignment_id_value,
   'Duplicate internship briefing listing','A fictional duplicate event used only for moderation evidence.',
   'IUT Seminar Room','https://events.example.test/duplicate-briefing',now_utc+interval '8 days',
   now_utc+interval '9 days',now_utc+interval '9 days 2 hours','REMOVED',now_utc-interval '7 days',
   now_utc-interval '1 day',now_utc-interval '1 day') RETURNING event_id INTO target_id_value;
 INSERT INTO uniconnect_presentation_seed_keys VALUES
   ('presentation-2026-v1','EVENT','moderated-duplicate-briefing',target_id_value,now_utc);
 INSERT INTO club_publication_audit(club_id,event_id,actor_user_id,actor_assignment_id,action,
   before_snapshot,after_snapshot,created_at)
 VALUES(club_id_value,target_id_value,pg_temp.presentation_uid('sabrina_haque'),assignment_id_value,'CREATED',NULL,
   jsonb_build_object('eventId',target_id_value,'title','Duplicate internship briefing listing','status','PUBLISHED')::text,
   now_utc-interval '7 days');
 INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,
   target_owner_user_id,parent_club_id,reviewer_id,submitted_at,review_started_at,resolved_at,resolution_summary,internal_notes)
 VALUES(pg_temp.presentation_uid('arif_hossain'),'EVENT',target_id_value,
   'This event repeats an internship briefing with conflicting registration details.','ACTION_TAKEN',
   'Duplicate internship briefing listing',
   jsonb_build_object('id',target_id_value,'clubId',club_id_value,'title','Duplicate internship briefing listing',
     'description','A fictional duplicate event used only for moderation evidence.','status','PUBLISHED',
     'authorUserId',pg_temp.presentation_uid('sabrina_haque'))::text,
   pg_temp.presentation_uid('sabrina_haque'),club_id_value,pg_temp.presentation_uid('admin_sayma'),
   now_utc-interval '4 days',now_utc-interval '3 days',now_utc-interval '1 day',
   'The duplicate event was removed so the canonical briefing remains unambiguous.',
   'Verified the duplicate schedule and registration link before removal.')
 RETURNING report_id INTO report_id_value;
 INSERT INTO uniconnect_presentation_seed_keys VALUES
   ('presentation-2026-v1','REPORT','event-action-taken',report_id_value,now_utc);
 INSERT INTO report_audit_logs(report_id,actor_id,event_type,previous_status,new_status,internal_note,occurred_at) VALUES
   (report_id_value,pg_temp.presentation_uid('arif_hossain'),'SUBMITTED',NULL,'SUBMITTED',NULL,now_utc-interval '4 days'),
   (report_id_value,pg_temp.presentation_uid('admin_sayma'),'UNDER_REVIEW','SUBMITTED','UNDER_REVIEW',
     'Checking the fictional event schedule and registration details.',now_utc-interval '3 days');
 INSERT INTO club_publication_audit(club_id,event_id,actor_user_id,actor_assignment_id,action,reason,
   before_snapshot,after_snapshot,created_at)
 VALUES(club_id_value,target_id_value,pg_temp.presentation_uid('sabrina_haque'),assignment_id_value,'REMOVED',
   'Removed a duplicate fictional briefing after administrator review.',
   jsonb_build_object('eventId',target_id_value,'status','PUBLISHED')::text,
   jsonb_build_object('eventId',target_id_value,'status','REMOVED')::text,now_utc-interval '1 day')
 RETURNING audit_id INTO removal_audit_id;
 INSERT INTO report_action_links(report_id,evidence_source,evidence_id,action_type,subject_type,subject_id,
   action_occurred_at,linked_by,linked_at)
 VALUES(report_id_value,'PUBLICATION',removal_audit_id,'REMOVED','EVENT',target_id_value,
   now_utc-interval '1 day',pg_temp.presentation_uid('admin_sayma'),now_utc-interval '1 day'+interval '1 minute');
 INSERT INTO report_audit_logs(report_id,actor_id,event_type,previous_status,new_status,internal_note,occurred_at)
 VALUES(report_id_value,pg_temp.presentation_uid('admin_sayma'),'ACTION_TAKEN','UNDER_REVIEW','ACTION_TAKEN',
   'Linked the committed event removal audit.',now_utc-interval '1 day'+interval '1 minute');
 INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at)
 VALUES(pg_temp.presentation_uid('arif_hossain'),'REPORT_RESOLVED','Report resolved',
   'Your report was reviewed and action was taken.','REPORT',report_id_value,
   'report-resolution:'||report_id_value,now_utc-interval '1 day'+interval '1 minute');
END
$moderated_publications$;

DO $additional_reports$
DECLARE
 now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
 report_id_value bigint;
 target_id_value bigint;
 club_id_value bigint;
BEGIN
 -- Open user report ready to claim.
 target_id_value:=pg_temp.presentation_uid('rayhan_kabir');
 INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,
   target_owner_user_id,submitted_at,open_reporter_id,open_target_type,open_target_id)
 SELECT pg_temp.presentation_uid('mariam_akter'),'USER',target_id_value,
   'The profile appears to repeat an unrelated project promotion.','SUBMITTED',u.full_name,
   jsonb_build_object('userId',u.user_id,'fullName',u.full_name,'platformRole',u.platform_role,
     'profilePhotoUrl',p.profile_photo_url,'bio',p.bio)::text,u.user_id,now_utc-interval '18 hours',
   pg_temp.presentation_uid('mariam_akter'),'USER',target_id_value
 FROM users u LEFT JOIN personal_profiles p ON p.user_id=u.user_id WHERE u.user_id=target_id_value
 RETURNING report_id INTO report_id_value;
 INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','REPORT','user-submitted',report_id_value,now_utc);
 INSERT INTO report_audit_logs VALUES(DEFAULT,report_id_value,pg_temp.presentation_uid('mariam_akter'),'SUBMITTED',NULL,'SUBMITTED',NULL,now_utc-interval '18 hours');

 -- Open club report already owned by an administrator.
 club_id_value:=pg_temp.presentation_eid('CLUB','robotics');
 INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,parent_club_id,
   reviewer_id,submitted_at,review_started_at,internal_notes,open_reporter_id,open_target_type,open_target_id)
 SELECT pg_temp.presentation_uid('hafsa_mahjabin'),'CLUB',club_id_value,
   'Several recent descriptions appear to repeat the same promotional wording.','UNDER_REVIEW',c.club_name,
   jsonb_build_object('clubId',c.club_id,'clubName',c.club_name,'category',c.category,'description',c.description,
     'logoUrl',c.logo_url,'status',c.status)::text,c.club_id,pg_temp.presentation_uid('admin_ayman'),
   now_utc-interval '30 hours',now_utc-interval '8 hours','Comparing presentation-owned club descriptions.',
   pg_temp.presentation_uid('hafsa_mahjabin'),'CLUB',club_id_value
 FROM clubs c WHERE c.club_id=club_id_value RETURNING report_id INTO report_id_value;
 INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','REPORT','club-under-review',report_id_value,now_utc);
 INSERT INTO report_audit_logs VALUES
   (DEFAULT,report_id_value,pg_temp.presentation_uid('hafsa_mahjabin'),'SUBMITTED',NULL,'SUBMITTED',NULL,now_utc-interval '30 hours'),
   (DEFAULT,report_id_value,pg_temp.presentation_uid('admin_ayman'),'UNDER_REVIEW','SUBMITTED','UNDER_REVIEW',
     'Comparing presentation-owned club descriptions.',now_utc-interval '8 hours');

 -- Accessible chat message: Zubair is a participant in club-planning and Sadia is the sender.
 SELECT m.message_id INTO target_id_value FROM chat_messages m
 JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1'
   AND k.entity_type='CONVERSATION' AND k.logical_key='club-planning' AND k.entity_id=m.conversation_id
 WHERE m.sender_id=pg_temp.presentation_uid('sadia_afrin') ORDER BY m.sent_at DESC,m.message_id DESC LIMIT 1;
 IF NOT EXISTS(SELECT 1 FROM chat_participants cp JOIN chat_messages m ON m.conversation_id=cp.conversation_id
   WHERE m.message_id=target_id_value AND cp.user_id=pg_temp.presentation_uid('zubair_ahmed')) THEN
  RAISE EXCEPTION 'Chat report fixture reporter lacks target-message access';
 END IF;
 INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,
   target_owner_user_id,submitted_at,open_reporter_id,open_target_type,open_target_id)
 SELECT pg_temp.presentation_uid('zubair_ahmed'),'CHAT_MESSAGE',m.message_id,
   'This follow-up appears off-topic for the volunteer-planning thread.','SUBMITTED','Chat message '||m.message_id,
   jsonb_build_object('id',m.message_id,'conversationId',m.conversation_id,'senderId',m.sender_id,
     'content',m.content,'sentAt',m.sent_at)::text,m.sender_id,now_utc-interval '12 hours',
   pg_temp.presentation_uid('zubair_ahmed'),'CHAT_MESSAGE',m.message_id
 FROM chat_messages m WHERE m.message_id=target_id_value RETURNING report_id INTO report_id_value;
 INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','REPORT','chat-submitted',report_id_value,now_utc);
 INSERT INTO report_audit_logs VALUES(DEFAULT,report_id_value,pg_temp.presentation_uid('zubair_ahmed'),'SUBMITTED',NULL,'SUBMITTED',NULL,now_utc-interval '12 hours');

 -- Dismissed user report.
 target_id_value:=pg_temp.presentation_uid('hamza_chowdhury');
 INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,target_owner_user_id,
   reviewer_id,submitted_at,review_started_at,resolved_at,resolution_summary,internal_notes)
 SELECT pg_temp.presentation_uid('aisha_siddika'),'USER',u.user_id,
   'The profile summary may overstate participation in a fictional campus activity.','NO_ACTION',u.full_name,
   jsonb_build_object('userId',u.user_id,'fullName',u.full_name,'platformRole',u.platform_role,
     'profilePhotoUrl',p.profile_photo_url,'bio',p.bio)::text,u.user_id,pg_temp.presentation_uid('admin_sayma'),
   now_utc-interval '6 days',now_utc-interval '5 days',now_utc-interval '4 days',
   'No policy issue was found; the profile describes general interests rather than a factual claim.',
   'Reviewed the retained profile snapshot and dismissed the mild fictional concern.'
 FROM users u LEFT JOIN personal_profiles p ON p.user_id=u.user_id WHERE u.user_id=target_id_value
 RETURNING report_id INTO report_id_value;
 INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','REPORT','user-no-action',report_id_value,now_utc);
 INSERT INTO report_audit_logs VALUES
   (DEFAULT,report_id_value,pg_temp.presentation_uid('aisha_siddika'),'SUBMITTED',NULL,'SUBMITTED',NULL,now_utc-interval '6 days'),
   (DEFAULT,report_id_value,pg_temp.presentation_uid('admin_sayma'),'UNDER_REVIEW','SUBMITTED','UNDER_REVIEW',
     'Reviewing the retained profile snapshot.',now_utc-interval '5 days'),
   (DEFAULT,report_id_value,pg_temp.presentation_uid('admin_sayma'),'NO_ACTION','UNDER_REVIEW','NO_ACTION',
     'No unsupported claim or policy issue was present.',now_utc-interval '4 days');
 INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at,read_at)
 VALUES(pg_temp.presentation_uid('aisha_siddika'),'REPORT_RESOLVED','Report resolved',
   'Your report was reviewed and no action was taken.','REPORT',report_id_value,
   'report-resolution:'||report_id_value,now_utc-interval '4 days',now_utc-interval '3 days');

 -- Dismissed club report.
 club_id_value:=pg_temp.presentation_eid('CLUB','career');
 INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,parent_club_id,
   reviewer_id,submitted_at,review_started_at,resolved_at,resolution_summary,internal_notes)
 SELECT pg_temp.presentation_uid('jannat_ferdous'),'CLUB',c.club_id,
   'The club description looks similar to another career promotion.','NO_ACTION',c.club_name,
   jsonb_build_object('clubId',c.club_id,'clubName',c.club_name,'category',c.category,'description',c.description,
     'logoUrl',c.logo_url,'status',c.status)::text,c.club_id,pg_temp.presentation_uid('admin_ayman'),
   now_utc-interval '7 days',now_utc-interval '6 days',now_utc-interval '5 days',
   'The wording is relevant to the club purpose and does not duplicate a publication.',
   'Compared the club description with its fictional announcements.'
 FROM clubs c WHERE c.club_id=club_id_value RETURNING report_id INTO report_id_value;
 INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','REPORT','club-no-action',report_id_value,now_utc);
 INSERT INTO report_audit_logs VALUES
   (DEFAULT,report_id_value,pg_temp.presentation_uid('jannat_ferdous'),'SUBMITTED',NULL,'SUBMITTED',NULL,now_utc-interval '7 days'),
   (DEFAULT,report_id_value,pg_temp.presentation_uid('admin_ayman'),'UNDER_REVIEW','SUBMITTED','UNDER_REVIEW',
     'Comparing the club description with presentation publications.',now_utc-interval '6 days'),
   (DEFAULT,report_id_value,pg_temp.presentation_uid('admin_ayman'),'NO_ACTION','UNDER_REVIEW','NO_ACTION',
     'The description is relevant and not a duplicate publication.',now_utc-interval '5 days');
 INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at)
 VALUES(pg_temp.presentation_uid('jannat_ferdous'),'REPORT_RESOLVED','Report resolved',
   'Your report was reviewed and no action was taken.','REPORT',report_id_value,
   'report-resolution:'||report_id_value,now_utc-interval '5 days');

 -- Existing published event under investigation; no state-changing action has been taken.
 SELECT e.event_id,e.club_id INTO target_id_value,club_id_value FROM club_events e
 JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1'
   AND k.entity_type='CLUB' AND k.logical_key='innovation' AND k.entity_id=e.club_id
 WHERE e.title='Open Source Orientation';
 INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,
   target_owner_user_id,parent_club_id,reviewer_id,submitted_at,review_started_at,internal_notes,
   open_reporter_id,open_target_type,open_target_id)
 SELECT pg_temp.presentation_uid('samira_khan'),'EVENT',e.event_id,
   'The completed event still appears to show outdated participation details.','UNDER_REVIEW',e.title,
   jsonb_build_object('id',e.event_id,'clubId',e.club_id,'title',e.title,'description',e.description,
     'location',e.location,'registrationUrl',e.registration_url,'startsAt',e.starts_at,'endsAt',e.ends_at,
     'status',e.status,'authorUserId',e.author_user_id)::text,e.author_user_id,e.club_id,
   pg_temp.presentation_uid('admin_sayma'),now_utc-interval '26 hours',now_utc-interval '6 hours',
   'Checking whether historical event visibility matches the implemented policy.',
   pg_temp.presentation_uid('samira_khan'),'EVENT',e.event_id
 FROM club_events e WHERE e.event_id=target_id_value RETURNING report_id INTO report_id_value;
 INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','REPORT','event-under-review',report_id_value,now_utc);
 INSERT INTO report_audit_logs VALUES
   (DEFAULT,report_id_value,pg_temp.presentation_uid('samira_khan'),'SUBMITTED',NULL,'SUBMITTED',NULL,now_utc-interval '26 hours'),
   (DEFAULT,report_id_value,pg_temp.presentation_uid('admin_sayma'),'UNDER_REVIEW','SUBMITTED','UNDER_REVIEW',
     'Checking historical event visibility against the current policy.',now_utc-interval '6 hours');
END
$additional_reports$;

DO $verify_upgrade$
DECLARE failures text := '';
BEGIN
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys
   WHERE dataset_key='presentation-2026-v1' AND entity_type='REPORT')<>10 THEN failures:=failures||' report-map-count'; END IF;
 IF (SELECT count(*) FROM content_reports r JOIN uniconnect_presentation_seed_keys k ON k.entity_id=r.report_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT')<>10 THEN failures:=failures||' report-row-count'; END IF;
 IF (SELECT count(*) FROM report_action_links l JOIN uniconnect_presentation_seed_keys k ON k.entity_id=l.report_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT')<>2 THEN failures:=failures||' action-link-count'; END IF;
 IF EXISTS(SELECT 1 FROM report_action_links l JOIN content_reports r ON r.report_id=l.report_id
   LEFT JOIN club_publication_audit a ON l.evidence_source='PUBLICATION' AND a.audit_id=l.evidence_id
   WHERE l.evidence_source='PUBLICATION' AND (a.audit_id IS NULL OR a.action<>'REMOVED'
     OR l.subject_id<>COALESCE(a.announcement_id,a.event_id) OR l.action_occurred_at<>a.created_at
     OR r.status<>'ACTION_TAKEN' OR l.action_occurred_at<r.submitted_at)) THEN failures:=failures||' action-evidence'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
   AND (r.reporter_id IN (pg_temp.presentation_uid('admin_ayman'),pg_temp.presentation_uid('admin_sayma'))
     OR r.target_owner_user_id IN (pg_temp.presentation_uid('admin_ayman'),pg_temp.presentation_uid('admin_sayma'))))
   THEN failures:=failures||' named-admin-target'; END IF;
 IF NOT EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys rk JOIN content_reports r ON r.report_id=rk.entity_id
   JOIN chat_messages m ON r.target_type='CHAT_MESSAGE' AND m.message_id=r.target_id
   JOIN chat_participants p ON p.conversation_id=m.conversation_id AND p.user_id=r.reporter_id
   WHERE rk.dataset_key='presentation-2026-v1' AND rk.entity_type='REPORT' AND rk.logical_key='chat-submitted')
   THEN failures:=failures||' chat-access'; END IF;
 IF failures<>'' THEN RAISE EXCEPTION 'Presentation report upgrade verification failed:%',failures; END IF;
END
$verify_upgrade$;

UPDATE uniconnect_presentation_seed_manifest SET seed_version=4
WHERE dataset_key='presentation-2026-v1' AND seed_version=3;
