-- Read-only pristine checks. Use before starting the backend or performing logins.
BEGIN TRANSACTION READ ONLY;
SET LOCAL search_path = public, pg_catalog;
SET LOCAL TIME ZONE 'UTC';
\ir checks.sql
SELECT seed_version,seeded_at,base_date FROM uniconnect_demo_seed_manifest;
SELECT user_id,full_name,email,platform_role,account_status FROM users ORDER BY user_id;
SELECT s.slot_id,s.topic,s.status,s.enrollment_open,s.capacity,s.current_mentee_count,
    s.meeting_count,count(o.occurrence_id) AS persisted_occurrences
FROM mentorship_slots s JOIN mentorship_occurrences o USING(slot_id)
GROUP BY s.slot_id ORDER BY s.slot_id;
COMMIT;
