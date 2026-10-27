\set ON_ERROR_STOP on
\pset pager off
BEGIN;
SET LOCAL search_path = public, pg_catalog;
SET LOCAL TIME ZONE 'UTC';
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '5min';
SELECT pg_advisory_xact_lock(26102702);

DO $guard$
BEGIN
  IF to_regclass('public.flyway_schema_history') IS NULL OR
     (SELECT count(*) FROM flyway_schema_history WHERE version IS NOT NULL AND success) <> 27 OR
     EXISTS (SELECT 1 FROM flyway_schema_history WHERE NOT success) OR
     NOT EXISTS (SELECT 1 FROM flyway_schema_history WHERE version='27'
       AND script='db.migration.V27__replace_email_verification_links_with_codes' AND success) THEN
    RAISE EXCEPTION 'Expected the exact successful UniConnect Flyway history through V27.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public'
      AND table_name='email_verification_tokens' AND column_name='token_hash') OR
     NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public'
      AND table_name='email_verification_tokens' AND column_name='code_digest') THEN
    RAISE EXCEPTION 'Target does not expose the V27 email-verification schema.';
  END IF;
END
$guard$;

CREATE TABLE IF NOT EXISTS uniconnect_presentation_seed_manifest (
  dataset_key varchar(100) PRIMARY KEY,
  seed_version integer NOT NULL CHECK (seed_version > 0),
  source_commit char(40) NOT NULL,
  seeded_at timestamp NOT NULL,
  base_date date NOT NULL,
  date_window_end date NOT NULL,
  account_count integer NOT NULL CHECK (account_count > 0)
);
CREATE TABLE IF NOT EXISTS uniconnect_presentation_seed_keys (
  dataset_key varchar(100) NOT NULL REFERENCES uniconnect_presentation_seed_manifest(dataset_key) ON DELETE RESTRICT,
  entity_type varchar(80) NOT NULL,
  logical_key varchar(150) NOT NULL,
  entity_id bigint NOT NULL,
  created_at timestamp NOT NULL,
  PRIMARY KEY (dataset_key, entity_type, logical_key),
  UNIQUE (dataset_key, entity_type, entity_id)
);

SELECT EXISTS (SELECT 1 FROM uniconnect_presentation_seed_manifest
  WHERE dataset_key='presentation-2026-v1' AND seed_version=1) AS needs_v1_repair,
  EXISTS (SELECT 1 FROM uniconnect_presentation_seed_manifest
  WHERE dataset_key='presentation-2026-v1' AND seed_version=2) AS needs_v2_repair,
  EXISTS (SELECT 1 FROM uniconnect_presentation_seed_manifest
  WHERE dataset_key='presentation-2026-v1' AND seed_version=3) AS needs_v3_report_upgrade,
  EXISTS (SELECT 1 FROM uniconnect_presentation_seed_manifest
  WHERE dataset_key='presentation-2026-v1' AND seed_version=4) AS needs_v4_history_repair,
  EXISTS (SELECT 1 FROM uniconnect_presentation_seed_manifest
  WHERE dataset_key='presentation-2026-v1' AND seed_version=5) AS already_applied \gset
\if :needs_v1_repair
  \ir repair-v1-vocabulary.sql
  \ir repair-v2-owned-relations.sql
  \ir upgrade-v3-reports.sql
  \ir repair-v4-report-history.sql
  COMMIT;
  \echo 'Presentation dataset v1 associations repaired; dataset is now v5.'
  \quit
\endif
\if :needs_v2_repair
  \ir repair-v2-owned-relations.sql
  \ir upgrade-v3-reports.sql
  \ir repair-v4-report-history.sql
  COMMIT;
  \echo 'Presentation dataset v2 owned relationships repaired; dataset is now v5.'
  \quit
\endif
\if :needs_v3_report_upgrade
  \ir upgrade-v3-reports.sql
  \ir repair-v4-report-history.sql
  COMMIT;
  \echo 'Presentation dataset report scenarios added; dataset is now v5.'
  \quit
\endif
\if :needs_v4_history_repair
  \ir repair-v4-report-history.sql
  COMMIT;
  \echo 'Presentation report review history normalized; dataset is now v5.'
  \quit
\endif
\if :already_applied
  COMMIT;
  \echo 'Presentation dataset already applied; no account or fixture rows were changed.'
  \quit
\endif

