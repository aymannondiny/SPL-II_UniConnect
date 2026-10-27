\set QUIET 1
\pset pager off
\set QUIET 0
SET statement_timeout = '30s';
SET lock_timeout = '5s';

DO $guard$
BEGIN
  IF to_regclass('public.flyway_schema_history') IS NULL OR
     NOT EXISTS (SELECT 1 FROM flyway_schema_history WHERE version='27' AND success) OR
     EXISTS (SELECT 1 FROM flyway_schema_history WHERE NOT success) THEN
    RAISE EXCEPTION 'Target must have a successful Flyway history through V27.';
  END IF;
END
$guard$;

SELECT to_regclass('public.uniconnect_presentation_seed_manifest') IS NOT NULL AS has_manifest \gset
\if :has_manifest
 SELECT EXISTS(SELECT 1 FROM uniconnect_presentation_seed_manifest
   WHERE dataset_key='presentation-2026-v1' AND seed_version=3) AS report_upgrade,
   EXISTS(SELECT 1 FROM uniconnect_presentation_seed_manifest
   WHERE dataset_key='presentation-2026-v1' AND seed_version=4) AS report_history_repair,
   EXISTS(SELECT 1 FROM uniconnect_presentation_seed_manifest
   WHERE dataset_key='presentation-2026-v1' AND seed_version=5) AS current_revision \gset
 \if :report_upgrade
  SELECT current_database() AS target_database,
         inet_server_addr() AS target_address,
         (SELECT version FROM flyway_schema_history WHERE success AND version IS NOT NULL ORDER BY installed_rank DESC LIMIT 1) AS migration_version,
         3 AS current_seed_revision,
         5 AS planned_seed_revision;
  SELECT 8 AS planned_report_inserts,
         2 AS planned_removed_publication_targets,
         4 AS planned_resolution_notifications,
         0 AS planned_account_updates,
         0 AS planned_password_changes;
  SELECT target_type,status,count(*) AS existing_report_count
  FROM content_reports r JOIN uniconnect_presentation_seed_keys k
    ON k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT' AND k.entity_id=r.report_id
  GROUP BY target_type,status ORDER BY target_type,status;
  SELECT 'Only presentation-owned report fixtures, two dedicated moderation targets, their audits/evidence, resolution notifications, and the manifest revision will change.' AS preservation_policy;
  \quit
 \endif
 \if :report_history_repair
  SELECT current_database() AS target_database,
         inet_server_addr() AS target_address,
         4 AS current_seed_revision,
         5 AS planned_seed_revision;
  SELECT (SELECT count(*) FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
           WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
             AND r.status='UNDER_REVIEW' AND r.internal_notes IS NOT NULL) AS planned_owned_report_note_clears,
         (SELECT count(*) FROM uniconnect_presentation_seed_keys k JOIN report_audit_logs a ON a.report_id=k.entity_id
           WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
             AND a.event_type='UNDER_REVIEW' AND a.internal_note IS NOT NULL) AS planned_owned_review_audit_note_clears,
         0 AS planned_account_updates,
         0 AS planned_password_changes;
  SELECT 'Only presentation-owned notes that the actual UNDER_REVIEW transition cannot create will be cleared.' AS preservation_policy;
  \quit
 \endif
 \if :current_revision
  SELECT current_database() AS target_database,
         inet_server_addr() AS target_address,
         5 AS current_seed_revision,
         'NO_CHANGES' AS planned_action;
  \quit
 \endif
\endif

