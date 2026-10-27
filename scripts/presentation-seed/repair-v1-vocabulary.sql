-- Bounded recovery for the initial additive v1 application. The ambiguous
-- vocabulary alias affected only missing skill/interest creation. This repair
-- only adds associations to profiles owned by this dataset's durable key map.
DO $repair_guard$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM uniconnect_presentation_seed_manifest
   WHERE dataset_key='presentation-2026-v1' AND seed_version=1) THEN
  RAISE EXCEPTION 'The v1 presentation manifest is required for this repair';
 END IF;
 IF (SELECT count(*) FROM uniconnect_presentation_seed_keys
   WHERE dataset_key='presentation-2026-v1' AND entity_type='PROFILE')<>34 THEN
  RAISE EXCEPTION 'Refusing repair because the v1 profile ownership map is incomplete';
 END IF;
END
$repair_guard$;

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

CREATE TEMP TABLE desired_profile_terms(logical_key text PRIMARY KEY, skills text[] NOT NULL, interests text[] NOT NULL);
INSERT INTO desired_profile_terms VALUES
('farhan_rahman',ARRAY['java','spring boot','postgresql','sql','git','docker'],ARRAY['distributed systems','open source','campus technology']),
('nusrat_jahan',ARRAY['java','sql','postgresql','algorithms'],ARRAY['mentoring','distributed systems','competitive programming']),
('abdullah_mamun',ARRAY['java','spring boot','postgresql','sql','docker'],ARRAY['distributed systems','open source']),
('tasnim_ahmed',ARRAY['java','sql','git'],ARRAY['distributed systems','campus technology']),
('mahmud_hasan',ARRAY['flutter','dart','firebase','git'],ARRAY['mobile development','accessibility','mentoring']),
('aisha_siddika',ARRAY['python','data analysis','machine learning','sql'],ARRAY['artificial intelligence','data science']),
('omar_faruk',ARRAY['c','embedded systems','iot','circuit design'],ARRAY['robotics','renewable energy','mentoring']),
('mariam_akter',ARRAY['javascript','react','html','css'],ARRAY['web development','campus technology']),
('yusuf_islam',ARRAY['algorithms','data structures','c++','git'],ARRAY['competitive programming','mentoring']),
('sumaiya_noor',ARRAY['python','machine learning','data analysis','sql'],ARRAY['artificial intelligence','data science']),
('ibrahim_khalil',ARRAY['c','embedded systems','iot','circuit design'],ARRAY['robotics','renewable energy']),
('fatima_zahra',ARRAY['java','cybersecurity','sql'],ARRAY['information security','open source']),
('rayhan_kabir',ARRAY['javascript','react','java','git'],ARRAY['web development','open source']),
('sadia_afrin',ARRAY['project management','excel','communication'],ARRAY['entrepreneurship','university activities']),
('zubair_ahmed',ARRAY['flutter','dart','git'],ARRAY['mobile development','university activities']),
('nabila_sultana',ARRAY['python','communication','sql'],ARRAY['community service','campus technology']),
('hamza_chowdhury',ARRAY['autocad','project management'],ARRAY['sustainable infrastructure']),
('rukaiya_islam',ARRAY['html','css','git'],ARRAY['web development','design']),
('tahmid_hassan',ARRAY['flutter','dart','firebase','algorithms'],ARRAY['mobile development','campus technology']),
('samira_khan',ARRAY['python','data analysis','sql','machine learning'],ARRAY['data science','campus technology']),
('arif_hossain',ARRAY['excel','project management','communication'],ARRAY['entrepreneurship','product management']),
('lamia_rahman',ARRAY['autocad','data analysis','project management'],ARRAY['sustainable infrastructure','renewable energy']),
('adnan_karim',ARRAY['solidworks','c','project management'],ARRAY['robotics','manufacturing']),
('jannat_ferdous',ARRAY['excel','data analysis','project management'],ARRAY['manufacturing','data science']),
('imran_siddique',ARRAY['c','embedded systems','iot','circuit design'],ARRAY['renewable energy','robotics']),
('hafsa_mahjabin',ARRAY['communication','project management','javascript'],ARRAY['university activities','community service']),
('ahmed_faisal',ARRAY['java','spring boot','postgresql','docker'],ARRAY['distributed systems','mentoring']),
('sabrina_haque',ARRAY['product management','project management','communication'],ARRAY['entrepreneurship','mentoring']),
('mohammad_rafiq',ARRAY['flutter','dart','firebase','git'],ARRAY['mobile development','mentoring']),
('khadija_noor',ARRAY['python','machine learning','data analysis','sql'],ARRAY['artificial intelligence','mentoring']),
('saif_uddin',ARRAY['c','embedded systems','iot','circuit design'],ARRAY['robotics','manufacturing']),
('meherun_nesa',ARRAY['javascript','react','html','css'],ARRAY['web development','accessibility']),
('tariq_mahmood',ARRAY['solidworks','project management'],ARRAY['manufacturing','mentoring']),
('anika_rahman',ARRAY['java','communication','project management'],ARRAY['career development','mentoring']);

INSERT INTO profile_skills(profile_id,skill_id)
SELECT k.entity_id,s.skill_id FROM desired_profile_terms d
JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1'
 AND k.entity_type='PROFILE' AND k.logical_key=d.logical_key
CROSS JOIN LATERAL unnest(d.skills) desired(name)
JOIN skills s ON lower(s.name)=desired.name
WHERE NOT EXISTS(SELECT 1 FROM profile_skills ps WHERE ps.profile_id=k.entity_id AND ps.skill_id=s.skill_id);
INSERT INTO profile_interests(profile_id,interest_id)
SELECT k.entity_id,i.interest_id FROM desired_profile_terms d
JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1'
 AND k.entity_type='PROFILE' AND k.logical_key=d.logical_key
CROSS JOIN LATERAL unnest(d.interests) desired(name)
JOIN interests i ON lower(i.name)=desired.name
WHERE NOT EXISTS(SELECT 1 FROM profile_interests pi WHERE pi.profile_id=k.entity_id AND pi.interest_id=i.interest_id);

DO $repair_verify$
DECLARE missing_terms integer;
BEGIN
 SELECT count(*) INTO missing_terms FROM desired_profile_terms d
 JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1'
  AND k.entity_type='PROFILE' AND k.logical_key=d.logical_key
 CROSS JOIN LATERAL unnest(d.skills) desired(name)
 WHERE NOT EXISTS(SELECT 1 FROM profile_skills ps JOIN skills s USING(skill_id)
   WHERE ps.profile_id=k.entity_id AND lower(s.name)=desired.name);
 IF missing_terms<>0 THEN RAISE EXCEPTION 'V1 repair left % profile skill associations missing',missing_terms; END IF;
 SELECT count(*) INTO missing_terms FROM desired_profile_terms d
 JOIN uniconnect_presentation_seed_keys k ON k.dataset_key='presentation-2026-v1'
  AND k.entity_type='PROFILE' AND k.logical_key=d.logical_key
 CROSS JOIN LATERAL unnest(d.interests) desired(name)
 WHERE NOT EXISTS(SELECT 1 FROM profile_interests pi JOIN interests i USING(interest_id)
   WHERE pi.profile_id=k.entity_id AND lower(i.name)=desired.name);
 IF missing_terms<>0 THEN RAISE EXCEPTION 'V1 repair left % profile interest associations missing',missing_terms; END IF;
END
$repair_verify$;
UPDATE uniconnect_presentation_seed_manifest SET seed_version=2
WHERE dataset_key='presentation-2026-v1' AND seed_version=1;