CREATE TEMP TABLE desired_accounts (
  logical_key text PRIMARY KEY, full_name text NOT NULL, email text NOT NULL UNIQUE,
  role text NOT NULL, programme_code text, academic_year integer, graduation_year integer,
  bio text, project_available boolean, mentor_available boolean, visibility text,
  skills text[] NOT NULL, interests text[] NOT NULL,
  existing_user_id bigint, existing_profile_id bigint
);
INSERT INTO desired_accounts VALUES
('admin_ayman','Ayman','ayman@iut-dhaka.edu','SYSTEM_ADMIN',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{}','{}',NULL,NULL),
('admin_sayma','Sayma','sayma@iut-dhaka.edu','SYSTEM_ADMIN',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'{}','{}',NULL,NULL),
('farhan_rahman','Farhan Rahman','pres.farhan.rahman@iut-dhaka.edu','STUDENT','SWE',4,NULL,'Backend engineering enthusiast building reliable campus systems.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['java','spring boot','postgresql','sql','git','docker'],ARRAY['distributed systems','open source','campus technology'],NULL,NULL),
('nusrat_jahan','Nusrat Jahan','pres.nusrat.jahan@iut-dhaka.edu','STUDENT','CSE',4,NULL,'Fourth-year student mentoring databases and clean API design.',TRUE,TRUE,'ALL_MEMBERS',ARRAY['java','sql','postgresql','algorithms'],ARRAY['mentoring','distributed systems','competitive programming'],NULL,NULL),
('abdullah_mamun','Abdullah Al Mamun','pres.abdullah.mamun@iut-dhaka.edu','STUDENT','SWE',3,NULL,'Backend developer focused on Spring services and PostgreSQL.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['java','spring boot','postgresql','sql','docker'],ARRAY['distributed systems','open source'],NULL,NULL),
('tasnim_ahmed','Tasnim Ahmed','pres.tasnim.ahmed@iut-dhaka.edu','STUDENT','CSE',3,NULL,'Software student learning scalable backend design.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['java','sql','git'],ARRAY['distributed systems','campus technology'],NULL,NULL),
('mahmud_hasan','Mahmud Hasan','pres.mahmud.hasan@iut-dhaka.edu','STUDENT','SWE',4,NULL,'Flutter developer interested in accessible mobile experiences.',TRUE,TRUE,'ALL_MEMBERS',ARRAY['flutter','dart','firebase','git'],ARRAY['mobile development','accessibility','mentoring'],NULL,NULL),
('aisha_siddika','Aisha Siddika','pres.aisha.siddika@iut-dhaka.edu','STUDENT','CSE',2,NULL,'Python learner exploring data analysis and machine learning.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['python','data analysis','machine learning','sql'],ARRAY['artificial intelligence','data science'],NULL,NULL),
('omar_faruk','Omar Faruk','pres.omar.faruk@iut-dhaka.edu','STUDENT','EEE',4,NULL,'Embedded-systems builder working with sensors and control.',TRUE,TRUE,'ALL_MEMBERS',ARRAY['c','embedded systems','iot','circuit design'],ARRAY['robotics','renewable energy','mentoring'],NULL,NULL),
('mariam_akter','Mariam Akter','pres.mariam.akter@iut-dhaka.edu','STUDENT','SWE',1,NULL,'Web development learner contributing to campus activities.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['javascript','react','html','css'],ARRAY['web development','campus technology'],NULL,NULL),
('yusuf_islam','Yusuf Islam','pres.yusuf.islam@iut-dhaka.edu','STUDENT','CSE',4,NULL,'Competitive programmer and peer mentor for algorithms.',TRUE,TRUE,'ALL_MEMBERS',ARRAY['algorithms','data structures','c++','git'],ARRAY['competitive programming','mentoring'],NULL,NULL),
('sumaiya_noor','Sumaiya Noor','pres.sumaiya.noor@iut-dhaka.edu','STUDENT','CSE',3,NULL,'Machine-learning student interested in responsible models.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['python','machine learning','data analysis','sql'],ARRAY['artificial intelligence','data science'],NULL,NULL),
('ibrahim_khalil','Ibrahim Khalil','pres.ibrahim.khalil@iut-dhaka.edu','STUDENT','EEE',2,NULL,'Robotics enthusiast combining firmware and electronics.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['c','embedded systems','iot','circuit design'],ARRAY['robotics','renewable energy'],NULL,NULL),
('fatima_zahra','Fatima Zahra','pres.fatima.zahra@iut-dhaka.edu','STUDENT','CSE',4,NULL,'Security-minded student who shares details with connections.',TRUE,FALSE,'CONNECTIONS_ONLY',ARRAY['java','cybersecurity','sql'],ARRAY['information security','open source'],NULL,NULL),
('rayhan_kabir','Rayhan Kabir','pres.rayhan.kabir@iut-dhaka.edu','STUDENT','SWE',3,NULL,'Full-stack student seeking practical team experience.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['javascript','react','java','git'],ARRAY['web development','open source'],NULL,NULL),
('sadia_afrin','Sadia Afrin','pres.sadia.afrin@iut-dhaka.edu','STUDENT','BBA-TM',2,NULL,'Technology-management student coordinating club programmes.',FALSE,FALSE,'ALL_MEMBERS',ARRAY['project management','excel','communication'],ARRAY['entrepreneurship','university activities'],NULL,NULL),
('zubair_ahmed','Zubair Ahmed','pres.zubair.ahmed@iut-dhaka.edu','STUDENT','SWE',4,NULL,'Club representative and mobile application contributor.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['flutter','dart','git'],ARRAY['mobile development','university activities'],NULL,NULL),
('nabila_sultana','Nabila Sultana','pres.nabila.sultana@iut-dhaka.edu','STUDENT','CSE',3,NULL,'Student community volunteer demonstrating reporting flows.',FALSE,FALSE,'ALL_MEMBERS',ARRAY['python','communication','sql'],ARRAY['community service','campus technology'],NULL,NULL),
('hamza_chowdhury','Hamza Chowdhury','pres.hamza.chowdhury@iut-dhaka.edu','STUDENT','CE',2,NULL,'Civil engineering student used for privacy comparisons.',FALSE,FALSE,'ALL_MEMBERS',ARRAY['autocad','project management'],ARRAY['sustainable infrastructure'],NULL,NULL),
('rukaiya_islam','Rukaiya Islam','pres.rukaiya.islam@iut-dhaka.edu','STUDENT','SWE',1,NULL,'Beginning software student with connection-only details.',TRUE,FALSE,'CONNECTIONS_ONLY',ARRAY['html','css','git'],ARRAY['web development','design'],NULL,NULL),
('tahmid_hassan','Tahmid Hassan','pres.tahmid.hassan@iut-dhaka.edu','STUDENT','CSE',4,NULL,'Mobile engineer contributing to a campus navigation project.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['flutter','dart','firebase','algorithms'],ARRAY['mobile development','campus technology'],NULL,NULL),
('samira_khan','Samira Khan','pres.samira.khan@iut-dhaka.edu','STUDENT','CSE',3,NULL,'Data analyst building useful student-facing dashboards.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['python','data analysis','sql','machine learning'],ARRAY['data science','campus technology'],NULL,NULL),
('arif_hossain','Arif Hossain','pres.arif.hossain@iut-dhaka.edu','STUDENT','BBA-TM',2,NULL,'Business student exploring product and internship opportunities.',FALSE,FALSE,'ALL_MEMBERS',ARRAY['excel','project management','communication'],ARRAY['entrepreneurship','product management'],NULL,NULL),
('lamia_rahman','Lamia Rahman','pres.lamia.rahman@iut-dhaka.edu','STUDENT','CE',4,NULL,'Civil engineering student leading a sustainability project.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['autocad','data analysis','project management'],ARRAY['sustainable infrastructure','renewable energy'],NULL,NULL),
('adnan_karim','Adnan Karim','pres.adnan.karim@iut-dhaka.edu','STUDENT','ME',3,NULL,'Mechanical engineering student interested in automation.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['solidworks','c','project management'],ARRAY['robotics','manufacturing'],NULL,NULL),
('jannat_ferdous','Jannat Ferdous','pres.jannat.ferdous@iut-dhaka.edu','STUDENT','IPE',2,NULL,'Industrial engineering student exploring operations analytics.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['excel','data analysis','project management'],ARRAY['manufacturing','data science'],NULL,NULL),
('imran_siddique','Imran Siddique','pres.imran.siddique@iut-dhaka.edu','STUDENT','EEE',4,NULL,'Embedded developer contributing to an energy monitor.',TRUE,FALSE,'ALL_MEMBERS',ARRAY['c','embedded systems','iot','circuit design'],ARRAY['renewable energy','robotics'],NULL,NULL),
('hafsa_mahjabin','Hafsa Mahjabin','pres.hafsa.mahjabin@iut-dhaka.edu','STUDENT','SWE',3,NULL,'Student volunteer coordinating events and announcements.',FALSE,FALSE,'ALL_MEMBERS',ARRAY['communication','project management','javascript'],ARRAY['university activities','community service'],NULL,NULL),
('ahmed_faisal','Ahmed Faisal','pres.ahmed.faisal@iut-dhaka.edu','ALUMNI','CSE',NULL,2018,'Backend engineer mentoring scalable service design.',NULL,NULL,'ALL_MEMBERS',ARRAY['java','spring boot','postgresql','docker'],ARRAY['distributed systems','mentoring'],NULL,NULL),
('sabrina_haque','Sabrina Haque','pres.sabrina.haque@iut-dhaka.edu','ALUMNI','BBA-TM',NULL,2019,'Product manager supporting student career development.',NULL,NULL,'ALL_MEMBERS',ARRAY['product management','project management','communication'],ARRAY['entrepreneurship','mentoring'],NULL,NULL),
('mohammad_rafiq','Mohammad Rafiq','pres.mohammad.rafiq@iut-dhaka.edu','ALUMNI','SWE',NULL,2020,'Mobile engineer mentoring Flutter architecture.',NULL,NULL,'ALL_MEMBERS',ARRAY['flutter','dart','firebase','git'],ARRAY['mobile development','mentoring'],NULL,NULL),
('khadija_noor','Khadija Noor','pres.khadija.noor@iut-dhaka.edu','ALUMNI','CSE',NULL,2017,'Data scientist mentoring practical machine learning.',NULL,NULL,'ALL_MEMBERS',ARRAY['python','machine learning','data analysis','sql'],ARRAY['artificial intelligence','mentoring'],NULL,NULL),
('saif_uddin','Saif Uddin','pres.saif.uddin@iut-dhaka.edu','ALUMNI','EEE',NULL,2016,'Embedded-systems engineer working in industrial IoT.',NULL,NULL,'ALL_MEMBERS',ARRAY['c','embedded systems','iot','circuit design'],ARRAY['robotics','manufacturing'],NULL,NULL),
('meherun_nesa','Meherun Nesa','pres.meherun.nesa@iut-dhaka.edu','ALUMNI','SWE',NULL,2021,'Frontend engineer focused on inclusive web products.',NULL,NULL,'ALL_MEMBERS',ARRAY['javascript','react','html','css'],ARRAY['web development','accessibility'],NULL,NULL),
('tariq_mahmood','Tariq Mahmood','pres.tariq.mahmood@iut-dhaka.edu','ALUMNI','ME',NULL,2015,'Mechanical engineer participating in alumni mentorship.',NULL,NULL,'CONNECTIONS_ONLY',ARRAY['solidworks','project management'],ARRAY['manufacturing','mentoring'],NULL,NULL),
('anika_rahman','Anika Rahman','pres.anika.rahman@iut-dhaka.edu','ALUMNI','CSE',NULL,2020,'Engineering recruiter sharing safe fictional opportunities.',NULL,NULL,'ALL_MEMBERS',ARRAY['java','communication','project management'],ARRAY['career development','mentoring'],NULL,NULL);

UPDATE desired_accounts d SET existing_user_id=u.user_id, existing_profile_id=p.profile_id
FROM users u LEFT JOIN personal_profiles p ON p.user_id=u.user_id WHERE lower(u.email)=d.email;

DO $conflicts$
DECLARE conflict text;
BEGIN
  SELECT string_agg(d.email, ', ') INTO conflict FROM desired_accounts d JOIN users u ON lower(u.email)=d.email
  WHERE u.anonymized_at IS NOT NULL;
  IF conflict IS NOT NULL THEN RAISE EXCEPTION 'Anonymized account collision(s): %', conflict; END IF;
  SELECT string_agg(d.email, ', ') INTO conflict FROM desired_accounts d JOIN users u ON lower(u.email)=d.email
  WHERE d.email NOT IN ('ayman@iut-dhaka.edu','sayma@iut-dhaka.edu') AND u.full_name IS DISTINCT FROM d.full_name;
  IF conflict IS NOT NULL THEN RAISE EXCEPTION 'Unexpected identity collision(s): %', conflict; END IF;
  SELECT string_agg(email_key, ', ') INTO conflict FROM (
    SELECT lower(u.email) email_key FROM users u JOIN desired_accounts d ON lower(u.email)=d.email
    GROUP BY lower(u.email) HAVING count(*) > 1) duplicates;
  IF conflict IS NOT NULL THEN RAISE EXCEPTION 'Case-variant duplicate account collision(s): %', conflict; END IF;
END
$conflicts$;

INSERT INTO uniconnect_presentation_seed_manifest
VALUES ('presentation-2026-v1',3,'e83b1fdd9ab4bbea3479e202ef29f692d3cb15a1',
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC',(CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Dhaka')::date,
        (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Dhaka')::date + 60,36);

SELECT set_config('uniconnect.presentation_password_hash', :'password_hash', true) AS password_configured \gset

DO $accounts$
DECLARE d record; uid bigint; now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
BEGIN
  FOR d IN SELECT * FROM desired_accounts ORDER BY logical_key LOOP
    IF d.existing_user_id IS NULL THEN
      INSERT INTO users(full_name,email,password_hash,platform_role,account_status,created_at,updated_at)
      VALUES(d.full_name,d.email,current_setting('uniconnect.presentation_password_hash'),d.role,'ACTIVE',now_utc - interval '45 days',now_utc)
      RETURNING user_id INTO uid;
    ELSE
      PERFORM 1 FROM users WHERE user_id=d.existing_user_id FOR UPDATE;
      uid := d.existing_user_id;
      UPDATE authenticated_sessions SET revoked_at=now_utc,revocation_reason='ACCOUNT_CHANGE'
      WHERE user_id=uid AND revoked_at IS NULL;
      UPDATE users SET full_name=CASE WHEN d.email IN ('ayman@iut-dhaka.edu','sayma@iut-dhaka.edu')
             THEN coalesce(full_name,d.full_name) ELSE d.full_name END,
             email=d.email,password_hash=current_setting('uniconnect.presentation_password_hash'),
             platform_role=d.role,account_status='ACTIVE',updated_at=now_utc
      WHERE user_id=uid;
    END IF;
    INSERT INTO uniconnect_presentation_seed_keys VALUES
      ('presentation-2026-v1','USER',d.logical_key,uid,now_utc);
  END LOOP;
END
$accounts$;

SELECT set_config('uniconnect.presentation_failpoint', :'failpoint', true);
DO $failpoint$
BEGIN
  IF current_setting('uniconnect.presentation_failpoint',true)='after_accounts' THEN
    RAISE EXCEPTION 'Intentional presentation seed failure after accounts';
  END IF;
END
$failpoint$;

-- Official IUT departments and undergraduate programmes. Existing matching codes are reused.
DO $catalogue$
DECLARE r record; did bigint; pid bigint;
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('CSE','Computer Science and Engineering'),('EEE','Electrical and Electronic Engineering'),
    ('MPE','Mechanical and Production Engineering'),('CEE','Civil and Environmental Engineering'),
    ('BTM','Business and Technology Management')) x(code,name) LOOP
    SELECT department_id INTO did FROM departments WHERE lower(department_code)=lower(r.code);
    IF did IS NULL THEN INSERT INTO departments(department_name,department_code) VALUES(r.name,r.code) RETURNING department_id INTO did;
    ELSIF NOT EXISTS(SELECT 1 FROM departments WHERE department_id=did AND department_name=r.name) THEN
      RAISE EXCEPTION 'Department code % exists with an unexpected name',r.code;
    END IF;
  END LOOP;
  FOR r IN SELECT * FROM (VALUES
    ('CSE','CSE','Computer Science and Engineering'),('SWE','CSE','Software Engineering'),
    ('EEE','EEE','Electrical and Electronic Engineering'),('ME','MPE','Mechanical Engineering'),
    ('IPE','MPE','Industrial and Production Engineering'),('CE','CEE','Civil Engineering'),
    ('BBA-TM','BTM','Technology Management')) x(code,dept,name) LOOP
    SELECT programme_id INTO pid FROM programmes WHERE lower(programme_code)=lower(r.code);
    SELECT department_id INTO did FROM departments WHERE lower(department_code)=lower(r.dept);
    IF pid IS NULL THEN INSERT INTO programmes(department_id,programme_name,programme_code) VALUES(did,r.name,r.code) RETURNING programme_id INTO pid;
    ELSIF NOT EXISTS(SELECT 1 FROM programmes WHERE programme_id=pid AND department_id=did AND programme_name=r.name) THEN
      RAISE EXCEPTION 'Programme code % has an unexpected name or department',r.code;
    END IF;
    IF NOT EXISTS(SELECT 1 FROM programme_degrees WHERE programme_id=pid AND degree_level='BACHELOR') THEN
      INSERT INTO programme_degrees(programme_id,degree_level,duration_years,minimum_year,maximum_year,active)
      VALUES(pid,'BACHELOR',4,1,4,TRUE);
    END IF;
  END LOOP;
END
$catalogue$;

INSERT INTO skills(name,category)
SELECT desired.name,'presentation' FROM unnest(ARRAY['java','spring boot','postgresql','sql','git','docker','flutter','dart','firebase',
 'python','data analysis','machine learning','c','c++','embedded systems','iot','circuit design','javascript','react','html','css',
 'algorithms','data structures','cybersecurity','project management','excel','communication','autocad','solidworks','product management']) AS desired(name)
WHERE NOT EXISTS(SELECT 1 FROM skills s WHERE lower(s.name)=desired.name);
INSERT INTO interests(name)
SELECT desired.name FROM unnest(ARRAY['distributed systems','open source','campus technology','mentoring','competitive programming',
 'mobile development','accessibility','artificial intelligence','data science','robotics','renewable energy','web development',
 'information security','entrepreneurship','university activities','community service','sustainable infrastructure','design',
 'product management','manufacturing','career development']) AS desired(name)
WHERE NOT EXISTS(SELECT 1 FROM interests i WHERE lower(i.name)=desired.name);

CREATE FUNCTION pg_temp.uid(k text) RETURNS bigint LANGUAGE sql STABLE AS $$
  SELECT entity_id FROM uniconnect_presentation_seed_keys
  WHERE dataset_key='presentation-2026-v1' AND entity_type='USER' AND logical_key=k
$$;
CREATE FUNCTION pg_temp.eid(t text,k text) RETURNS bigint LANGUAGE sql STABLE AS $$
  SELECT entity_id FROM uniconnect_presentation_seed_keys
  WHERE dataset_key='presentation-2026-v1' AND entity_type=t AND logical_key=k
$$;

DO $profiles$
DECLARE d record; pdid bigint; pid bigint; now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
BEGIN
  FOR d IN SELECT * FROM desired_accounts WHERE role<>'SYSTEM_ADMIN' ORDER BY logical_key LOOP
    IF d.existing_profile_id IS NOT NULL THEN
      pid := d.existing_profile_id;
      IF NOT EXISTS(SELECT 1 FROM personal_profiles WHERE profile_id=pid AND profile_type=d.role) THEN
        RAISE EXCEPTION 'Existing profile type conflicts for %',d.email;
      END IF;
    ELSE
      SELECT pd.programme_degree_id INTO pdid FROM programme_degrees pd JOIN programmes p USING(programme_id)
      WHERE lower(p.programme_code)=lower(d.programme_code) AND pd.degree_level='BACHELOR';
      IF d.role='STUDENT' THEN
        INSERT INTO personal_profiles(user_id,profile_type,programme_degree_id,bio,created_at,updated_at,
          student_number,year_of_study,expected_graduation_year,project_availability,mentorship_availability,details_visibility)
        VALUES(pg_temp.uid(d.logical_key),'STUDENT',pdid,d.bio,now_utc-interval '40 days',now_utc,
          'PRES-'||upper(substr(md5(d.logical_key),1,10)),d.academic_year,
          extract(year FROM CURRENT_DATE)::int+(4-d.academic_year),d.project_available,d.mentor_available,d.visibility)
        RETURNING profile_id INTO pid;
      ELSE
        INSERT INTO personal_profiles(user_id,profile_type,programme_degree_id,bio,created_at,updated_at,
          graduation_year,current_company,current_position,industry,career_background,linkedin_url,details_visibility)
        VALUES(pg_temp.uid(d.logical_key),'ALUMNI',pdid,d.bio,now_utc-interval '40 days',now_utc,d.graduation_year,
          CASE d.logical_key WHEN 'ahmed_faisal' THEN 'Northstar Systems' WHEN 'sabrina_haque' THEN 'Crescent Product Studio'
            WHEN 'mohammad_rafiq' THEN 'Riverstone Mobile' WHEN 'khadija_noor' THEN 'Atlas Analytics'
            WHEN 'saif_uddin' THEN 'Delta Embedded Labs' WHEN 'meherun_nesa' THEN 'OpenCanvas'
            WHEN 'tariq_mahmood' THEN 'Apex Manufacturing' ELSE 'BrightPath Talent' END,
          CASE WHEN d.logical_key='sabrina_haque' THEN 'Product Manager' WHEN d.logical_key='anika_rahman' THEN 'Technical Recruiter'
            WHEN d.logical_key='tariq_mahmood' THEN 'Mechanical Engineer' ELSE 'Senior Engineer' END,
          CASE WHEN d.programme_code='BBA-TM' THEN 'Product Management' WHEN d.programme_code='EEE' THEN 'Embedded Systems'
            WHEN d.programme_code='ME' THEN 'Manufacturing' ELSE 'Software and Data' END,
          'Fictional presentation profile illustrating alumni expertise and mentorship.',
          'https://profiles.example.test/'||d.logical_key,d.visibility)
        RETURNING profile_id INTO pid;
      END IF;
    END IF;
    INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','PROFILE',d.logical_key,pid,now_utc);
    IF d.existing_profile_id IS NULL THEN
      INSERT INTO profile_skills(profile_id,skill_id) SELECT pid,s.skill_id FROM unnest(d.skills) n(name)
        JOIN skills s ON lower(s.name)=n.name;
      INSERT INTO profile_interests(profile_id,interest_id) SELECT pid,i.interest_id FROM unnest(d.interests) n(name)
        JOIN interests i ON lower(i.name)=n.name;
    END IF;
  END LOOP;
END
$profiles$;

-- Connections include student/student, student/alumni, alumni/alumni, and pending directions.
DO $connections$
DECLARE r record; id bigint; lo bigint; hi bigint; now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
BEGIN
 FOR r IN SELECT * FROM (VALUES
  ('farhan-abdullah','farhan_rahman','abdullah_mamun','ACCEPTED',20),
  ('farhan-tasnim','farhan_rahman','tasnim_ahmed','ACCEPTED',19),
  ('nusrat-ahmed','nusrat_jahan','ahmed_faisal','ACCEPTED',18),
  ('mahmud-rafiq','mahmud_hasan','mohammad_rafiq','ACCEPTED',17),
  ('ahmed-sabrina','ahmed_faisal','sabrina_haque','ACCEPTED',16),
  ('khadija-anika','khadija_noor','anika_rahman','ACCEPTED',15),
  ('mariam-farhan','mariam_akter','farhan_rahman','PENDING',3),
  ('nabila-sadia','nabila_sultana','sadia_afrin','PENDING',2),
  ('arif-sabrina','arif_hossain','sabrina_haque','PENDING',1)) x(k,requester,receiver,status,days) LOOP
   lo:=least(pg_temp.uid(r.requester),pg_temp.uid(r.receiver)); hi:=greatest(pg_temp.uid(r.requester),pg_temp.uid(r.receiver));
   IF EXISTS(SELECT 1 FROM connections WHERE open_low=lo AND open_high=hi) THEN
     RAISE EXCEPTION 'Existing open connection conflicts with presentation pair %',r.k;
   END IF;
   INSERT INTO connections(requester_id,receiver_id,user_low,user_high,open_low,open_high,status,introductory_message,requested_at,accepted_at,closed_at)
   VALUES(pg_temp.uid(r.requester),pg_temp.uid(r.receiver),lo,hi,lo,hi,r.status,
     'Assalamu alaikum, I would like to connect through the UniConnect presentation network.',now_utc-r.days*interval '1 day',
     CASE WHEN r.status='ACCEPTED' THEN now_utc-(r.days-1)*interval '1 day' END,NULL) RETURNING connection_id INTO id;
   INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','CONNECTION',r.k,id,now_utc);
 END LOOP;
END
$connections$;

-- Natural chat history; no existing conversation can be reused or modified.
DO $chat$
DECLARE r record; cid bigint; mid bigint; lo bigint; hi bigint; sender bigint; recipient bigint;
 now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC'; idx integer;
BEGIN
 FOR r IN SELECT * FROM (VALUES
  ('backend-mentoring','nusrat_jahan','ahmed_faisal'),('mobile-project','mahmud_hasan','mohammad_rafiq'),
  ('club-planning','sadia_afrin','zubair_ahmed'),('internship-advice','arif_hossain','sabrina_haque')) x(k,a,b) LOOP
   lo:=least(pg_temp.uid(r.a),pg_temp.uid(r.b)); hi:=greatest(pg_temp.uid(r.a),pg_temp.uid(r.b));
   IF EXISTS(SELECT 1 FROM chat_conversations WHERE user_low=lo AND user_high=hi) THEN
     RAISE EXCEPTION 'Existing real conversation conflicts with presentation pair %',r.k;
   END IF;
   INSERT INTO chat_conversations(user_low,user_high,created_at,last_message_at)
    VALUES(lo,hi,now_utc-interval '8 days',now_utc-interval '6 hours') RETURNING conversation_id INTO cid;
   INSERT INTO chat_participants(conversation_id,user_id,slot,joined_at) VALUES(cid,lo,1,now_utc-interval '8 days'),(cid,hi,2,now_utc-interval '8 days');
   INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','CONVERSATION',r.k,cid,now_utc);
   FOR idx IN 1..3 LOOP
     sender:=CASE WHEN idx=2 THEN pg_temp.uid(r.b) ELSE pg_temp.uid(r.a) END;
     recipient:=CASE WHEN sender=pg_temp.uid(r.a) THEN pg_temp.uid(r.b) ELSE pg_temp.uid(r.a) END;
     INSERT INTO chat_messages(conversation_id,sender_id,client_message_id,content,sent_at)
     VALUES(cid,sender,md5(r.k||idx)::uuid,
       CASE r.k||':'||idx
        WHEN 'backend-mentoring:1' THEN 'Assalamu alaikum, could we discuss transaction boundaries for our project?'
        WHEN 'backend-mentoring:2' THEN 'Certainly. Bring the schema and we will review locking and rollback together.'
        WHEN 'backend-mentoring:3' THEN 'Great, I prepared a small PostgreSQL example for the session.'
        WHEN 'mobile-project:1' THEN 'The campus navigation prototype now supports offline map markers.'
        WHEN 'mobile-project:2' THEN 'Excellent. Please also test the loading and retry states on Android.'
        WHEN 'mobile-project:3' THEN 'I will share the widget test results before our next meeting.'
        WHEN 'club-planning:1' THEN 'Can you prepare the volunteer briefing for Innovation Week?'
        WHEN 'club-planning:2' THEN 'Yes, I will include registration desk and stage responsibilities.'
        WHEN 'club-planning:3' THEN 'Thank you. Let us confirm the final schedule tomorrow.'
        WHEN 'internship-advice:1' THEN 'Could you review my preparation plan for product internships?'
        WHEN 'internship-advice:2' THEN 'Focus on one case study and explain the decisions, not only the outcome.'
        ELSE 'I will revise the case study and send a concise version this week.' END,
       now_utc-(4-idx)*interval '6 hours') RETURNING message_id INTO mid;
     INSERT INTO chat_message_states(message_id,conversation_id,user_id,delivered_at,read_at)
     VALUES(mid,cid,sender,now_utc-(4-idx)*interval '6 hours'+interval '1 minute',now_utc-(4-idx)*interval '6 hours'+interval '2 minutes'),
       (mid,cid,recipient,now_utc-(4-idx)*interval '6 hours'+interval '2 minutes',
        CASE WHEN idx<3 THEN now_utc-(4-idx)*interval '6 hours'+interval '10 minutes' END);
     IF idx=3 THEN
       INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at)
       VALUES(recipient,'NEW_MESSAGE','New message','You have a new presentation conversation message.','CONVERSATION',cid,
         'presentation:chat:'||r.k||':3',now_utc-interval '6 hours');
     END IF;
   END LOOP;
 END LOOP;
END
$chat$;

-- Clubs and publication material.
DO $clubs$
DECLARE r record; cid bigint; aid bigint; now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
BEGIN
 FOR r IN SELECT * FROM (VALUES
  ('innovation','UniConnect Innovation Society','Technology and Innovation','Student-led software, robotics and product showcases.','sadia_afrin'),
  ('robotics','UniConnect Robotics Circle','Engineering','Hands-on embedded systems and robotics activities.','omar_faruk'),
  ('career','UniConnect Career Forum','Career Development','Fictional workshops connecting students and alumni.','sabrina_haque')) x(k,name,category,description,admin_key) LOOP
   IF EXISTS(SELECT 1 FROM clubs WHERE name_key=lower(r.name)) THEN RAISE EXCEPTION 'Club name collision: %',r.name; END IF;
   INSERT INTO clubs(club_name,name_key,category,description,contact_email,status,created_at,updated_at)
    VALUES(r.name,lower(r.name),r.category,r.description,'pres.'||r.k||'.club@iut-dhaka.edu','ACTIVE',now_utc-interval '35 days',now_utc)
    RETURNING club_id INTO cid;
   INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','CLUB',r.k,cid,now_utc);
   INSERT INTO club_role_assignments(club_id,user_id,role,assigned_by,assigned_at,current_club_id,current_user_id,administrator_club_id,administrator_user_id)
    VALUES(cid,pg_temp.uid(r.admin_key),'CLUB_ADMINISTRATOR',pg_temp.uid('admin_ayman'),now_utc-interval '34 days',cid,pg_temp.uid(r.admin_key),cid,pg_temp.uid(r.admin_key))
    RETURNING assignment_id INTO aid;
   INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','CLUB_ASSIGNMENT',r.k||'-admin',aid,now_utc);
   INSERT INTO club_audit(club_id,actor_id,target_assignment_id,action,reason,created_at)
    VALUES(cid,pg_temp.uid('admin_ayman'),aid,'CLUB_CREATED','Presentation club approved for a fictional demonstration.',now_utc-interval '34 days');
 END LOOP;
 -- Representatives.
 FOR r IN SELECT * FROM (VALUES('innovation','zubair_ahmed'),('innovation','hafsa_mahjabin'),('robotics','ibrahim_khalil'),('career','anika_rahman')) x(club_key,user_key) LOOP
   cid:=pg_temp.eid('CLUB',r.club_key);
   INSERT INTO club_role_assignments(club_id,user_id,role,assigned_by,assigned_at,current_club_id,current_user_id)
    VALUES(cid,pg_temp.uid(r.user_key),'REPRESENTATIVE',pg_temp.uid('admin_ayman'),now_utc-interval '25 days',cid,pg_temp.uid(r.user_key))
    RETURNING assignment_id INTO aid;
   INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','CLUB_ASSIGNMENT',r.club_key||'-'||r.user_key,aid,now_utc);
   INSERT INTO club_audit(club_id,actor_id,target_assignment_id,action,reason,created_at)
    VALUES(cid,pg_temp.uid('admin_ayman'),aid,'ROLE_GRANTED','Presentation representative assignment.',now_utc-interval '25 days');
 END LOOP;
 -- Pending requests remain consumable actions.
 INSERT INTO club_creation_requests(requester_user_id,club_name,name_key,category,description,contact_email,status,created_at,updated_at)
 VALUES(pg_temp.uid('lamia_rahman'),'Sustainable Design Collective','sustainable design collective','Engineering',
   'A proposed student group for sustainable campus design.','pres.lamia.rahman@iut-dhaka.edu','PENDING',now_utc-interval '2 days',now_utc-interval '2 days'),
  (pg_temp.uid('samira_khan'),'IUT Data Community','iut data community','Technology',
   'A proposed peer community for data literacy and responsible analytics.','pres.samira.khan@iut-dhaka.edu','PENDING',now_utc-interval '1 day',now_utc-interval '1 day');
 -- Announcements and relative-time events.
 cid:=pg_temp.eid('CLUB','innovation'); aid:=pg_temp.eid('CLUB_ASSIGNMENT','innovation-admin');
 INSERT INTO club_announcements(club_id,author_user_id,author_assignment_id,title,content,priority,status,created_at,updated_at,published_at,expires_at)
 VALUES(cid,pg_temp.uid('sadia_afrin'),aid,'Innovation Week volunteer briefing','Volunteer roles and the presentation-day schedule are now available.','IMPORTANT','PUBLISHED',now_utc-interval '5 days',now_utc-interval '1 day',now_utc-interval '5 days',now_utc+interval '14 days'),
  (cid,pg_temp.uid('sadia_afrin'),aid,'Prototype showcase registrations','Teams may register safe fictional prototypes before the listed deadline.','NORMAL','PUBLISHED',now_utc-interval '3 days',now_utc,now_utc-interval '3 days',now_utc+interval '20 days'),
  (cid,pg_temp.uid('sadia_afrin'),aid,'Next semester planning notes','Draft agenda retained for administrator demonstration.','NORMAL','UNPUBLISHED',now_utc-interval '1 day',now_utc,NULL,NULL);
 INSERT INTO club_events(club_id,author_user_id,author_assignment_id,title,description,location,registration_url,registration_deadline,starts_at,ends_at,status,published_at,updated_at)
 VALUES(cid,pg_temp.uid('sadia_afrin'),aid,'Innovation Week Showcase','Student prototypes and alumni feedback sessions.','IUT Auditorium','https://events.example.test/innovation-week',now_utc+interval '9 days',now_utc+interval '10 days',now_utc+interval '10 days 4 hours','PUBLISHED',now_utc-interval '7 days',now_utc),
  (cid,pg_temp.uid('sadia_afrin'),aid,'Campus App Design Sprint','An active presentation example for event timing.','CSE Design Lab','https://events.example.test/design-sprint',now_utc-interval '1 day',now_utc-interval '1 hour',now_utc+interval '2 hours','PUBLISHED',now_utc-interval '10 days',now_utc),
  (cid,pg_temp.uid('sadia_afrin'),aid,'Open Source Orientation','A completed fictional event retained in history.','CSE Seminar Room',NULL,now_utc-interval '9 days',now_utc-interval '8 days',now_utc-interval '8 days'+interval '2 hours','PUBLISHED',now_utc-interval '20 days',now_utc-interval '8 days');
END
$clubs$;

-- Projects and recommendation candidates use the real 70/20/10 scoring inputs.
DO $projects$
DECLARE r record; pid bigint; appid bigint; now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC'; base date := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Dhaka')::date;
BEGIN
 FOR r IN SELECT * FROM (VALUES
  ('campus-services','farhan_rahman','Campus Services API','A reliable API for fictional campus service requests.',5,'12 weeks','Software Engineering',base+35,'OPEN'),
  ('navigation','mahmud_hasan','Accessible Campus Navigator','Flutter navigation prototype with accessible offline guidance.',4,'10 weeks','Mobile Application Development',base+28,'OPEN'),
  ('energy','omar_faruk','Smart Lab Energy Monitor','Embedded monitor for fictional laboratory energy use.',3,'14 weeks','Embedded Systems',base+30,'OPEN'),
  ('sustainability','lamia_rahman','Sustainable Campus Dashboard','Civil and data collaboration for sustainability indicators.',4,'8 weeks','Engineering Project',base+21,'OPEN'),
  ('full-algorithms','yusuf_islam','Programming Practice Portal','A full project illustrating capacity-derived status.',2,'6 weeks','Algorithms',base+20,'OPEN'),
  ('closed-archive','fatima_zahra','Security Checklist Toolkit','A manually closed project retained for presentation history.',4,'6 weeks','Information Security',base+10,'CLOSED')) x(k,creator,title,description,limit_size,duration,course,deadline,status) LOOP
   INSERT INTO teammate_projects(creator_user_id,title,description,team_size_limit,duration,course_name,application_deadline,status,created_at,updated_at,closed_at)
    VALUES(pg_temp.uid(r.creator),r.title,r.description,r.limit_size,r.duration,r.course,r.deadline,r.status,now_utc-interval '18 days',now_utc,
      CASE WHEN r.status='CLOSED' THEN now_utc-interval '2 days' END) RETURNING project_id INTO pid;
   INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','PROJECT',r.k,pid,now_utc);
   INSERT INTO teammate_project_memberships(project_id,member_user_id,role,creator_project_id,joined_at)
    VALUES(pid,pg_temp.uid(r.creator),'CREATOR',pid,now_utc-interval '18 days');
   INSERT INTO teammate_project_audits(project_id,actor_user_id,event_type,occurred_at)
    VALUES(pid,pg_temp.uid(r.creator),'CREATED',now_utc-interval '18 days');
 END LOOP;
 -- Project skills.
 INSERT INTO teammate_project_skills SELECT pg_temp.eid('PROJECT','campus-services'),s.skill_id,x.required FROM
  (VALUES('java',true),('spring boot',true),('postgresql',true),('docker',false),('git',false)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 INSERT INTO teammate_project_skills SELECT pg_temp.eid('PROJECT','navigation'),s.skill_id,x.required FROM
  (VALUES('flutter',true),('dart',true),('firebase',false),('git',false)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 INSERT INTO teammate_project_skills SELECT pg_temp.eid('PROJECT','energy'),s.skill_id,x.required FROM
  (VALUES('c',true),('embedded systems',true),('iot',false),('circuit design',false)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 INSERT INTO teammate_project_skills SELECT pg_temp.eid('PROJECT','sustainability'),s.skill_id,x.required FROM
  (VALUES('data analysis',true),('project management',true),('autocad',false)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 INSERT INTO teammate_project_skills SELECT pg_temp.eid('PROJECT','full-algorithms'),s.skill_id,x.required FROM
  (VALUES('algorithms',true),('data structures',true)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 INSERT INTO teammate_project_skills SELECT pg_temp.eid('PROJECT','closed-archive'),s.skill_id,x.required FROM
  (VALUES('cybersecurity',true),('java',false)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 -- Existing members/full state.
 INSERT INTO teammate_project_memberships(project_id,member_user_id,role,joined_at) VALUES
  (pg_temp.eid('PROJECT','navigation'),pg_temp.uid('tahmid_hassan'),'TEAMMATE',now_utc-interval '10 days'),
  (pg_temp.eid('PROJECT','energy'),pg_temp.uid('imran_siddique'),'TEAMMATE',now_utc-interval '9 days'),
  (pg_temp.eid('PROJECT','full-algorithms'),pg_temp.uid('fatima_zahra'),'TEAMMATE',now_utc-interval '8 days');
 -- Applications: pending, accepted, rejected; cancellation is represented only for deleted projects by the current schema.
 FOR r IN SELECT * FROM (VALUES
  ('campus-pending','campus-services','sumaiya_noor','PENDING'),
  ('navigation-accepted','navigation','tahmid_hassan','ACCEPTED'),
  ('navigation-pending','navigation','zubair_ahmed','PENDING'),
  ('energy-rejected','energy','rayhan_kabir','REJECTED'),
  ('sustainability-pending','sustainability','jannat_ferdous','PENDING')) x(k,project_key,applicant,status) LOOP
   INSERT INTO teammate_project_applications(project_id,applicant_user_id,message,status,applied_at,responded_at)
    VALUES(pg_temp.eid('PROJECT',r.project_key),pg_temp.uid(r.applicant),'I would like to contribute my presentation profile skills.',r.status,
      now_utc-interval '6 days',CASE WHEN r.status<>'PENDING' THEN now_utc-interval '4 days' END) RETURNING application_id INTO appid;
   INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','PROJECT_APPLICATION',r.k,appid,now_utc);
   INSERT INTO teammate_project_audits(project_id,actor_user_id,application_id,event_type,occurred_at)
    VALUES(pg_temp.eid('PROJECT',r.project_key),pg_temp.uid(r.applicant),appid,'APPLICATION_SUBMITTED',now_utc-interval '6 days');
   IF r.status='ACCEPTED' THEN
    INSERT INTO teammate_project_audits(project_id,actor_user_id,application_id,event_type,occurred_at)
    VALUES(pg_temp.eid('PROJECT',r.project_key),(SELECT creator_user_id FROM teammate_projects WHERE project_id=pg_temp.eid('PROJECT',r.project_key)),appid,'APPLICATION_ACCEPTED',now_utc-interval '4 days');
   ELSIF r.status='REJECTED' THEN
    INSERT INTO teammate_project_audits(project_id,actor_user_id,application_id,event_type,occurred_at)
    VALUES(pg_temp.eid('PROJECT',r.project_key),(SELECT creator_user_id FROM teammate_projects WHERE project_id=pg_temp.eid('PROJECT',r.project_key)),appid,'APPLICATION_REJECTED',now_utc-interval '4 days');
   END IF;
 END LOOP;
END
$projects$;

-- Career board: active, naturally expired and manually closed posts with saved examples.
DO $careers$
DECLARE r record; jid bigint; now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC'; base date := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Dhaka')::date;
BEGIN
 FOR r IN SELECT * FROM (VALUES
  ('backend-intern','ahmed_faisal','Backend Engineering Intern','Northstar Systems','INTERNSHIP','HYBRID',base+30,'PUBLISHED'),
  ('product-intern','sabrina_haque','Associate Product Intern','Crescent Product Studio','INTERNSHIP','ONSITE',base+24,'PUBLISHED'),
  ('data-role','khadija_noor','Junior Data Analyst','Atlas Analytics','FULL_TIME','REMOTE',base+35,'PUBLISHED'),
  ('expired-mobile','mohammad_rafiq','Flutter Internship — Previous Intake','Riverstone Mobile','INTERNSHIP','REMOTE',base-3,'PUBLISHED'),
  ('closed-graduate','anika_rahman','Graduate Software Engineer','BrightPath Talent','FULL_TIME','HYBRID',base+10,'CLOSED')) x(k,author,title,company,employment,mode,deadline,status) LOOP
   INSERT INTO career_job_posts(author_user_id,title,company_name,description,qualifications,location,employment_type,work_mode,salary_range,
    application_url,application_email,application_deadline,status,posted_at,updated_at,closed_at)
   VALUES(pg_temp.uid(r.author),r.title,r.company,'Fictional presentation opportunity; no real vacancy or employer contact.',
    'Relevant fundamentals, thoughtful communication, and willingness to learn.','Dhaka, Bangladesh',r.employment,r.mode,'Illustrative only',
    'https://careers.example.test/'||r.k,NULL,r.deadline,r.status,now_utc-interval '12 days',now_utc,
    CASE WHEN r.status='CLOSED' THEN now_utc-interval '2 days' END) RETURNING job_post_id INTO jid;
   INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','CAREER_POST',r.k,jid,now_utc);
 END LOOP;
 INSERT INTO career_job_skills SELECT pg_temp.eid('CAREER_POST','backend-intern'),s.skill_id,x.required FROM
  (VALUES('java',true),('spring boot',true),('postgresql',false),('git',false)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 INSERT INTO career_job_skills SELECT pg_temp.eid('CAREER_POST','product-intern'),s.skill_id,x.required FROM
  (VALUES('product management',true),('communication',true),('excel',false)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 INSERT INTO career_job_skills SELECT pg_temp.eid('CAREER_POST','data-role'),s.skill_id,x.required FROM
  (VALUES('python',true),('sql',true),('data analysis',true)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 INSERT INTO career_job_skills SELECT pg_temp.eid('CAREER_POST','expired-mobile'),s.skill_id,x.required FROM
  (VALUES('flutter',true),('dart',true)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 INSERT INTO career_job_skills SELECT pg_temp.eid('CAREER_POST','closed-graduate'),s.skill_id,x.required FROM
  (VALUES('java',true),('git',false)) x(name,required) JOIN skills s ON lower(s.name)=x.name;
 INSERT INTO career_saved_jobs(student_user_id,job_post_id,note,saved_at) VALUES
  (pg_temp.uid('arif_hossain'),pg_temp.eid('CAREER_POST','product-intern'),'Discuss this role during the presentation.',now_utc-interval '2 days'),
  (pg_temp.uid('sumaiya_noor'),pg_temp.eid('CAREER_POST','data-role'),'Good match for the data portfolio.',now_utc-interval '1 day'),
  (pg_temp.uid('rayhan_kabir'),pg_temp.eid('CAREER_POST','closed-graduate'),'Saved before the fictional intake closed.',now_utc-interval '5 days');
END
$careers$;

-- Mentorship: only fourth-year students and alumni host fixtures.
DO $mentorship$
DECLARE r record; mpid bigint; sid bigint; eid bigint; now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC'; base date := (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Dhaka')::date;
BEGIN
 FOR r IN SELECT * FROM (VALUES
  ('nusrat','nusrat_jahan','AVAILABLE','Database transactions and API design for student teams.'),
  ('mahmud','mahmud_hasan','AVAILABLE','Flutter architecture, testing and accessible mobile UX.'),
  ('omar','omar_faruk','AVAILABLE','Embedded systems, sensors and practical IoT prototyping.'),
  ('ahmed','ahmed_faisal','AVAILABLE','Backend engineering and production service design.'),
  ('khadija','khadija_noor','AVAILABLE','Applied data analysis and responsible machine learning.'),
  ('rafiq','mohammad_rafiq','UNAVAILABLE','Mobile engineering mentorship between project cycles.')) x(k,user_key,status,bio) LOOP
   IF (SELECT role FROM desired_accounts WHERE logical_key=r.user_key)='STUDENT' AND
      (SELECT academic_year FROM desired_accounts WHERE logical_key=r.user_key)<>4 THEN
     RAISE EXCEPTION 'Student mentor % is not fourth-year',r.user_key;
   END IF;
   INSERT INTO mentor_profiles(user_id,mentoring_bio,status,registered_at,updated_at)
    VALUES(pg_temp.uid(r.user_key),r.bio,r.status,now_utc-interval '30 days',now_utc) RETURNING mentor_profile_id INTO mpid;
   INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','MENTOR_PROFILE',r.k,mpid,now_utc);
 END LOOP;
 INSERT INTO mentor_expertise(mentor_profile_id,skill_id,description)
 SELECT pg_temp.eid('MENTOR_PROFILE','nusrat'),skill_id,'Transactions and reliable API fundamentals.' FROM skills WHERE lower(name) IN ('java','postgresql');
 INSERT INTO mentor_expertise(mentor_profile_id,skill_id,description)
 SELECT pg_temp.eid('MENTOR_PROFILE','mahmud'),skill_id,'Mobile architecture and testable widgets.' FROM skills WHERE lower(name) IN ('flutter','dart');
 INSERT INTO mentor_expertise(mentor_profile_id,skill_id,description)
 SELECT pg_temp.eid('MENTOR_PROFILE','omar'),skill_id,'Embedded prototyping and safe circuit practice.' FROM skills WHERE lower(name) IN ('embedded systems','circuit design');
 INSERT INTO mentor_expertise(mentor_profile_id,skill_id,description)
 SELECT pg_temp.eid('MENTOR_PROFILE','ahmed'),skill_id,'Backend systems from design to deployment.' FROM skills WHERE lower(name) IN ('spring boot','docker');
 INSERT INTO mentor_expertise(mentor_profile_id,skill_id,description)
 SELECT pg_temp.eid('MENTOR_PROFILE','khadija'),skill_id,'Practical data preparation and model evaluation.' FROM skills WHERE lower(name) IN ('python','machine learning');
 FOR r IN SELECT * FROM (VALUES
  ('backend-series','ahmed','Backend Design Clinic','WEEKLY',base+5,time '15:00',time '16:00','ONLINE',4,2,'OPEN',true,3),
  ('flutter-full','mahmud','Flutter Testing Workshop','ONE_TIME',base+7,time '10:00',time '11:30','ONLINE',2,2,'OPEN',true,1),
  ('embedded-open','omar','Embedded Sensor Lab','ONE_TIME',base+9,time '14:00',time '16:00','IN_PERSON',5,1,'OPEN',true,1),
  ('data-closed','khadija','Responsible ML Review','WEEKLY',base+12,time '18:00',time '19:00','ONLINE',4,1,'CLOSED',false,2),
  ('cancelled-api','nusrat','Cancelled API Study Group','ONE_TIME',base+6,time '09:00',time '10:00','ONLINE',4,0,'CANCELLED',false,1),
  ('completed-sql','nusrat','SQL Fundamentals Clinic','ONE_TIME',base-7,time '09:00',time '10:00','IN_PERSON',3,0,'OPEN',true,1))
  x(k,mentor_key,topic,schedule,start_date,start_time,end_time,mode,capacity,current_count,status,enrollment_open,meeting_count) LOOP
   INSERT INTO mentorship_slots(mentor_profile_id,topic,description,schedule_type,start_date,start_time,end_time,mode,location,meeting_link,
    capacity,current_mentee_count,status,created_at,updated_at,meeting_count,enrollment_open)
   VALUES(pg_temp.eid('MENTOR_PROFILE',r.mentor_key),r.topic,'Fictional presentation mentorship with consistent occurrence data.',r.schedule,
    r.start_date,r.start_time,r.end_time,r.mode,CASE WHEN r.mode='IN_PERSON' THEN 'IUT Presentation Lab' END,
    CASE WHEN r.mode='ONLINE' THEN 'https://meet.example.test/'||r.k END,r.capacity,r.current_count,r.status,now_utc-interval '20 days',now_utc,r.meeting_count,r.enrollment_open)
   RETURNING slot_id INTO sid;
   INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','MENTORSHIP_SLOT',r.k,sid,now_utc);
   FOR eid IN 0..r.meeting_count-1 LOOP
    INSERT INTO mentorship_occurrences(slot_id,starts_at,ends_at,cancelled_at)
    VALUES(sid,(r.start_date+(CASE WHEN r.schedule='WEEKLY' THEN eid*7 ELSE 0 END)) + r.start_time,
      (r.start_date+(CASE WHEN r.schedule='WEEKLY' THEN eid*7 ELSE 0 END)) + r.end_time,
      CASE WHEN r.status='CANCELLED' THEN now_utc-interval '1 day' END);
   END LOOP;
 END LOOP;
 INSERT INTO mentorship_enrollments(slot_id,mentee_id,join_message,learning_goal,status,joined_at,left_at,active_marker) VALUES
  (pg_temp.eid('MENTORSHIP_SLOT','backend-series'),pg_temp.uid('tasnim_ahmed'),'I want to improve transaction design.','Build a reliable service layer.','ACTIVE',now_utc-interval '5 days',NULL,TRUE),
  (pg_temp.eid('MENTORSHIP_SLOT','flutter-full'),pg_temp.uid('zubair_ahmed'),'I want stronger widget tests.','Test loading and error states.','ACTIVE',now_utc-interval '4 days',NULL,TRUE),
  (pg_temp.eid('MENTORSHIP_SLOT','flutter-full'),pg_temp.uid('tahmid_hassan'),'I want to test navigation flows.','Write stable navigation tests.','ACTIVE',now_utc-interval '4 days',NULL,TRUE),
  (pg_temp.eid('MENTORSHIP_SLOT','embedded-open'),pg_temp.uid('ibrahim_khalil'),'I want practical sensor guidance.','Prototype safely.','ACTIVE',now_utc-interval '3 days',NULL,TRUE),
  (pg_temp.eid('MENTORSHIP_SLOT','data-closed'),pg_temp.uid('sumaiya_noor'),'I want model review feedback.','Evaluate bias and validation.','ACTIVE',now_utc-interval '6 days',NULL,TRUE),
  (pg_temp.eid('MENTORSHIP_SLOT','backend-series'),pg_temp.uid('tariq_mahmood'),'I joined before a schedule conflict.','Understand service boundaries.','LEFT',now_utc-interval '9 days',now_utc-interval '7 days',NULL),
  (pg_temp.eid('MENTORSHIP_SLOT','backend-series'),pg_temp.uid('tariq_mahmood'),'My schedule is clear now.','Continue the backend learning plan.','ACTIVE',now_utc-interval '2 days',NULL,TRUE),
  (pg_temp.eid('MENTORSHIP_SLOT','completed-sql'),pg_temp.uid('mariam_akter'),'I want stronger SQL foundations.','Practice joins and constraints.','COMPLETED',now_utc-interval '14 days',now_utc-interval '7 days',NULL);
END
$mentorship$;

-- Reports stay entirely within synthetic accounts/content. Named administrators remain active.
DO $reports$
DECLARE rid bigint; now_utc timestamp := CURRENT_TIMESTAMP AT TIME ZONE 'UTC'; target bigint;
BEGIN
 target:=pg_temp.eid('PROJECT','campus-services');
 INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,target_owner_user_id,
  submitted_at,open_reporter_id,open_target_type,open_target_id)
 VALUES(pg_temp.uid('nabila_sultana'),'PROJECT',target,'Presentation report for reviewing a fictional project description.','SUBMITTED',
  'Campus Services API',jsonb_build_object('id',target,'title','Campus Services API','fixture',true)::text,
  pg_temp.uid('farhan_rahman'),now_utc-interval '2 days',pg_temp.uid('nabila_sultana'),'PROJECT',target) RETURNING report_id INTO rid;
 INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','REPORT','project-submitted',rid,now_utc);
 INSERT INTO report_audit_logs(report_id,actor_id,event_type,previous_status,new_status,occurred_at)
 VALUES(rid,pg_temp.uid('nabila_sultana'),'SUBMITTED',NULL,'SUBMITTED',now_utc-interval '2 days');
 target:=pg_temp.eid('CAREER_POST','closed-graduate');
 INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,target_owner_user_id,reviewer_id,
  submitted_at,review_started_at,open_reporter_id,open_target_type,open_target_id,internal_notes)
 VALUES(pg_temp.uid('nabila_sultana'),'CAREER_POST',target,'Presentation review of a safely fictional closed opportunity.','UNDER_REVIEW',
  'Graduate Software Engineer',jsonb_build_object('id',target,'title','Graduate Software Engineer','fixture',true)::text,
  pg_temp.uid('anika_rahman'),pg_temp.uid('admin_sayma'),now_utc-interval '3 days',now_utc-interval '1 day',
  pg_temp.uid('nabila_sultana'),'CAREER_POST',target,'Reviewing presentation-only content.') RETURNING report_id INTO rid;
 INSERT INTO uniconnect_presentation_seed_keys VALUES('presentation-2026-v1','REPORT','career-review',rid,now_utc);
 INSERT INTO report_audit_logs(report_id,actor_id,event_type,previous_status,new_status,occurred_at) VALUES
  (rid,pg_temp.uid('nabila_sultana'),'SUBMITTED',NULL,'SUBMITTED',now_utc-interval '3 days'),
  (rid,pg_temp.uid('admin_sayma'),'UNDER_REVIEW','SUBMITTED','UNDER_REVIEW',now_utc-interval '1 day');
END
$reports$;

-- Action-linked notifications, preserving unread/read examples.
INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at,read_at)
SELECT pg_temp.uid('mariam_akter'),'CONNECTION_REQUESTED','Connection request sent','Your presentation connection request is awaiting review.','CONNECTION',pg_temp.eid('CONNECTION','mariam-farhan'),'presentation:connection:mariam-farhan',(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')-interval '3 days',NULL::timestamp
UNION ALL SELECT pg_temp.uid('farhan_rahman'),'CONNECTION_REQUESTED','New connection request','Mariam sent a presentation connection request.','CONNECTION',pg_temp.eid('CONNECTION','mariam-farhan'),'presentation:connection:mariam-farhan:receiver',(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')-interval '3 days',NULL::timestamp
UNION ALL SELECT pg_temp.uid('abdullah_mamun'),'CONNECTION_ACCEPTED','Connection accepted','Farhan is now connected with you.','CONNECTION',pg_temp.eid('CONNECTION','farhan-abdullah'),'presentation:connection:farhan-abdullah:accepted',(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')-interval '19 days',(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')-interval '18 days'
UNION ALL SELECT pg_temp.uid('zubair_ahmed'),'CLUB_ROLE_GRANTED','Club representative access','Innovation Society representative access is active.','CLUB',pg_temp.eid('CLUB','innovation'),'presentation:club:innovation:zubair',(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')-interval '25 days',(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')-interval '24 days'
UNION ALL SELECT pg_temp.uid('tahmid_hassan'),'PROJECT_APPLICATION_ACCEPTED','Project application accepted','You joined the Accessible Campus Navigator team.','PROJECT',pg_temp.eid('PROJECT','navigation'),'presentation:project:navigation:tahmid',(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')-interval '4 days',NULL::timestamp
UNION ALL SELECT pg_temp.uid('ahmed_faisal'),'MENTORSHIP_SLOT_JOINED','New mentee enrolled','A mentee joined Backend Design Clinic.','MENTORSHIP_SLOT',pg_temp.eid('MENTORSHIP_SLOT','backend-series'),'presentation:mentorship:backend:mentor',(CURRENT_TIMESTAMP AT TIME ZONE 'UTC')-interval '5 days',NULL::timestamp;

DO $semantic_checks$
BEGIN
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys WHERE dataset_key='presentation-2026-v1' AND entity_type='USER')<>36 THEN
  RAISE EXCEPTION 'Expected 36 mapped presentation accounts'; END IF;
 IF EXISTS(SELECT 1 FROM desired_accounts d JOIN users u ON lower(u.email)=d.email WHERE u.account_status<>'ACTIVE' OR u.anonymized_at IS NOT NULL) THEN
  RAISE EXCEPTION 'Presentation account eligibility mismatch'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN mentor_profiles mp ON mp.mentor_profile_id=k.entity_id
   JOIN personal_profiles p ON p.user_id=mp.user_id WHERE k.dataset_key='presentation-2026-v1'
   AND k.entity_type='MENTOR_PROFILE' AND p.profile_type='STUDENT' AND p.year_of_study<>4) THEN
  RAISE EXCEPTION 'A seeded student mentor is not fourth-year'; END IF;
 IF EXISTS(SELECT 1 FROM teammate_project_applications a JOIN teammate_project_memberships m
   ON m.project_id=a.project_id AND m.member_user_id=a.applicant_user_id WHERE a.status='PENDING') THEN
  RAISE EXCEPTION 'Pending project applicant is already an active member'; END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN mentorship_slots s ON s.slot_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='MENTORSHIP_SLOT'
   AND s.current_mentee_count<>(SELECT count(*) FROM mentorship_enrollments e WHERE e.slot_id=s.slot_id AND e.status='ACTIVE')) THEN
  RAISE EXCEPTION 'Mentorship active counts are inconsistent'; END IF;
 IF EXISTS(SELECT 1 FROM users WHERE lower(email) IN ('ayman@iut-dhaka.edu','sayma@iut-dhaka.edu') AND
   (platform_role<>'SYSTEM_ADMIN' OR account_status<>'ACTIVE' OR anonymized_at IS NOT NULL)) THEN
  RAISE EXCEPTION 'Named administrator state is incorrect'; END IF;
END
$semantic_checks$;

\ir upgrade-v3-reports.sql
\ir repair-v4-report-history.sql

COMMIT;
\echo 'Presentation dataset applied atomically.'
SELECT dataset_key,seed_version,seeded_at,base_date,date_window_end,account_count
FROM uniconnect_presentation_seed_manifest WHERE dataset_key='presentation-2026-v1';
