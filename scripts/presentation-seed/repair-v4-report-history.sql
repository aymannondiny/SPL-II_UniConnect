-- Align presentation review history with ReportReviewService: claiming a report
-- records ownership/time only. Internal notes are first accepted at resolution.
DO $guard$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM uniconnect_presentation_seed_manifest
   WHERE dataset_key='presentation-2026-v1' AND seed_version=4) THEN
  RAISE EXCEPTION 'The v4 presentation manifest is required for report-history normalization';
 END IF;
END
$guard$;

UPDATE content_reports r SET internal_notes=NULL
FROM uniconnect_presentation_seed_keys k
WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT' AND k.entity_id=r.report_id
  AND r.status='UNDER_REVIEW' AND r.internal_notes IS NOT NULL;

UPDATE report_audit_logs a SET internal_note=NULL
FROM uniconnect_presentation_seed_keys k
WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT' AND k.entity_id=a.report_id
  AND a.event_type='UNDER_REVIEW' AND a.internal_note IS NOT NULL;

DO $verify$
BEGIN
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN content_reports r ON r.report_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
     AND r.status='UNDER_REVIEW' AND r.internal_notes IS NOT NULL) THEN
  RAISE EXCEPTION 'Presentation under-review report retained impossible internal notes';
 END IF;
 IF EXISTS(SELECT 1 FROM uniconnect_presentation_seed_keys k JOIN report_audit_logs a ON a.report_id=k.entity_id
   WHERE k.dataset_key='presentation-2026-v1' AND k.entity_type='REPORT'
     AND a.event_type='UNDER_REVIEW' AND a.internal_note IS NOT NULL) THEN
  RAISE EXCEPTION 'Presentation under-review audit retained impossible internal notes';
 END IF;
END
$verify$;

UPDATE uniconnect_presentation_seed_manifest SET seed_version=5
WHERE dataset_key='presentation-2026-v1' AND seed_version=4;
