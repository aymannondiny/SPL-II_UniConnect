-- UniConnect demo fixture v1, based on main 5e5f9959c12fd61279839de1cc34c806c08b2151.
-- Opt-in local/demo data, NEVER a Flyway migration. Run via seed.sh with backend stopped.
BEGIN;
SET LOCAL search_path = public, pg_catalog;
SET LOCAL TIME ZONE 'UTC';
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SELECT pg_advisory_xact_lock(26102501);

DO $guard$
BEGIN
    -- CONNECTION_GUARD_BEGIN (only this guard is substituted in the embedded validation harness)
    IF inet_server_addr() IS NULL OR inet_server_addr() NOT IN ('127.0.0.1'::inet, '::1'::inet) THEN
        RAISE EXCEPTION 'Seed requires a loopback TCP PostgreSQL connection.';
    END IF;
    -- CONNECTION_GUARD_END
    IF current_database() <> 'uniconnect_demo' THEN
        RAISE EXCEPTION 'Seed requires a dedicated database named uniconnect_demo.';
    END IF;
    IF to_regclass('public.flyway_schema_history') IS NULL THEN
        RAISE EXCEPTION 'Start the current backend normally to apply migrations first.';
    END IF;
    IF (SELECT count(*) FROM flyway_schema_history WHERE version IS NOT NULL) <> 26
       OR EXISTS (SELECT 1 FROM flyway_schema_history WHERE NOT success)
       OR EXISTS (SELECT 1 FROM generate_series(1,26) AS expected(v)
           WHERE NOT EXISTS (SELECT 1 FROM flyway_schema_history h WHERE h.version=expected.v::text AND h.success))
       OR NOT EXISTS (SELECT 1 FROM flyway_schema_history WHERE version='26' AND script='db.migration.V26__correct_mentorship_lifecycle' AND success) THEN
        RAISE EXCEPTION 'Expected successful Flyway V1-V26. No schema changes will be made.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public'
        AND table_name='mentorship_enrollments' AND column_name='active_marker') THEN
        RAISE EXCEPTION 'Missing V26 enrollment contract.';
    END IF;
END
$guard$;

-- This metadata belongs only to the dedicated demo database, not application migrations.
CREATE TABLE IF NOT EXISTS uniconnect_demo_seed_manifest (
    seed_version integer PRIMARY KEY CHECK (seed_version=1),
    seeded_at timestamp NOT NULL,
    base_date date NOT NULL,
    data_fingerprint text NOT NULL
);

CREATE OR REPLACE FUNCTION pg_temp.demo_fingerprint() RETURNS text LANGUAGE plpgsql AS $fingerprint$
DECLARE t record; table_hash text; all_hashes text := '';
BEGIN
    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='public'
        AND tablename NOT IN ('flyway_schema_history','uniconnect_demo_seed_manifest') ORDER BY tablename
    LOOP
        EXECUTE format('SELECT md5(coalesce(string_agg(to_jsonb(r)::text, '''' ORDER BY to_jsonb(r)::text), '''')) FROM public.%I r',t.tablename) INTO table_hash;
        all_hashes := all_hashes || t.tablename || ':' || table_hash || ';';
    END LOOP;
    RETURN md5(all_hashes);
END
$fingerprint$;

DO $seed$
DECLARE
    seed_now timestamp := date_trunc('second', CURRENT_TIMESTAMP AT TIME ZONE 'UTC');
    seed_date date := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Dhaka')::date;
    t record;
    has_rows boolean;
BEGIN
    -- Block concurrent writers while checking and inserting the demo rows.
    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename LOOP
        EXECUTE format('LOCK TABLE public.%I IN SHARE ROW EXCLUSIVE MODE',t.tablename);
    END LOOP;
    IF EXISTS (SELECT 1 FROM uniconnect_demo_seed_manifest) THEN
        IF (SELECT data_fingerprint FROM uniconnect_demo_seed_manifest WHERE seed_version=1)
            IS DISTINCT FROM pg_temp.demo_fingerprint() THEN
            RAISE EXCEPTION 'Demo data changed since seeding. Refusing to overwrite or reseed; use a NEW demo database.';
        END IF;
        RAISE NOTICE 'Unchanged fixture already present; seed is a no-op.';
        RETURN;
    END IF;
    IF (SELECT count(*) FROM application_metadata) <> 1 OR NOT EXISTS(SELECT 1 FROM application_metadata WHERE metadata_key='schema_version' AND metadata_value='1') THEN
        RAISE EXCEPTION 'Expected only the application_metadata row installed by V1.';
    END IF;
    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='public'
        AND tablename NOT IN ('flyway_schema_history','uniconnect_demo_seed_manifest','application_metadata') LOOP
        EXECUTE format('SELECT EXISTS(SELECT 1 FROM public.%I)',t.tablename) INTO has_rows;
        IF has_rows THEN RAISE EXCEPTION 'Database is not empty (%). Nothing seeded.',t.tablename; END IF;
    END LOOP;
-- 1. Synthetic accounts; one documented demo-only BCrypt password