CREATE TEMP TABLE desired_accounts(email text PRIMARY KEY, full_name text, role text);
INSERT INTO desired_accounts VALUES
('ayman@iut-dhaka.edu','Ayman','SYSTEM_ADMIN'),
('sayma@iut-dhaka.edu','Sayma','SYSTEM_ADMIN'),
('pres.farhan.rahman@iut-dhaka.edu','Farhan Rahman','STUDENT'),
('pres.nusrat.jahan@iut-dhaka.edu','Nusrat Jahan','STUDENT'),
('pres.abdullah.mamun@iut-dhaka.edu','Abdullah Al Mamun','STUDENT'),
('pres.tasnim.ahmed@iut-dhaka.edu','Tasnim Ahmed','STUDENT'),
('pres.mahmud.hasan@iut-dhaka.edu','Mahmud Hasan','STUDENT'),
('pres.aisha.siddika@iut-dhaka.edu','Aisha Siddika','STUDENT'),
('pres.omar.faruk@iut-dhaka.edu','Omar Faruk','STUDENT'),
('pres.mariam.akter@iut-dhaka.edu','Mariam Akter','STUDENT'),
('pres.yusuf.islam@iut-dhaka.edu','Yusuf Islam','STUDENT'),
('pres.sumaiya.noor@iut-dhaka.edu','Sumaiya Noor','STUDENT'),
('pres.ibrahim.khalil@iut-dhaka.edu','Ibrahim Khalil','STUDENT'),
('pres.fatima.zahra@iut-dhaka.edu','Fatima Zahra','STUDENT'),
('pres.rayhan.kabir@iut-dhaka.edu','Rayhan Kabir','STUDENT'),
('pres.sadia.afrin@iut-dhaka.edu','Sadia Afrin','STUDENT'),
('pres.zubair.ahmed@iut-dhaka.edu','Zubair Ahmed','STUDENT'),
('pres.nabila.sultana@iut-dhaka.edu','Nabila Sultana','STUDENT'),
('pres.hamza.chowdhury@iut-dhaka.edu','Hamza Chowdhury','STUDENT'),
('pres.rukaiya.islam@iut-dhaka.edu','Rukaiya Islam','STUDENT'),
('pres.tahmid.hassan@iut-dhaka.edu','Tahmid Hassan','STUDENT'),
('pres.samira.khan@iut-dhaka.edu','Samira Khan','STUDENT'),
('pres.arif.hossain@iut-dhaka.edu','Arif Hossain','STUDENT'),
('pres.lamia.rahman@iut-dhaka.edu','Lamia Rahman','STUDENT'),
('pres.adnan.karim@iut-dhaka.edu','Adnan Karim','STUDENT'),
('pres.jannat.ferdous@iut-dhaka.edu','Jannat Ferdous','STUDENT'),
('pres.imran.siddique@iut-dhaka.edu','Imran Siddique','STUDENT'),
('pres.hafsa.mahjabin@iut-dhaka.edu','Hafsa Mahjabin','STUDENT'),
('pres.ahmed.faisal@iut-dhaka.edu','Ahmed Faisal','ALUMNI'),
('pres.sabrina.haque@iut-dhaka.edu','Sabrina Haque','ALUMNI'),
('pres.mohammad.rafiq@iut-dhaka.edu','Mohammad Rafiq','ALUMNI'),
('pres.khadija.noor@iut-dhaka.edu','Khadija Noor','ALUMNI'),
('pres.saif.uddin@iut-dhaka.edu','Saif Uddin','ALUMNI'),
('pres.meherun.nesa@iut-dhaka.edu','Meherun Nesa','ALUMNI'),
('pres.tariq.mahmood@iut-dhaka.edu','Tariq Mahmood','ALUMNI'),
('pres.anika.rahman@iut-dhaka.edu','Anika Rahman','ALUMNI');

SELECT current_database() AS target_database,
       inet_server_addr() AS target_address,
       (SELECT version FROM flyway_schema_history WHERE success AND version IS NOT NULL ORDER BY installed_rank DESC LIMIT 1) AS migration_version,
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='uniconnect_presentation_seed_manifest') AS manifest_table_exists;
SELECT count(*) AS desired_accounts,
       count(*) FILTER (WHERE u.user_id IS NULL) AS planned_account_inserts,
       count(*) FILTER (WHERE u.user_id IS NOT NULL) AS normalized_email_collisions,
       count(*) FILTER (WHERE u.user_id IS NOT NULL AND (u.password_hash IS DISTINCT FROM '<new bcrypt hash>' OR u.platform_role IS DISTINCT FROM d.role OR u.account_status IS DISTINCT FROM 'ACTIVE')) AS explicitly_authorized_account_updates
FROM desired_accounts d LEFT JOIN users u ON lower(u.email)=d.email;
SELECT d.email, u.user_id, u.full_name AS existing_name, u.platform_role AS existing_role,
       u.account_status AS existing_status, u.anonymized_at IS NOT NULL AS anonymized,
       CASE WHEN u.user_id IS NULL THEN 'INSERT'
            WHEN u.anonymized_at IS NOT NULL THEN 'BLOCKED_ANONYMIZED'
            WHEN d.email NOT IN ('ayman@iut-dhaka.edu','sayma@iut-dhaka.edu') AND u.full_name IS DISTINCT FROM d.full_name THEN 'BLOCKED_IDENTITY_CONFLICT'
            WHEN u.platform_role IS DISTINCT FROM d.role OR u.account_status IS DISTINCT FROM 'ACTIVE' THEN 'UPDATE_ROLE_OR_ELIGIBILITY_AND_REVOKE_SESSIONS'
            ELSE 'UPDATE_PASSWORD_AND_REVOKE_SESSIONS' END AS planned_action
FROM desired_accounts d LEFT JOIN users u ON lower(u.email)=d.email
WHERE u.user_id IS NOT NULL ORDER BY d.email;
SELECT 'presentation rows are additive; unrelated rows are never updated or deleted' AS preservation_policy;
