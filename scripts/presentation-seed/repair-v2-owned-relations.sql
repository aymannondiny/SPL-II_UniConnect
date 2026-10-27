-- V1 was applied while missing vocabulary rows were absent, so joins that attach
-- project/career/mentor terms could not create those relationships. Restrict all
-- repairs to entities resolved through the durable presentation ownership map.
DO $repair_guard$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM uniconnect_presentation_seed_manifest
   WHERE dataset_key='presentation-2026-v1' AND seed_version=2) THEN
  RAISE EXCEPTION 'The v2 presentation manifest is required for owned-relation repair';
 END IF;
END
$repair_guard$;

CREATE TEMP TABLE desired_project_skills(logical_key text, skill_name text, required boolean,
 PRIMARY KEY(logical_key,skill_name));
INSERT INTO desired_project_skills VALUES
('campus-services','java',true),('campus-services','spring boot',true),('campus-services','postgresql',true),('campus-services','docker',false),('campus-services','git',false),
('navigation','flutter',true),('navigation','dart',true),('navigation','firebase',false),('navigation','git',false),
('energy','c',true),('energy','embedded systems',true),('energy','iot',false),('energy','circuit design',false),
('sustainability','data analysis',true),('sustainability','project management',true),('sustainability','autocad',false),
('full-algorithms','algorithms',true),('full-algorithms','data structures',true),
('closed-archive','cybersecurity',true),('closed-archive','java',false);
INSERT INTO teammate_project_skills(project_id,skill_id,required)
SELECT k.entity_id,s.skill_id,d.required FROM desired_project_skills d
JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1' AND k.entity_type='PROJECT' AND k.logical_key=d.logical_key
JOIN skills s ON lower(s.name)=d.skill_name
WHERE NOT EXISTS(SELECT 1 FROM teammate_project_skills ps WHERE ps.project_id=k.entity_id AND ps.skill_id=s.skill_id);

CREATE TEMP TABLE desired_career_skills(logical_key text, skill_name text, required boolean,
 PRIMARY KEY(logical_key,skill_name));
INSERT INTO desired_career_skills VALUES
('backend-intern','java',true),('backend-intern','spring boot',true),('backend-intern','postgresql',false),('backend-intern','git',false),
('product-intern','product management',true),('product-intern','communication',true),('product-intern','excel',false),
('data-role','python',true),('data-role','sql',true),('data-role','data analysis',true),
('expired-mobile','flutter',true),('expired-mobile','dart',true),
('closed-graduate','java',true),('closed-graduate','git',false);
INSERT INTO career_job_skills(job_post_id,skill_id,required)
SELECT k.entity_id,s.skill_id,d.required FROM desired_career_skills d
JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1' AND k.entity_type='CAREER_POST' AND k.logical_key=d.logical_key
JOIN skills s ON lower(s.name)=d.skill_name
WHERE NOT EXISTS(SELECT 1 FROM career_job_skills cs WHERE cs.job_post_id=k.entity_id AND cs.skill_id=s.skill_id);

CREATE TEMP TABLE desired_mentor_expertise(logical_key text,skill_name text,description text,
 PRIMARY KEY(logical_key,skill_name));
INSERT INTO desired_mentor_expertise VALUES
('nusrat','java','Transactions and reliable API fundamentals.'),('nusrat','postgresql','Transactions and reliable API fundamentals.'),
('mahmud','flutter','Mobile architecture and testable widgets.'),('mahmud','dart','Mobile architecture and testable widgets.'),
('omar','embedded systems','Embedded prototyping and safe circuit practice.'),('omar','circuit design','Embedded prototyping and safe circuit practice.'),
('ahmed','spring boot','Backend systems from design to deployment.'),('ahmed','docker','Backend systems from design to deployment.'),
('khadija','python','Practical data preparation and model evaluation.'),('khadija','machine learning','Practical data preparation and model evaluation.');
INSERT INTO mentor_expertise(mentor_profile_id,skill_id,description)
SELECT k.entity_id,s.skill_id,d.description FROM desired_mentor_expertise d
JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1' AND k.entity_type='MENTOR_PROFILE' AND k.logical_key=d.logical_key
JOIN skills s ON lower(s.name)=d.skill_name
WHERE NOT EXISTS(SELECT 1 FROM mentor_expertise me WHERE me.mentor_profile_id=k.entity_id AND me.skill_id=s.skill_id);

DO $repair_verify$
DECLARE missing_count integer;
BEGIN
 SELECT count(*) INTO missing_count FROM desired_project_skills d
 JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1' AND k.entity_type='PROJECT' AND k.logical_key=d.logical_key
 WHERE NOT EXISTS(SELECT 1 FROM teammate_project_skills ps JOIN skills s USING(skill_id)
  WHERE ps.project_id=k.entity_id AND lower(s.name)=d.skill_name AND ps.required=d.required);
 IF missing_count<>0 THEN RAISE EXCEPTION 'V2 repair left % project skill relationships missing',missing_count; END IF;
 SELECT count(*) INTO missing_count FROM desired_career_skills d
 JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1' AND k.entity_type='CAREER_POST' AND k.logical_key=d.logical_key
 WHERE NOT EXISTS(SELECT 1 FROM career_job_skills cs JOIN skills s USING(skill_id)
  WHERE cs.job_post_id=k.entity_id AND lower(s.name)=d.skill_name AND cs.required=d.required);
 IF missing_count<>0 THEN RAISE EXCEPTION 'V2 repair left % career skill relationships missing',missing_count; END IF;
 SELECT count(*) INTO missing_count FROM desired_mentor_expertise d
 JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1' AND k.entity_type='MENTOR_PROFILE' AND k.logical_key=d.logical_key
 WHERE NOT EXISTS(SELECT 1 FROM mentor_expertise me JOIN skills s USING(skill_id)
  WHERE me.mentor_profile_id=k.entity_id AND lower(s.name)=d.skill_name);
 IF missing_count<>0 THEN RAISE EXCEPTION 'V2 repair left % mentor expertise relationships missing',missing_count; END IF;
END
$repair_verify$;
UPDATE uniconnect_presentation_seed_manifest SET seed_version=3
WHERE dataset_key='presentation-2026-v1' AND seed_version=2;