INSERT INTO users (user_id, full_name, email, password_hash, platform_role, account_status, created_at, updated_at) VALUES
    (1, 'System Admin', 'system.admin@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'SYSTEM_ADMIN', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (2, 'Project Creator', 'project.creator@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (3, 'Complete Match', 'complete.match@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (4, 'Connected Match', 'connected.match@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (5, 'Interest Match', 'interest.match@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (6, 'Unavailable Student', 'unavailable.student@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (7, 'Hidden Student', 'hidden.student@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (8, 'Python Student', 'python.student@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (9, 'Student Mentor', 'student.mentor@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (10, 'Alumni Mentor', 'alumni.mentor@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'ALUMNI', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (11, 'Student Mentee', 'student.mentee@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (12, 'Alumni Mentee', 'alumni.mentee@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'ALUMNI', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (13, 'Club Admin', 'club.admin@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (14, 'Club Representative', 'club.representative@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (15, 'Club Co Admin', 'club.co.admin@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (16, 'Career Author', 'career.author@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'ALUMNI', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (17, 'Student Reporter', 'student.reporter@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (18, 'Student Outsider', 'student.outsider@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (19, 'Suspended Student', 'suspended.student@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'SUSPENDED', seed_now - INTERVAL '30 days', seed_now - INTERVAL '1 days'),
    (20, 'Pending Student', 'pending.student@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'PENDING_VERIFICATION', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (21, 'New Student', 'new.student@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (22, 'Alumni Member', 'alumni.member@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'ALUMNI', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (23, 'Engineering Student', 'engineering.student@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (24, 'Business Student', 'business.student@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (25, 'Unavailable Mentor', 'unavailable.mentor@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'ALUMNI', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days'),
    (26, 'Project Applicant', 'project.applicant@iut-dhaka.edu', '$2b$10$8z5hVJ2vIAgtgEM3aj/feOIsWH6xY1F6ib9B3KsPDjnhmjcMUO.fC', 'STUDENT', 'ACTIVE', seed_now - INTERVAL '30 days', seed_now - INTERVAL '30 days');

-- 2. Academic catalogue and canonical lowercase vocabulary

INSERT INTO departments (department_id, department_name, department_code) VALUES
    (1, 'Computer Science and Engineering', 'CSE'),
    (2, 'Electrical and Electronic Engineering', 'EEE'),
    (3, 'Business and Technology Management', 'BTM');

INSERT INTO programmes (programme_id, department_id, programme_name, programme_code) VALUES
    (1, 1, 'Software Engineering', 'SWE'),
    (2, 1, 'Computer Science and Engineering', 'CSE'),
    (3, 2, 'Electrical and Electronic Engineering', 'EEE'),
    (4, 3, 'Business and Technology Management', 'BTM');

INSERT INTO programme_degrees (programme_degree_id, programme_id, degree_level, duration_years, minimum_year, maximum_year, active) VALUES
    (1, 1, 'BACHELOR', 4, 1, 4, TRUE),
    (2, 2, 'BACHELOR', 4, 1, 4, TRUE),
    (3, 3, 'BACHELOR', 4, 1, 4, TRUE),
    (4, 4, 'BACHELOR', 4, 1, 4, TRUE);

INSERT INTO skills (skill_id, name, category) VALUES
    (1, 'java', 'demo'),
    (2, 'sql', 'demo'),
    (3, 'docker', 'demo'),
    (4, 'git', 'demo'),
    (5, 'python', 'demo'),
    (6, 'flutter', 'demo'),
    (7, 'dart', 'demo'),
    (8, 'javascript', 'demo'),
    (9, 'react', 'demo'),
    (10, 'postgresql', 'demo'),
    (11, 'c', 'demo'),
    (12, 'machine learning', 'demo'),
    (13, 'excel', 'demo'),
    (14, 'data analysis', 'demo'),
    (15, 'spring boot', 'demo'),
    (16, 'circuit design', 'demo');

INSERT INTO interests (interest_id, name) VALUES
    (1, 'ai'),
    (2, 'distributed systems'),
    (3, 'mobile development'),
    (4, 'web development'),
    (5, 'robotics'),
    (6, 'entrepreneurship'),
    (7, 'cybersecurity'),
    (8, 'data science');

-- 3. Role-correct profiles, privacy and skill associations

INSERT INTO personal_profiles (profile_id, user_id, profile_type, programme_degree_id, bio, created_at, updated_at, details_visibility, student_number, year_of_study, expected_graduation_year, project_availability, mentorship_availability, graduation_year, current_company, current_position, industry, career_background, linkedin_url) VALUES
    (2, 2, 'STUDENT', 1, 'Demo profile: Project Creator.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-002', 3, EXTRACT(YEAR FROM seed_date)::integer + 1, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (3, 3, 'STUDENT', 1, 'Demo profile: Complete Match.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-003', 4, EXTRACT(YEAR FROM seed_date)::integer + 0, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (4, 4, 'STUDENT', 1, 'Demo profile: Connected Match.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'CONNECTIONS_ONLY', 'DEMO-STUDENT-004', 1, EXTRACT(YEAR FROM seed_date)::integer + 3, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (5, 5, 'STUDENT', 1, 'Demo profile: Interest Match.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-005', 2, EXTRACT(YEAR FROM seed_date)::integer + 2, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (6, 6, 'STUDENT', 1, 'Demo profile: Unavailable Student.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-006', 3, EXTRACT(YEAR FROM seed_date)::integer + 1, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (7, 7, 'STUDENT', 1, 'Demo profile: Hidden Student.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'CONNECTIONS_ONLY', 'DEMO-STUDENT-007', 4, EXTRACT(YEAR FROM seed_date)::integer + 0, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (8, 8, 'STUDENT', 2, 'Demo profile: Python Student.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-008', 1, EXTRACT(YEAR FROM seed_date)::integer + 3, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (9, 9, 'STUDENT', 1, 'Demo profile: Student Mentor.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-009', 2, EXTRACT(YEAR FROM seed_date)::integer + 2, FALSE, TRUE, NULL, NULL, NULL, NULL, NULL, NULL),
    (10, 10, 'ALUMNI', 1, 'Demo profile: Alumni Mentor.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', NULL, NULL, NULL, NULL, NULL, 2018, 'Demo Labs', 'Senior Engineer', 'Software', 'Synthetic career history for demonstration.', NULL),
    (11, 11, 'STUDENT', 2, 'Demo profile: Student Mentee.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-011', 4, EXTRACT(YEAR FROM seed_date)::integer + 0, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (12, 12, 'ALUMNI', 1, 'Demo profile: Alumni Mentee.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'CONNECTIONS_ONLY', NULL, NULL, NULL, NULL, NULL, 2022, 'Demo Labs', 'Software Engineer', 'Software', 'Synthetic career history for demonstration.', NULL),
    (13, 13, 'STUDENT', 1, 'Demo profile: Club Admin.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-013', 2, EXTRACT(YEAR FROM seed_date)::integer + 2, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (14, 14, 'STUDENT', 1, 'Demo profile: Club Representative.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-014', 3, EXTRACT(YEAR FROM seed_date)::integer + 1, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (15, 15, 'STUDENT', 1, 'Demo profile: Club Co Admin.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-015', 4, EXTRACT(YEAR FROM seed_date)::integer + 0, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (16, 16, 'ALUMNI', 1, 'Demo profile: Career Author.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', NULL, NULL, NULL, NULL, NULL, 2022, 'Demo Labs', 'Software Engineer', 'Software', 'Synthetic career history for demonstration.', NULL),
    (17, 17, 'STUDENT', 1, 'Demo profile: Student Reporter.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-017', 2, EXTRACT(YEAR FROM seed_date)::integer + 2, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (18, 18, 'STUDENT', 2, 'Demo profile: Student Outsider.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-018', 3, EXTRACT(YEAR FROM seed_date)::integer + 1, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (19, 19, 'STUDENT', 1, 'Demo profile: Suspended Student.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-019', 4, EXTRACT(YEAR FROM seed_date)::integer + 0, FALSE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (22, 22, 'ALUMNI', 1, 'Demo profile: Alumni Member.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', NULL, NULL, NULL, NULL, NULL, 2022, 'Demo Labs', 'Software Engineer', 'Software', 'Synthetic career history for demonstration.', NULL),
    (23, 23, 'STUDENT', 3, 'Demo profile: Engineering Student.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-023', 4, EXTRACT(YEAR FROM seed_date)::integer + 0, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (24, 24, 'STUDENT', 4, 'Demo profile: Business Student.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-024', 1, EXTRACT(YEAR FROM seed_date)::integer + 3, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL),
    (25, 25, 'ALUMNI', 1, 'Demo profile: Unavailable Mentor.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', NULL, NULL, NULL, NULL, NULL, 2022, 'Demo Labs', 'Software Engineer', 'Software', 'Synthetic career history for demonstration.', NULL),
    (26, 26, 'STUDENT', 1, 'Demo profile: Project Applicant.', seed_now - INTERVAL '30 days', seed_now - INTERVAL '10 days', 'ALL_MEMBERS', 'DEMO-STUDENT-026', 3, EXTRACT(YEAR FROM seed_date)::integer + 1, TRUE, FALSE, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO profile_skills (profile_id, skill_id) VALUES
    (2, 1),
    (2, 2),
    (2, 3),
    (2, 4),
    (3, 1),
    (3, 2),
    (3, 3),
    (3, 4),
    (4, 2),
    (4, 4),
    (5, 1),
    (6, 1),
    (6, 2),
    (6, 3),
    (6, 4),
    (7, 1),
    (7, 2),
    (7, 3),
    (7, 4),
    (8, 5),
    (9, 1),
    (9, 10),
    (9, 15),
    (10, 1),
    (10, 2),
    (10, 10),
    (10, 15),
    (11, 6),
    (11, 7),
    (12, 5),
    (12, 14),
    (13, 8),
    (13, 9),
    (14, 8),
    (15, 6),
    (15, 7),
    (16, 1),
    (16, 2),
    (16, 3),
    (16, 4),
    (17, 5),
    (18, 5),
    (19, 1),
    (22, 5),
    (22, 12),
    (23, 11),
    (23, 16),
    (24, 13),
    (24, 14),
    (25, 5),
    (25, 12),
    (26, 5);

INSERT INTO profile_interests (profile_id, interest_id) VALUES
    (2, 1),
    (2, 2),
    (3, 1),
    (3, 2),
    (5, 1),
    (6, 1),
    (6, 2),
    (7, 1),
    (7, 2),
    (8, 8),
    (9, 2),
    (9, 7),
    (10, 2),
    (11, 3),
    (12, 8),
    (13, 4),
    (14, 4),
    (15, 3),
    (16, 2),
    (17, 8),
    (18, 5),
    (19, 7),
    (22, 1),
    (22, 8),
    (23, 5),
    (24, 6),
    (25, 1),
    (26, 8);

-- 4. Connections: accepted, pending and retained closed periods

INSERT INTO connections (connection_id, requester_id, receiver_id, user_low, user_high, open_low, open_high, status, introductory_message, requested_at, accepted_at, closed_at) VALUES
    (1, 2, 3, 2, 3, 2, 3, 'ACCEPTED', 'Demo connection request.', seed_now - INTERVAL '20 days', seed_now - INTERVAL '19 days', NULL),
    (2, 2, 4, 2, 4, 2, 4, 'ACCEPTED', 'Demo connection request.', seed_now - INTERVAL '20 days', seed_now - INTERVAL '19 days', NULL),
    (3, 9, 11, 9, 11, 9, 11, 'ACCEPTED', 'Demo connection request.', seed_now - INTERVAL '20 days', seed_now - INTERVAL '19 days', NULL),
    (4, 13, 17, 13, 17, 13, 17, 'ACCEPTED', 'Demo connection request.', seed_now - INTERVAL '20 days', seed_now - INTERVAL '19 days', NULL),
    (5, 10, 12, 10, 12, 10, 12, 'ACCEPTED', 'Demo connection request.', seed_now - INTERVAL '20 days', seed_now - INTERVAL '19 days', NULL),
    (6, 13, 18, 13, 18, 13, 18, 'PENDING', 'Demo connection request.', seed_now - INTERVAL '20 days', NULL, NULL),
    (7, 8, 23, 8, 23, NULL, NULL, 'REJECTED', 'Demo connection request.', seed_now - INTERVAL '20 days', NULL, seed_now - INTERVAL '15 days'),
    (8, 14, 24, 14, 24, NULL, NULL, 'CANCELLED', 'Demo connection request.', seed_now - INTERVAL '20 days', NULL, seed_now - INTERVAL '15 days'),
    (9, 15, 22, 15, 22, NULL, NULL, 'REMOVED', 'Demo connection request.', seed_now - INTERVAL '20 days', seed_now - INTERVAL '19 days', seed_now - INTERVAL '15 days');

-- 5. Chat: two accepted pairs, delivery/read states and deletion history

INSERT INTO chat_conversations (conversation_id, user_low, user_high, created_at, last_message_at) VALUES
    (1, 9, 11, seed_now - INTERVAL '18 days', seed_now - INTERVAL '2 days'),
    (2, 13, 17, seed_now - INTERVAL '18 days', seed_now - INTERVAL '2 days');

INSERT INTO chat_participants (participant_id, conversation_id, user_id, slot, joined_at) VALUES
    (1, 1, 9, 1, seed_now - INTERVAL '18 days'),
    (2, 1, 11, 2, seed_now - INTERVAL '18 days'),
    (3, 2, 13, 1, seed_now - INTERVAL '18 days'),
    (4, 2, 17, 2, seed_now - INTERVAL '18 days');

INSERT INTO chat_messages (message_id, conversation_id, sender_id, client_message_id, content, sent_at, deleted_for_everyone_at) VALUES
    (1, 1, 9, '00000000-0000-4000-8000-000000000001', 'Welcome to the backend mentorship series.', seed_now - INTERVAL '7 days', NULL),
    (2, 1, 11, '00000000-0000-4000-8000-000000000002', 'Thank you. I want to learn transaction design.', seed_now - INTERVAL '6 days', NULL),
    (3, 1, 9, '00000000-0000-4000-8000-000000000003', 'This demonstration message was deleted for everyone.', seed_now - INTERVAL '5 days', seed_now - INTERVAL '3 days'),
    (4, 2, 13, '00000000-0000-4000-8000-000000000004', 'The coding club workshop starts next week.', seed_now - INTERVAL '4 days', NULL),
    (5, 2, 17, '00000000-0000-4000-8000-000000000005', 'Please clarify the workshop prerequisites.', seed_now - INTERVAL '3 days', NULL),
    (6, 2, 13, '00000000-0000-4000-8000-000000000006', 'Bring a laptop with Java installed.', seed_now - INTERVAL '2 days', NULL);

INSERT INTO chat_message_states (state_id, message_id, conversation_id, user_id, delivered_at, read_at, deleted_for_self_at) VALUES
    (1, 1, 1, 9, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', NULL),
    (2, 1, 1, 11, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', NULL),
    (3, 2, 1, 9, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', NULL),
    (4, 2, 1, 11, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', NULL),
    (5, 3, 1, 9, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', NULL),
    (6, 3, 1, 11, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', NULL),
    (7, 4, 2, 13, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', NULL),
    (8, 4, 2, 17, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days'),
    (9, 5, 2, 13, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', NULL),
    (10, 5, 2, 17, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', NULL),
    (11, 6, 2, 13, seed_now - INTERVAL '1 days', seed_now - INTERVAL '1 days', NULL),
    (12, 6, 2, 17, seed_now - INTERVAL '1 days', NULL, NULL);

-- 6. Clubs, multiple administrators, representative access and request decisions

INSERT INTO clubs (club_id, club_name, name_key, category, description, contact_email, status, created_at, updated_at) VALUES
    (1, 'Coding Club', 'coding club', 'Technology', 'Demo Coding Club for access and lifecycle checks.', 'club.admin@iut-dhaka.edu', 'ACTIVE', seed_now - INTERVAL '25 days', seed_now - INTERVAL '3 days'),
    (2, 'Robotics Club', 'robotics club', 'Engineering', 'Demo Robotics Club for access and lifecycle checks.', 'club.admin@iut-dhaka.edu', 'PUBLISHING_SUSPENDED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '3 days'),
    (3, 'Business Club', 'business club', 'Business', 'Demo Business Club for access and lifecycle checks.', 'club.admin@iut-dhaka.edu', 'ARCHIVED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '3 days'),
    (4, 'Old Club', 'old club', 'General', 'Demo Old Club for access and lifecycle checks.', 'club.admin@iut-dhaka.edu', 'REMOVED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '3 days');

INSERT INTO club_role_assignments (assignment_id, club_id, user_id, role, assigned_by, assigned_at, revoked_by, revoked_at, current_club_id, current_user_id, administrator_club_id, administrator_user_id) VALUES
    (1, 1, 13, 'CLUB_ADMINISTRATOR', 1, seed_now - INTERVAL '25 days', NULL, NULL, 1, 13, 1, 13),
    (2, 1, 15, 'CLUB_ADMINISTRATOR', 1, seed_now - INTERVAL '25 days', NULL, NULL, 1, 15, 1, 15),
    (3, 1, 14, 'REPRESENTATIVE', 1, seed_now - INTERVAL '25 days', NULL, NULL, 1, 14, NULL, NULL),
    (4, 2, 13, 'CLUB_ADMINISTRATOR', 1, seed_now - INTERVAL '25 days', NULL, NULL, 2, 13, 2, 13),
    (5, 2, 14, 'REPRESENTATIVE', 1, seed_now - INTERVAL '25 days', NULL, NULL, 2, 14, NULL, NULL),
    (6, 3, 15, 'CLUB_ADMINISTRATOR', 1, seed_now - INTERVAL '25 days', NULL, NULL, 3, 15, 3, 15),
    (7, 4, 13, 'CLUB_ADMINISTRATOR', 1, seed_now - INTERVAL '25 days', NULL, NULL, 4, 13, 4, 13),
    (8, 1, 18, 'REPRESENTATIVE', 1, seed_now - INTERVAL '25 days', 13, seed_now - INTERVAL '5 days', NULL, NULL, NULL, NULL);

INSERT INTO club_audit (audit_id, club_id, actor_id, actor_assignment_id, target_assignment_id, action, reason, created_at, previous_state, new_state) VALUES
    (1, 1, 1, NULL, 1, 'CLUB_CREATED', 'Demo role assignment.', seed_now - INTERVAL '25 days', NULL, NULL),
    (2, 1, 1, NULL, 2, 'ROLE_GRANTED', 'Demo role assignment.', seed_now - INTERVAL '25 days', NULL, NULL),
    (3, 1, 1, NULL, 3, 'ROLE_GRANTED', 'Demo role assignment.', seed_now - INTERVAL '25 days', NULL, NULL),
    (4, 2, 1, NULL, 4, 'CLUB_CREATED', 'Demo role assignment.', seed_now - INTERVAL '25 days', NULL, NULL),
    (5, 2, 1, NULL, 5, 'ROLE_GRANTED', 'Demo role assignment.', seed_now - INTERVAL '25 days', NULL, NULL),
    (6, 3, 1, NULL, 6, 'CLUB_CREATED', 'Demo role assignment.', seed_now - INTERVAL '25 days', NULL, NULL),
    (7, 4, 1, NULL, 7, 'CLUB_CREATED', 'Demo role assignment.', seed_now - INTERVAL '25 days', NULL, NULL),
    (8, 1, 1, NULL, 8, 'ROLE_GRANTED', 'Demo role assignment.', seed_now - INTERVAL '25 days', NULL, NULL),
    (9, 1, 13, 1, 8, 'ROLE_REVOKED', 'Demo revoked representative.', seed_now - INTERVAL '5 days', NULL, NULL),
    (10, 2, 1, NULL, NULL, 'CLUB_PUBLISHING_SUSPENDED', 'Demo publishing pause.', seed_now - INTERVAL '3 days', 'ACTIVE', 'PUBLISHING_SUSPENDED'),
    (11, 3, 1, NULL, NULL, 'CLUB_ARCHIVED', 'Demo recoverable archive.', seed_now - INTERVAL '3 days', 'ACTIVE', 'ARCHIVED'),
    (12, 4, 1, NULL, NULL, 'CLUB_REMOVED', 'Demo terminal removal.', seed_now - INTERVAL '3 days', 'ACTIVE', 'REMOVED');

INSERT INTO club_creation_requests (request_id, requester_user_id, club_name, name_key, category, description, contact_email, status, created_at, updated_at, decided_at, decided_by, rejection_reason, club_id) VALUES
    (1, 23, 'Science Club', 'science club', 'Science', 'Pending demo request.', 'engineering.student@iut-dhaka.edu', 'PENDING', seed_now - INTERVAL '2 days', seed_now - INTERVAL '2 days', NULL, NULL, NULL, NULL),
    (2, 13, 'Coding Club', 'coding club', 'Technology', 'Approved request that created Coding Club.', 'club.admin@iut-dhaka.edu', 'APPROVED', seed_now - INTERVAL '26 days', seed_now - INTERVAL '25 days', seed_now - INTERVAL '25 days', 1, NULL, 1),
    (3, 24, 'Duplicate Coding Club', 'duplicate coding club', 'Technology', 'Rejected demo request.', 'business.student@iut-dhaka.edu', 'REJECTED', seed_now - INTERVAL '4 days', seed_now - INTERVAL '3 days', seed_now - INTERVAL '3 days', 1, 'An existing club covers this activity.', NULL);

-- 7. Announcements and events: current, expired, draft, removed and historical

INSERT INTO club_announcements (announcement_id, club_id, author_user_id, author_assignment_id, title, content, priority, status, created_at, updated_at, published_at, expires_at, removed_at) VALUES
    (1, 1, 13, 1, 'Workshop Notice', 'Demo announcement: Workshop Notice.', 'IMPORTANT', 'PUBLISHED', seed_now - INTERVAL '12 days', seed_now - INTERVAL '4 days', seed_now - INTERVAL '10 days', seed_now + INTERVAL '7 days', NULL),
    (2, 1, 13, 1, 'Urgent Venue Notice', 'Demo announcement: Urgent Venue Notice.', 'URGENT', 'PUBLISHED', seed_now - INTERVAL '12 days', seed_now - INTERVAL '4 days', seed_now - INTERVAL '10 days', seed_now + INTERVAL '3 days', NULL),
    (3, 1, 13, 1, 'Draft Notice', 'Demo announcement: Draft Notice.', 'NORMAL', 'UNPUBLISHED', seed_now - INTERVAL '12 days', seed_now - INTERVAL '4 days', NULL, NULL, NULL),
    (4, 1, 13, 1, 'Expired Notice', 'Demo announcement: Expired Notice.', 'NORMAL', 'PUBLISHED', seed_now - INTERVAL '12 days', seed_now - INTERVAL '4 days', seed_now - INTERVAL '10 days', seed_now - INTERVAL '2 days', NULL),
    (5, 1, 13, 1, 'Removed Notice', 'Demo announcement: Removed Notice.', 'NORMAL', 'REMOVED', seed_now - INTERVAL '12 days', seed_now - INTERVAL '4 days', seed_now - INTERVAL '10 days', NULL, seed_now - INTERVAL '4 days'),
    (6, 2, 13, 4, 'Robotics Notice', 'Demo announcement: Robotics Notice.', 'NORMAL', 'PUBLISHED', seed_now - INTERVAL '12 days', seed_now - INTERVAL '4 days', seed_now - INTERVAL '10 days', seed_now + INTERVAL '10 days', NULL);

INSERT INTO club_events (event_id, club_id, author_user_id, author_assignment_id, title, description, location, registration_url, registration_deadline, starts_at, ends_at, status, published_at, updated_at, removed_at) VALUES
    (1, 1, 13, 1, 'Upcoming Java Workshop', 'Demo event: Upcoming Java Workshop.', 'Demo Room A', 'https://example.test/register', seed_now + INTERVAL '6 days', seed_now + INTERVAL '7 days', seed_now + INTERVAL '7 days 2 hours', 'PUBLISHED', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', NULL),
    (2, 1, 13, 1, 'Active Coding Meetup', 'Demo event: Active Coding Meetup.', 'Demo Room A', 'https://example.test/register', seed_now - INTERVAL '2 days', seed_now - INTERVAL '1 hour', seed_now + INTERVAL '1 hour', 'PUBLISHED', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', NULL),
    (3, 1, 13, 1, 'Past Coding Meetup', 'Demo event: Past Coding Meetup.', 'Demo Room A', 'https://example.test/register', seed_now + INTERVAL '-8 days', seed_now + INTERVAL '-7 days', seed_now + INTERVAL '-7 days 2 hours', 'PUBLISHED', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', NULL),
    (4, 1, 13, 1, 'Removed Coding Meetup', 'Demo event: Removed Coding Meetup.', 'Demo Room A', 'https://example.test/register', seed_now + INTERVAL '9 days', seed_now + INTERVAL '10 days', seed_now + INTERVAL '10 days 2 hours', 'REMOVED', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', seed_now - INTERVAL '2 days');

-- Audit snapshots use the actual seeded public-response fields, not invented production actions.
INSERT INTO club_publication_audit (audit_id, club_id, announcement_id, actor_user_id,
    actor_assignment_id, action, after_snapshot, created_at)
SELECT announcement_id, club_id, announcement_id, author_user_id, author_assignment_id,
    'CREATED', jsonb_build_object('id', announcement_id, 'clubId', club_id,
    'title', title, 'content', content, 'status', 'UNPUBLISHED')::text, created_at
FROM club_announcements;
INSERT INTO club_publication_audit (audit_id, club_id, announcement_id, actor_user_id,
    actor_assignment_id, action, reason, after_snapshot, created_at)
SELECT 10 + announcement_id, club_id, announcement_id, author_user_id, author_assignment_id,
    CASE WHEN status='REMOVED' THEN 'REMOVED' ELSE 'PUBLISHED' END,
    CASE WHEN status='REMOVED' THEN 'Demo removal of a synthetic notice.' END,
    jsonb_build_object('id', announcement_id, 'clubId', club_id, 'title', title,
    'content', content, 'status', status)::text,
    CASE WHEN status='REMOVED' THEN removed_at ELSE published_at END
FROM club_announcements WHERE status<>'UNPUBLISHED';
INSERT INTO club_publication_audit (audit_id, club_id, event_id, actor_user_id,
    actor_assignment_id, action, after_snapshot, created_at)
SELECT 20 + event_id, club_id, event_id, author_user_id, author_assignment_id, 'CREATED',
    jsonb_build_object('id', event_id, 'clubId', club_id, 'title', title, 'status', 'PUBLISHED')::text,
    published_at FROM club_events;
INSERT INTO club_publication_audit (audit_id, club_id, event_id, actor_user_id,
    actor_assignment_id, action, reason, after_snapshot, created_at)
SELECT 30 + event_id, club_id, event_id, author_user_id, author_assignment_id, 'REMOVED',
    'Demo removal of a synthetic event.',
    jsonb_build_object('id', event_id, 'clubId', club_id, 'title', title, 'status', status)::text,
    removed_at FROM club_events WHERE status='REMOVED';

-- 8. Mentorship with persisted occurrences and separate enrollment periods

INSERT INTO mentor_profiles (mentor_profile_id, user_id, mentoring_bio, status, registered_at, updated_at) VALUES
    (1, 9, 'Student-led Java and database mentoring.', 'AVAILABLE', seed_now - INTERVAL '20 days', seed_now - INTERVAL '20 days'),
    (2, 10, 'Experienced alumni backend mentorship.', 'AVAILABLE', seed_now - INTERVAL '20 days', seed_now - INTERVAL '20 days'),
    (3, 25, 'Temporarily unavailable alumni mentor.', 'UNAVAILABLE', seed_now - INTERVAL '20 days', seed_now - INTERVAL '2 days');

INSERT INTO mentor_expertise (expertise_id, mentor_profile_id, skill_id, description) VALUES
    (1, 1, 1, 'Java fundamentals.'),
    (2, 1, 10, 'Database transactions.'),
    (3, 2, 1, 'Java engineering.'),
    (4, 2, 15, 'Spring Boot design.'),
    (5, 3, 5, 'Python and data science.');

INSERT INTO mentorship_slots (slot_id, mentor_profile_id, topic, description, schedule_type, start_date, start_time, end_time, recurrence_end_date, mode, location, meeting_link, capacity, current_mentee_count, status, created_at, updated_at, meeting_count, enrollment_open) VALUES
    (1, 2, 'Alumni Backend Series', 'Demo mentorship series with persisted meetings.', 'WEEKLY', seed_date + 7, '10:00', '11:00', NULL, 'ONLINE', NULL, 'https://meet.example.test/demo-series-1', 5, 2, 'OPEN', seed_now - INTERVAL '20 days', seed_now - INTERVAL '1 days', 3, TRUE),
    (2, 1, 'Student Java Workshop', 'Demo mentorship series with persisted meetings.', 'ONE_TIME', seed_date + 8, '10:00', '11:00', NULL, 'ONLINE', NULL, 'https://meet.example.test/demo-series-2', 2, 2, 'OPEN', seed_now - INTERVAL '20 days', seed_now - INTERVAL '1 days', 1, TRUE),
    (3, 2, 'Closed Enrollment Series', 'Demo mentorship series with persisted meetings.', 'WEEKLY', seed_date + 9, '10:00', '11:00', NULL, 'ONLINE', NULL, 'https://meet.example.test/demo-series-3', 4, 1, 'CLOSED', seed_now - INTERVAL '20 days', seed_now - INTERVAL '1 days', 2, FALSE),
    (4, 2, 'Cancelled Backend Series', 'Demo mentorship series with persisted meetings.', 'WEEKLY', seed_date + 10, '10:00', '11:00', NULL, 'ONLINE', NULL, 'https://meet.example.test/demo-series-4', 4, 0, 'CANCELLED', seed_now - INTERVAL '20 days', seed_now - INTERVAL '1 days', 2, FALSE),
    (5, 1, 'Completed Java Workshop', 'Demo mentorship series with persisted meetings.', 'ONE_TIME', seed_date - 7, '10:00', '11:00', NULL, 'IN_PERSON', 'Demo Lab A', NULL, 3, 0, 'OPEN', seed_now - INTERVAL '20 days', seed_now - INTERVAL '1 days', 1, TRUE),
    (6, 3, 'Unavailable Mentor Workshop', 'Demo mentorship series with persisted meetings.', 'ONE_TIME', seed_date + 12, '10:00', '11:00', NULL, 'ONLINE', NULL, 'https://meet.example.test/demo-series-6', 3, 1, 'OPEN', seed_now - INTERVAL '20 days', seed_now - INTERVAL '1 days', 1, TRUE),
    (7, 2, 'Biweekly API Series', 'Demo mentorship series with persisted meetings.', 'BIWEEKLY', seed_date + 14, '14:00', '15:00', NULL, 'ONLINE', NULL, 'https://meet.example.test/demo-series-7', 4, 0, 'OPEN', seed_now - INTERVAL '20 days', seed_now - INTERVAL '1 days', 3, TRUE),
    (8, 1, 'Back To Back Workshop', 'Demo mentorship series with persisted meetings.', 'ONE_TIME', seed_date + 8, '11:00', '12:00', NULL, 'ONLINE', NULL, 'https://meet.example.test/demo-series-8', 3, 0, 'OPEN', seed_now - INTERVAL '20 days', seed_now - INTERVAL '1 days', 1, TRUE);

INSERT INTO mentorship_occurrences (occurrence_id, slot_id, starts_at, ends_at, cancelled_at) VALUES
    (1, 1, (seed_date + 7) + TIME '10:00', (seed_date + 7) + TIME '11:00', NULL),
    (2, 1, (seed_date + 14) + TIME '10:00', (seed_date + 14) + TIME '11:00', NULL),
    (3, 1, (seed_date + 21) + TIME '10:00', (seed_date + 21) + TIME '11:00', NULL),
    (4, 2, (seed_date + 8) + TIME '10:00', (seed_date + 8) + TIME '11:00', NULL),
    (5, 3, (seed_date + 9) + TIME '10:00', (seed_date + 9) + TIME '11:00', NULL),
    (6, 3, (seed_date + 16) + TIME '10:00', (seed_date + 16) + TIME '11:00', NULL),
    (7, 4, (seed_date + 10) + TIME '10:00', (seed_date + 10) + TIME '11:00', seed_now - INTERVAL '1 days'),
    (8, 4, (seed_date + 17) + TIME '10:00', (seed_date + 17) + TIME '11:00', seed_now - INTERVAL '1 days'),
    (9, 5, (seed_date + -7) + TIME '10:00', (seed_date + -7) + TIME '11:00', NULL),
    (10, 6, (seed_date + 12) + TIME '10:00', (seed_date + 12) + TIME '11:00', NULL),
    (11, 7, (seed_date + 14) + TIME '14:00', (seed_date + 14) + TIME '15:00', NULL),
    (12, 7, (seed_date + 28) + TIME '14:00', (seed_date + 28) + TIME '15:00', NULL),
    (13, 7, (seed_date + 42) + TIME '14:00', (seed_date + 42) + TIME '15:00', NULL),
    (14, 8, (seed_date + 8) + TIME '11:00', (seed_date + 8) + TIME '12:00', NULL);

INSERT INTO mentorship_enrollments (enrollment_id, slot_id, mentee_id, join_message, learning_goal, status, joined_at, left_at, active_marker) VALUES
    (1, 1, 12, 'Demo enrollment request.', 'Learn through guided practice.', 'LEFT', seed_now - INTERVAL '10 days', seed_now - INTERVAL '7 days', NULL),
    (2, 1, 12, 'Demo enrollment request.', 'Learn through guided practice.', 'ACTIVE', seed_now - INTERVAL '6 days', NULL, TRUE),
    (3, 1, 11, 'Demo enrollment request.', 'Learn through guided practice.', 'ACTIVE', seed_now - INTERVAL '5 days', NULL, TRUE),
    (4, 2, 17, 'Demo enrollment request.', 'Learn through guided practice.', 'ACTIVE', seed_now - INTERVAL '5 days', NULL, TRUE),
    (5, 2, 18, 'Demo enrollment request.', 'Learn through guided practice.', 'ACTIVE', seed_now - INTERVAL '5 days', NULL, TRUE),
    (6, 3, 26, 'Demo enrollment request.', 'Learn through guided practice.', 'ACTIVE', seed_now - INTERVAL '5 days', NULL, TRUE),
    (7, 4, 12, 'Demo enrollment request.', 'Learn through guided practice.', 'CANCELLED', seed_now - INTERVAL '6 days', seed_now - INTERVAL '1 days', NULL),
    (8, 5, 11, 'Demo enrollment request.', 'Learn through guided practice.', 'COMPLETED', seed_now - INTERVAL '15 days', seed_now - INTERVAL '7 days', NULL),
    (9, 6, 22, 'Demo enrollment request.', 'Learn through guided practice.', 'ACTIVE', seed_now - INTERVAL '5 days', NULL, TRUE);

-- 9. Projects: exact-score discovery fixture plus applications and lifecycle examples

INSERT INTO teammate_projects (project_id, creator_user_id, title, description, team_size_limit, duration, course_name, application_deadline, status, created_at, updated_at, closed_at, deleted_at) VALUES
    (1, 2, 'Java Recommendation Project', 'Demo project: Java Recommendation Project.', 5, '4 weeks', 'Demo Software Project', seed_date + 30, 'OPEN', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', NULL, NULL),
    (2, 2, 'Python Team Project', 'Demo project: Python Team Project.', 4, '4 weeks', 'Demo Software Project', seed_date + 25, 'OPEN', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', NULL, NULL),
    (3, 13, 'Full Club Website Project', 'Demo project: Full Club Website Project.', 2, '4 weeks', 'Demo Software Project', seed_date + 20, 'OPEN', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', NULL, NULL),
    (4, 15, 'Closed Mobile Project', 'Demo project: Closed Mobile Project.', 4, '4 weeks', 'Demo Software Project', seed_date + 20, 'CLOSED', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', seed_now - INTERVAL '2 days', NULL),
    (5, 2, 'Expired Java Project', 'Demo project: Expired Java Project.', 4, '4 weeks', 'Demo Software Project', seed_date - 2, 'OPEN', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', NULL, NULL),
    (6, 19, 'Reported Owner Project', 'Demo project: Reported Owner Project.', 4, '4 weeks', 'Demo Software Project', seed_date + 30, 'OPEN', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', NULL, NULL),
    (7, 2, 'Deleted Demo Project', 'Demo project: Deleted Demo Project.', 4, '4 weeks', 'Demo Software Project', seed_date + 20, 'DELETED', seed_now - INTERVAL '15 days', seed_now - INTERVAL '2 days', NULL, seed_now - INTERVAL '2 days');

INSERT INTO teammate_project_skills (project_id, skill_id, required) VALUES
    (1, 1, TRUE),
    (1, 2, TRUE),
    (1, 3, FALSE),
    (1, 4, FALSE),
    (2, 5, TRUE),
    (2, 4, FALSE),
    (3, 8, TRUE),
    (3, 9, FALSE),
    (4, 6, TRUE),
    (4, 7, FALSE),
    (5, 1, TRUE),
    (6, 1, TRUE),
    (7, 5, TRUE);

INSERT INTO teammate_project_memberships (membership_id, project_id, member_user_id, role, creator_project_id, joined_at) VALUES
    (1, 1, 2, 'CREATOR', 1, seed_now - INTERVAL '15 days'),
    (2, 2, 2, 'CREATOR', 2, seed_now - INTERVAL '15 days'),
    (3, 3, 13, 'CREATOR', 3, seed_now - INTERVAL '15 days'),
    (4, 4, 15, 'CREATOR', 4, seed_now - INTERVAL '15 days'),
    (5, 5, 2, 'CREATOR', 5, seed_now - INTERVAL '15 days'),
    (6, 6, 19, 'CREATOR', 6, seed_now - INTERVAL '15 days'),
    (7, 7, 2, 'CREATOR', 7, seed_now - INTERVAL '15 days'),
    (8, 2, 8, 'TEAMMATE', NULL, seed_now - INTERVAL '5 days'),
    (9, 3, 14, 'TEAMMATE', NULL, seed_now - INTERVAL '5 days');

INSERT INTO teammate_project_applications (application_id, project_id, applicant_user_id, message, status, applied_at, responded_at) VALUES
    (1, 2, 8, 'I would like to contribute to this demo project.', 'ACCEPTED', seed_now - INTERVAL '8 days', seed_now - INTERVAL '5 days'),
    (2, 2, 26, 'I would like to contribute to this demo project.', 'PENDING', seed_now - INTERVAL '8 days', NULL),
    (3, 2, 11, 'I would like to contribute to this demo project.', 'REJECTED', seed_now - INTERVAL '8 days', seed_now - INTERVAL '5 days'),
    (4, 3, 14, 'I would like to contribute to this demo project.', 'ACCEPTED', seed_now - INTERVAL '8 days', seed_now - INTERVAL '5 days'),
    (5, 4, 17, 'I would like to contribute to this demo project.', 'PENDING', seed_now - INTERVAL '8 days', NULL),
    (6, 7, 26, 'I would like to contribute to this demo project.', 'CANCELLED_PROJECT_DELETED', seed_now - INTERVAL '8 days', seed_now - INTERVAL '2 days');

INSERT INTO teammate_project_audits (audit_id, project_id, actor_user_id, application_id, event_type, occurred_at) VALUES
    (1, 1, 2, NULL, 'CREATED', seed_now - INTERVAL '15 days'),
    (2, 2, 2, NULL, 'CREATED', seed_now - INTERVAL '15 days'),
    (3, 3, 13, NULL, 'CREATED', seed_now - INTERVAL '15 days'),
    (4, 4, 15, NULL, 'CREATED', seed_now - INTERVAL '15 days'),
    (5, 5, 2, NULL, 'CREATED', seed_now - INTERVAL '15 days'),
    (6, 6, 19, NULL, 'CREATED', seed_now - INTERVAL '15 days'),
    (7, 7, 2, NULL, 'CREATED', seed_now - INTERVAL '15 days'),
    (8, 2, 8, 1, 'APPLICATION_SUBMITTED', seed_now - INTERVAL '8 days'),
    (9, 2, 2, 1, 'APPLICATION_ACCEPTED', seed_now - INTERVAL '5 days'),
    (10, 2, 26, 2, 'APPLICATION_SUBMITTED', seed_now - INTERVAL '8 days'),
    (11, 2, 11, 3, 'APPLICATION_SUBMITTED', seed_now - INTERVAL '8 days'),
    (12, 2, 2, 3, 'APPLICATION_REJECTED', seed_now - INTERVAL '5 days'),
    (13, 3, 14, 4, 'APPLICATION_SUBMITTED', seed_now - INTERVAL '8 days'),
    (14, 3, 13, 4, 'APPLICATION_ACCEPTED', seed_now - INTERVAL '5 days'),
    (15, 4, 17, 5, 'APPLICATION_SUBMITTED', seed_now - INTERVAL '8 days'),
    (16, 7, 26, 6, 'APPLICATION_SUBMITTED', seed_now - INTERVAL '8 days'),
    (17, 7, 2, 6, 'APPLICATION_CANCELLED', seed_now - INTERVAL '2 days'),
    (18, 4, 15, NULL, 'CLOSED', seed_now - INTERVAL '2 days'),
    (19, 7, 2, NULL, 'DELETED', seed_now - INTERVAL '2 days');

-- 10. Career posts, application channels, skills and retained saved access

INSERT INTO career_job_posts (job_post_id, author_user_id, title, company_name, description, qualifications, location, employment_type, work_mode, salary_range, application_url, application_email, application_deadline, status, posted_at, updated_at, closed_at, removed_at) VALUES
    (1, 16, 'Backend Internship', 'Demo Labs', 'Synthetic career post for Backend Internship.', 'Relevant skills and a willingness to learn.', 'Dhaka', 'INTERNSHIP', 'HYBRID', 'BDT 25000-50000', 'https://example.test/jobs/demo-1', NULL, seed_date + 45, 'PUBLISHED', seed_now - INTERVAL '18 days', seed_now - INTERVAL '4 days', NULL, NULL),
    (2, 16, 'Closed Platform Role', 'Demo Labs', 'Synthetic career post for Closed Platform Role.', 'Relevant skills and a willingness to learn.', 'Dhaka', 'FULL_TIME', 'ONSITE', 'Negotiable', NULL, 'career.author@iut-dhaka.edu', seed_date + 40, 'CLOSED', seed_now - INTERVAL '18 days', seed_now - INTERVAL '4 days', seed_now - INTERVAL '4 days', NULL),
    (3, 16, 'Expired Data Role', 'Demo Labs', 'Synthetic career post for Expired Data Role.', 'Relevant skills and a willingness to learn.', 'Dhaka', 'FULL_TIME', 'REMOTE', 'Negotiable', 'https://example.test/jobs/demo-3', NULL, seed_date - 3, 'PUBLISHED', seed_now - INTERVAL '18 days', seed_now - INTERVAL '4 days', NULL, NULL),
    (4, 16, 'Flutter Contract', 'Demo Labs', 'Synthetic career post for Flutter Contract.', 'Relevant skills and a willingness to learn.', 'Dhaka', 'CONTRACT', 'REMOTE', 'Negotiable', 'https://example.test/jobs/demo-4', 'career.author@iut-dhaka.edu', seed_date + 60, 'PUBLISHED', seed_now - INTERVAL '18 days', seed_now - INTERVAL '4 days', NULL, NULL),
    (5, 16, 'Part Time Data Analyst', 'Demo Labs', 'Synthetic career post for Part Time Data Analyst.', 'Relevant skills and a willingness to learn.', 'Dhaka', 'PART_TIME', 'HYBRID', 'Negotiable', NULL, 'career.author@iut-dhaka.edu', seed_date + 35, 'PUBLISHED', seed_now - INTERVAL '18 days', seed_now - INTERVAL '4 days', NULL, NULL),
    (6, 16, 'Removed Career Post', 'Demo Labs', 'Synthetic career post for Removed Career Post.', 'Relevant skills and a willingness to learn.', 'Dhaka', 'FULL_TIME', 'ONSITE', 'Negotiable', 'https://example.test/jobs/demo-6', NULL, seed_date + 30, 'REMOVED', seed_now - INTERVAL '18 days', seed_now - INTERVAL '4 days', NULL, seed_now - INTERVAL '4 days');

INSERT INTO career_job_skills (job_post_id, skill_id, required) VALUES
    (1, 1, TRUE),
    (1, 2, TRUE),
    (1, 4, FALSE),
    (2, 1, TRUE),
    (2, 10, TRUE),
    (3, 5, TRUE),
    (3, 2, FALSE),
    (4, 6, TRUE),
    (4, 7, TRUE),
    (5, 13, TRUE),
    (5, 14, TRUE),
    (6, 1, TRUE);

INSERT INTO career_saved_jobs (saved_job_id, student_user_id, job_post_id, note, saved_at, updated_at) VALUES
    (1, 17, 1, 'Review this internship.', seed_now - INTERVAL '10 days', NULL),
    (2, 17, 2, 'Saved before closure; retain reporting access.', seed_now - INTERVAL '10 days', NULL),
    (3, 17, 3, 'Saved before expiry; retain reporting access.', seed_now - INTERVAL '10 days', NULL),
    (4, 11, 4, 'Prepare a Flutter portfolio.', seed_now - INTERVAL '10 days', NULL),
    (5, 26, 5, 'Prepare a data analysis example.', seed_now - INTERVAL '10 days', NULL);

-- 11. Moderation evidence and reports for every supported target type

INSERT INTO moderation_actions (action_id, actor_id, target_user_id, action_type, reason, previous_state, new_state, created_at) VALUES
    (1, 1, 19, 'SUSPEND_ACCOUNT', 'Demo suspension after a synthetic user report.', 'ACTIVE', 'SUSPENDED', seed_now - INTERVAL '1 days');

INSERT INTO audit_logs (audit_log_id, moderation_action_id, actor_id, event_type, subject_type, subject_id, reason, previous_state_json, new_state_json, occurred_at) VALUES
    (1, 1, 1, 'ACCOUNT_SUSPENDED', 'USER', 19, 'Demo suspension after a synthetic user report.', '{"accountStatus": "ACTIVE"}', '{"accountStatus": "SUSPENDED"}', seed_now - INTERVAL '1 days');

INSERT INTO content_reports (report_id, reporter_id, target_type, target_id, reason, status,
    target_label, target_snapshot, target_owner_user_id, parent_club_id, reviewer_id,
    submitted_at, review_started_at, resolved_at, resolution_summary, internal_notes,
    open_reporter_id, open_target_type, open_target_id)
SELECT 1, 17, 'USER', 19, 'Demo user conduct report.', 'ACTION_TAKEN', full_name,
    jsonb_build_object('userId',user_id,'fullName',full_name,'platformRole',platform_role)::text,
    19, NULL, 1, seed_now - INTERVAL '3 days', seed_now - INTERVAL '2 days',
    seed_now - INTERVAL '12 hours', 'The reported account was suspended.',
    'Synthetic account-moderation evidence 1.', NULL, NULL, NULL
FROM users WHERE user_id=19;
INSERT INTO content_reports (report_id, reporter_id, target_type, target_id, reason, status,
    target_label, target_snapshot, parent_club_id, submitted_at,
    open_reporter_id, open_target_type, open_target_id)
SELECT 2,17,'CLUB',club_id,'Demo club review request.','SUBMITTED',club_name,
    jsonb_build_object('id',club_id,'clubName',club_name,'category',category,'description',description,'status',status)::text,
    club_id, seed_now - INTERVAL '2 days',17,'CLUB',club_id FROM clubs WHERE club_id=1;
INSERT INTO content_reports (report_id, reporter_id, target_type, target_id, reason, status,
    target_label, target_snapshot, target_owner_user_id, parent_club_id, reviewer_id,
    submitted_at, review_started_at, open_reporter_id, open_target_type, open_target_id)
SELECT 3,17,'ANNOUNCEMENT',announcement_id,'Demo announcement review request.','UNDER_REVIEW',title,
    jsonb_build_object('id',announcement_id,'clubId',club_id,'authorUserId',author_user_id,
    'authorAssignmentId',author_assignment_id,'title',title,'content',content,'priority',priority,
    'status',status,'createdAt',created_at,'updatedAt',updated_at,'publishedAt',published_at,'expiresAt',expires_at,'removedAt',removed_at)::text,
    author_user_id,club_id,1,seed_now - INTERVAL '2 days',seed_now - INTERVAL '1 day',
    17,'ANNOUNCEMENT',announcement_id FROM club_announcements WHERE announcement_id=1;
INSERT INTO content_reports (report_id, reporter_id, target_type, target_id, reason, status,
    target_label, target_snapshot, target_owner_user_id, parent_club_id, reviewer_id,
    submitted_at, review_started_at, resolved_at, resolution_summary)
SELECT 4,17,'EVENT',event_id,'Demo past event review.','NO_ACTION',title,
    jsonb_build_object('id',event_id,'clubId',club_id,'authorUserId',author_user_id,
    'title',title,'description',description,'startsAt',starts_at,'endsAt',ends_at,'status',status,'timing','PAST')::text,
    author_user_id,club_id,1,seed_now - INTERVAL '3 days',seed_now - INTERVAL '2 days',
    seed_now - INTERVAL '1 day','The historical event required no moderation.'
FROM club_events WHERE event_id=3;
INSERT INTO content_reports (report_id, reporter_id, target_type, target_id, reason, status,
    target_label, target_snapshot, target_owner_user_id, submitted_at,
    open_reporter_id, open_target_type, open_target_id)
SELECT 5,17,'CHAT_MESSAGE',message_id,'Demo accessible chat-message report.','SUBMITTED',
    'Chat message '||message_id,
    jsonb_build_object('id',message_id,'conversationId',conversation_id,'senderId',sender_id,'content',content,'sentAt',sent_at)::text,
    sender_id,seed_now - INTERVAL '12 hours',17,'CHAT_MESSAGE',message_id FROM chat_messages WHERE message_id=6;
INSERT INTO content_reports (report_id, reporter_id, target_type, target_id, reason, status,
    target_label, target_snapshot, target_owner_user_id, submitted_at,
    open_reporter_id, open_target_type, open_target_id)
SELECT 6,17,'PROJECT',p.project_id,'Demo project review request.','SUBMITTED',p.title,
    jsonb_build_object('id',p.project_id,'creatorUserId',p.creator_user_id,'creatorDisplayName',u.full_name,
    'title',p.title,'description',p.description,'teamSizeLimit',p.team_size_limit,'duration',p.duration,
    'courseName',p.course_name,'applicationDeadline',p.application_deadline,'status',p.status,'availability','AVAILABLE',
    'skills',(SELECT jsonb_agg(jsonb_build_object('id',s.skill_id,'name',s.name,'required',ps.required) ORDER BY s.skill_id)
       FROM teammate_project_skills ps JOIN skills s USING(skill_id) WHERE ps.project_id=p.project_id),
    'createdAt',p.created_at,'updatedAt',p.updated_at,'closedAt',p.closed_at)::text,
    p.creator_user_id,seed_now - INTERVAL '2 days',17,'PROJECT',p.project_id
FROM teammate_projects p JOIN users u ON u.user_id=p.creator_user_id WHERE p.project_id=1;
INSERT INTO content_reports (report_id, reporter_id, target_type, target_id, reason, status,
    target_label, target_snapshot, target_owner_user_id, reviewer_id, submitted_at, review_started_at,
    open_reporter_id, open_target_type, open_target_id)
SELECT 7,17,'CAREER_POST',p.job_post_id,'Demo saved closed career-post report.','UNDER_REVIEW',p.title,
    jsonb_build_object('id',p.job_post_id,'authorUserId',p.author_user_id,'authorDisplayName',u.full_name,
    'title',p.title,'companyName',p.company_name,'description',p.description,'qualifications',p.qualifications,
    'location',p.location,'employmentType',p.employment_type,'workMode',p.work_mode,'salaryRange',p.salary_range,
    'applicationUrl',p.application_url,'applicationEmail',p.application_email,'applicationDeadline',p.application_deadline,
    'status','CLOSED','applicationChannels',jsonb_build_array('EMAIL'),
    'skills',(SELECT jsonb_agg(jsonb_build_object('id',s.skill_id,'name',s.name,'required',ps.required) ORDER BY s.skill_id)
       FROM career_job_skills ps JOIN skills s USING(skill_id) WHERE ps.job_post_id=p.job_post_id),
    'postedAt',p.posted_at,'updatedAt',p.updated_at,'closedAt',p.closed_at)::text,
    p.author_user_id,1,seed_now - INTERVAL '2 days',seed_now - INTERVAL '1 day',17,'CAREER_POST',p.job_post_id
FROM career_job_posts p JOIN users u ON u.user_id=p.author_user_id WHERE p.job_post_id=2;
INSERT INTO report_audit_logs (report_id,actor_id,event_type,previous_status,new_status,occurred_at)
SELECT report_id,reporter_id,'SUBMITTED',NULL,'SUBMITTED',submitted_at FROM content_reports;
INSERT INTO report_audit_logs (report_id,actor_id,event_type,previous_status,new_status,occurred_at)
SELECT report_id,reviewer_id,'UNDER_REVIEW','SUBMITTED','UNDER_REVIEW',review_started_at
FROM content_reports WHERE review_started_at IS NOT NULL;
INSERT INTO report_audit_logs (report_id,actor_id,event_type,previous_status,new_status,internal_note,occurred_at)
SELECT report_id,reviewer_id,status,'UNDER_REVIEW',status,internal_notes,resolved_at
FROM content_reports WHERE resolved_at IS NOT NULL;
INSERT INTO report_action_links (link_id,report_id,evidence_source,evidence_id,action_type,subject_type,
    subject_id,action_occurred_at,linked_by,linked_at)
VALUES (1,1,'ACCOUNT_MODERATION',1,'SUSPEND_ACCOUNT','USER',19,seed_now - INTERVAL '1 day',1,seed_now - INTERVAL '12 hours');

-- 12. Notifications with application-compatible event keys

INSERT INTO notifications (notification_id, recipient_id, type, title, message, reference_type, reference_id, event_key, created_at, read_at, dismissed_at) VALUES
    (1, 3, 'CONNECTION_REQUESTED', 'New connection request', 'You received a connection request.', 'CONNECTION', 1, 'connection:1:CONNECTION_REQUESTED', seed_now - INTERVAL '20 days', seed_now - INTERVAL '0 days', NULL),
    (2, 2, 'CONNECTION_ACCEPTED', 'Connection accepted', 'Your connection request was accepted.', 'CONNECTION', 1, 'connection:1:CONNECTION_ACCEPTED', seed_now - INTERVAL '19 days', seed_now - INTERVAL '0 days', NULL),
    (3, 4, 'CONNECTION_REQUESTED', 'New connection request', 'You received a connection request.', 'CONNECTION', 2, 'connection:2:CONNECTION_REQUESTED', seed_now - INTERVAL '20 days', seed_now - INTERVAL '0 days', NULL),
    (4, 2, 'CONNECTION_ACCEPTED', 'Connection accepted', 'Your connection request was accepted.', 'CONNECTION', 2, 'connection:2:CONNECTION_ACCEPTED', seed_now - INTERVAL '19 days', seed_now - INTERVAL '0 days', NULL),
    (5, 11, 'CONNECTION_REQUESTED', 'New connection request', 'You received a connection request.', 'CONNECTION', 3, 'connection:3:CONNECTION_REQUESTED', seed_now - INTERVAL '20 days', seed_now - INTERVAL '0 days', NULL),
    (6, 9, 'CONNECTION_ACCEPTED', 'Connection accepted', 'Your connection request was accepted.', 'CONNECTION', 3, 'connection:3:CONNECTION_ACCEPTED', seed_now - INTERVAL '19 days', seed_now - INTERVAL '0 days', NULL),
    (7, 17, 'CONNECTION_REQUESTED', 'New connection request', 'You received a connection request.', 'CONNECTION', 4, 'connection:4:CONNECTION_REQUESTED', seed_now - INTERVAL '20 days', seed_now - INTERVAL '0 days', NULL),
    (8, 13, 'CONNECTION_ACCEPTED', 'Connection accepted', 'Your connection request was accepted.', 'CONNECTION', 4, 'connection:4:CONNECTION_ACCEPTED', seed_now - INTERVAL '19 days', seed_now - INTERVAL '0 days', NULL),
    (9, 12, 'CONNECTION_REQUESTED', 'New connection request', 'You received a connection request.', 'CONNECTION', 5, 'connection:5:CONNECTION_REQUESTED', seed_now - INTERVAL '20 days', seed_now - INTERVAL '0 days', NULL),
    (10, 10, 'CONNECTION_ACCEPTED', 'Connection accepted', 'Your connection request was accepted.', 'CONNECTION', 5, 'connection:5:CONNECTION_ACCEPTED', seed_now - INTERVAL '19 days', seed_now - INTERVAL '0 days', NULL),
    (11, 18, 'CONNECTION_REQUESTED', 'New connection request', 'You received a connection request.', 'CONNECTION', 6, 'connection:6:CONNECTION_REQUESTED', seed_now - INTERVAL '20 days', NULL, NULL),
    (12, 23, 'CONNECTION_REQUESTED', 'New connection request', 'You received a connection request.', 'CONNECTION', 7, 'connection:7:CONNECTION_REQUESTED', seed_now - INTERVAL '20 days', seed_now - INTERVAL '0 days', NULL),
    (13, 24, 'CONNECTION_REQUESTED', 'New connection request', 'You received a connection request.', 'CONNECTION', 8, 'connection:8:CONNECTION_REQUESTED', seed_now - INTERVAL '20 days', seed_now - INTERVAL '0 days', NULL),
    (14, 22, 'CONNECTION_REQUESTED', 'New connection request', 'You received a connection request.', 'CONNECTION', 9, 'connection:9:CONNECTION_REQUESTED', seed_now - INTERVAL '20 days', seed_now - INTERVAL '0 days', NULL),
    (15, 15, 'CONNECTION_ACCEPTED', 'Connection accepted', 'Your connection request was accepted.', 'CONNECTION', 9, 'connection:9:CONNECTION_ACCEPTED', seed_now - INTERVAL '19 days', seed_now - INTERVAL '0 days', NULL),
    (16, 13, 'CLUB_ROLE_GRANTED', 'Club access granted', 'CLUB_ADMINISTRATOR access granted.', 'CLUB', 1, 'club-assignment:1:CLUB_ROLE_GRANTED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '0 days', NULL),
    (17, 15, 'CLUB_ROLE_GRANTED', 'Club access granted', 'CLUB_ADMINISTRATOR access granted.', 'CLUB', 1, 'club-assignment:2:CLUB_ROLE_GRANTED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '0 days', NULL),
    (18, 14, 'CLUB_ROLE_GRANTED', 'Club access granted', 'REPRESENTATIVE access granted.', 'CLUB', 1, 'club-assignment:3:CLUB_ROLE_GRANTED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '0 days', NULL),
    (19, 13, 'CLUB_ROLE_GRANTED', 'Club access granted', 'CLUB_ADMINISTRATOR access granted.', 'CLUB', 2, 'club-assignment:4:CLUB_ROLE_GRANTED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '0 days', NULL),
    (20, 14, 'CLUB_ROLE_GRANTED', 'Club access granted', 'REPRESENTATIVE access granted.', 'CLUB', 2, 'club-assignment:5:CLUB_ROLE_GRANTED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '0 days', NULL),
    (21, 15, 'CLUB_ROLE_GRANTED', 'Club access granted', 'CLUB_ADMINISTRATOR access granted.', 'CLUB', 3, 'club-assignment:6:CLUB_ROLE_GRANTED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '0 days', NULL),
    (22, 13, 'CLUB_ROLE_GRANTED', 'Club access granted', 'CLUB_ADMINISTRATOR access granted.', 'CLUB', 4, 'club-assignment:7:CLUB_ROLE_GRANTED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '0 days', NULL),
    (23, 18, 'CLUB_ROLE_GRANTED', 'Club access granted', 'REPRESENTATIVE access granted.', 'CLUB', 1, 'club-assignment:8:CLUB_ROLE_GRANTED', seed_now - INTERVAL '25 days', seed_now - INTERVAL '0 days', NULL),
    (24, 18, 'CLUB_ROLE_REVOKED', 'Club access revoked', 'Representative access revoked.', 'CLUB', 1, 'club-assignment:8:CLUB_ROLE_REVOKED', seed_now - INTERVAL '5 days', NULL, NULL),
    (25, 11, 'NEW_MESSAGE', 'New message', 'You received a demo message.', 'CONVERSATION', 1, 'chat-message:1', seed_now - INTERVAL '7 days', seed_now - INTERVAL '0 days', NULL),
    (26, 9, 'NEW_MESSAGE', 'New message', 'You received a demo message.', 'CONVERSATION', 1, 'chat-message:2', seed_now - INTERVAL '6 days', seed_now - INTERVAL '0 days', NULL),
    (27, 11, 'NEW_MESSAGE', 'New message', 'You received a demo message.', 'CONVERSATION', 1, 'chat-message:3', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (28, 17, 'NEW_MESSAGE', 'New message', 'You received a demo message.', 'CONVERSATION', 2, 'chat-message:4', seed_now - INTERVAL '4 days', seed_now - INTERVAL '0 days', NULL),
    (29, 13, 'NEW_MESSAGE', 'New message', 'You received a demo message.', 'CONVERSATION', 2, 'chat-message:5', seed_now - INTERVAL '3 days', seed_now - INTERVAL '0 days', NULL),
    (30, 17, 'NEW_MESSAGE', 'New message', 'You received a demo message.', 'CONVERSATION', 2, 'chat-message:6', seed_now - INTERVAL '2 days', NULL, NULL),
    (31, 10, 'MENTORSHIP_SLOT_JOINED', 'New mentee enrolled', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 1, 'mentorship-slot:1:enrollment:1:mentor', seed_now - INTERVAL '10 days', seed_now - INTERVAL '0 days', NULL),
    (32, 12, 'MENTORSHIP_SLOT_JOINED', 'Enrolled in session', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 1, 'mentorship-slot:1:enrollment:1:mentee', seed_now - INTERVAL '10 days', seed_now - INTERVAL '0 days', NULL),
    (33, 10, 'MENTORSHIP_SLOT_LEFT', 'Mentee left session', 'A mentee released their place.', 'MENTORSHIP_SLOT', 1, 'mentorship-slot:1:left:1', seed_now - INTERVAL '7 days', seed_now - INTERVAL '0 days', NULL),
    (34, 10, 'MENTORSHIP_SLOT_JOINED', 'New mentee enrolled', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 1, 'mentorship-slot:1:enrollment:2:mentor', seed_now - INTERVAL '6 days', seed_now - INTERVAL '0 days', NULL),
    (35, 12, 'MENTORSHIP_SLOT_JOINED', 'Enrolled in session', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 1, 'mentorship-slot:1:enrollment:2:mentee', seed_now - INTERVAL '6 days', seed_now - INTERVAL '0 days', NULL),
    (36, 10, 'MENTORSHIP_SLOT_JOINED', 'New mentee enrolled', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 1, 'mentorship-slot:1:enrollment:3:mentor', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (37, 11, 'MENTORSHIP_SLOT_JOINED', 'Enrolled in session', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 1, 'mentorship-slot:1:enrollment:3:mentee', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (38, 9, 'MENTORSHIP_SLOT_JOINED', 'New mentee enrolled', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 2, 'mentorship-slot:2:enrollment:4:mentor', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (39, 17, 'MENTORSHIP_SLOT_JOINED', 'Enrolled in session', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 2, 'mentorship-slot:2:enrollment:4:mentee', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (40, 9, 'MENTORSHIP_SLOT_JOINED', 'New mentee enrolled', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 2, 'mentorship-slot:2:enrollment:5:mentor', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (41, 18, 'MENTORSHIP_SLOT_JOINED', 'Enrolled in session', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 2, 'mentorship-slot:2:enrollment:5:mentee', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (42, 10, 'MENTORSHIP_SLOT_JOINED', 'New mentee enrolled', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 3, 'mentorship-slot:3:enrollment:6:mentor', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (43, 26, 'MENTORSHIP_SLOT_JOINED', 'Enrolled in session', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 3, 'mentorship-slot:3:enrollment:6:mentee', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (44, 10, 'MENTORSHIP_SLOT_JOINED', 'New mentee enrolled', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 4, 'mentorship-slot:4:enrollment:7:mentor', seed_now - INTERVAL '6 days', seed_now - INTERVAL '0 days', NULL),
    (45, 12, 'MENTORSHIP_SLOT_JOINED', 'Enrolled in session', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 4, 'mentorship-slot:4:enrollment:7:mentee', seed_now - INTERVAL '6 days', seed_now - INTERVAL '0 days', NULL),
    (46, 12, 'MENTORSHIP_SLOT_CANCELLED', 'Mentorship session cancelled', 'The demo series was cancelled.', 'MENTORSHIP_SLOT', 4, 'mentorship-slot:4:cancelled:12', seed_now - INTERVAL '1 days', NULL, NULL),
    (47, 9, 'MENTORSHIP_SLOT_JOINED', 'New mentee enrolled', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 5, 'mentorship-slot:5:enrollment:8:mentor', seed_now - INTERVAL '15 days', seed_now - INTERVAL '0 days', NULL),
    (48, 11, 'MENTORSHIP_SLOT_JOINED', 'Enrolled in session', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 5, 'mentorship-slot:5:enrollment:8:mentee', seed_now - INTERVAL '15 days', seed_now - INTERVAL '0 days', NULL),
    (49, 25, 'MENTORSHIP_SLOT_JOINED', 'New mentee enrolled', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 6, 'mentorship-slot:6:enrollment:9:mentor', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (50, 22, 'MENTORSHIP_SLOT_JOINED', 'Enrolled in session', 'Demo enrollment notification.', 'MENTORSHIP_SLOT', 6, 'mentorship-slot:6:enrollment:9:mentee', seed_now - INTERVAL '5 days', seed_now - INTERVAL '0 days', NULL),
    (51, 8, 'PROJECT_APPLICATION_ACCEPTED', 'Project application accepted', 'Your demo application was accepted.', 'PROJECT', 2, 'project-application:1:PROJECT_APPLICATION_ACCEPTED', seed_now - INTERVAL '5 days', NULL, NULL),
    (52, 11, 'PROJECT_APPLICATION_REJECTED', 'Project application rejected', 'Your demo application was rejected.', 'PROJECT', 2, 'project-application:3:PROJECT_APPLICATION_REJECTED', seed_now - INTERVAL '5 days', NULL, NULL),
    (53, 14, 'PROJECT_APPLICATION_ACCEPTED', 'Project application accepted', 'Your demo application was accepted.', 'PROJECT', 3, 'project-application:4:PROJECT_APPLICATION_ACCEPTED', seed_now - INTERVAL '5 days', NULL, NULL),
    (54, 26, 'PROJECT_DELETED', 'Project deleted', 'A project you applied to was deleted.', 'PROJECT', 7, 'project-deleted:6', seed_now - INTERVAL '2 days', NULL, NULL),
    (55, 19, 'ACCOUNT_SUSPENDED', 'Account suspended', 'Your account has been suspended.', 'USER', 19, 'account-moderation:1', seed_now - INTERVAL '1 days', NULL, NULL),
    (56, 17, 'REPORT_RESOLVED', 'Report resolved', 'Your report was reviewed and action was taken.', 'REPORT', 1, 'report-resolution:1', seed_now - INTERVAL '12 hours', NULL, NULL),
    (57, 17, 'REPORT_RESOLVED', 'Report resolved', 'Your report was reviewed and no action was taken.', 'REPORT', 4, 'report-resolution:4', seed_now - INTERVAL '1 days', seed_now - INTERVAL '0 days', NULL),
    (58, 13, 'PUBLISHING_SUSPENDED', 'Club publishing suspended', 'Publishing suspended for club 2.', 'CLUB', 2, 'club-lifecycle:10', seed_now - INTERVAL '3 days', NULL, NULL),
    (59, 14, 'PUBLISHING_SUSPENDED', 'Club publishing suspended', 'Publishing suspended for club 2.', 'CLUB', 2, 'club-lifecycle:10', seed_now - INTERVAL '3 days', NULL, NULL);

END
$seed$;

-- Semantic validation takes place before the transaction can commit.
\ir checks.sql

DO $finish$
DECLARE c record; identity_sequence text; next_id bigint;
BEGIN
    IF NOT EXISTS(SELECT 1 FROM uniconnect_demo_seed_manifest) THEN
        -- ALTER SEQUENCE RESTART is transactional; unlike setval(), it rolls back on failure.
        FOR c IN SELECT table_name,column_name FROM information_schema.columns
            WHERE table_schema='public' AND is_identity='YES' LOOP
            identity_sequence := pg_get_serial_sequence('public.'||quote_ident(c.table_name),c.column_name);
            EXECUTE format('SELECT coalesce(max(%I),0)+1 FROM public.%I',c.column_name,c.table_name) INTO next_id;
            EXECUTE format('ALTER SEQUENCE %s RESTART WITH %s',identity_sequence,next_id);
        END LOOP;
        INSERT INTO uniconnect_demo_seed_manifest VALUES
            (1,CURRENT_TIMESTAMP AT TIME ZONE 'UTC',(CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Dhaka')::date,pg_temp.demo_fingerprint());
    END IF;
END
$finish$;
COMMIT;
SELECT seed_version,seeded_at,base_date FROM uniconnect_demo_seed_manifest;
SELECT user_id,full_name,email,platform_role,account_status FROM users ORDER BY user_id;
