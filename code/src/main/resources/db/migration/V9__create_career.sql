-- ================================================
-- V9: CAREER BOARD MODULE
-- ================================================

-- ================================================
-- 1. JOB POSTINGS TABLE
-- ================================================
CREATE TABLE job_postings (
                              job_id BIGSERIAL PRIMARY KEY,
                              posted_by BIGINT NOT NULL,
                              title VARCHAR(255) NOT NULL,
                              company_name VARCHAR(255) NOT NULL,
                              job_type VARCHAR(50) NOT NULL CHECK (job_type IN ('FULL_TIME', 'PART_TIME', 'INTERNSHIP', 'CO_OP')),
                              location VARCHAR(255) NOT NULL,
                              description TEXT NOT NULL,
                              requirements TEXT,
                              application_link VARCHAR(500),
                              application_email VARCHAR(255),
                              application_deadline DATE,
                              salary_range VARCHAR(100),
                              created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                              CONSTRAINT fk_job_posted_by FOREIGN KEY (posted_by)
                                  REFERENCES users(user_id) ON DELETE CASCADE
);

-- Indexes for job_postings
CREATE INDEX idx_job_posted_by ON job_postings(posted_by);
CREATE INDEX idx_job_type ON job_postings(job_type);
CREATE INDEX idx_job_deadline ON job_postings(application_deadline);

-- ================================================
-- 2. JOB SKILLS TABLE (Junction)
-- ================================================
CREATE TABLE job_skills (
                            job_skill_id BIGSERIAL PRIMARY KEY,
                            job_id BIGINT NOT NULL,
                            skill_id BIGINT NOT NULL,

                            CONSTRAINT fk_job_skill_job FOREIGN KEY (job_id)
                                REFERENCES job_postings(job_id) ON DELETE CASCADE,
                            CONSTRAINT fk_job_skill_skill FOREIGN KEY (skill_id)
                                REFERENCES skills(skill_id) ON DELETE CASCADE,
                            CONSTRAINT uk_job_skill UNIQUE (job_id, skill_id)
);

-- Indexes for job_skills
CREATE INDEX idx_job_skill_job ON job_skills(job_id);
CREATE INDEX idx_job_skill_skill ON job_skills(skill_id);

-- ================================================
-- 3. SAVED JOBS TABLE
-- ================================================
CREATE TABLE saved_jobs (
                            saved_job_id BIGSERIAL PRIMARY KEY,
                            user_id BIGINT NOT NULL,
                            job_id BIGINT NOT NULL,
                            saved_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                            CONSTRAINT fk_saved_job_user FOREIGN KEY (user_id)
                                REFERENCES users(user_id) ON DELETE CASCADE,
                            CONSTRAINT fk_saved_job_job FOREIGN KEY (job_id)
                                REFERENCES job_postings(job_id) ON DELETE CASCADE,
                            CONSTRAINT uk_user_job UNIQUE (user_id, job_id)
);

-- Indexes for saved_jobs
CREATE INDEX idx_saved_job_user ON saved_jobs(user_id);
CREATE INDEX idx_saved_job_job ON saved_jobs(job_id);

-- ================================================
-- 4. COMMENTS (Optional for version tracking)
-- ================================================
COMMENT ON TABLE job_postings IS 'Job opportunities posted by alumni/clubs';
COMMENT ON TABLE job_skills IS 'Skills required for job postings';
COMMENT ON TABLE saved_jobs IS 'Jobs bookmarked by users';

COMMENT ON COLUMN job_postings.job_type IS 'FULL_TIME, PART_TIME, INTERNSHIP, CO_OP';
COMMENT ON COLUMN job_postings.application_link IS 'External application URL';
COMMENT ON COLUMN job_postings.application_email IS 'Email to apply via';
COMMENT ON COLUMN job_postings.salary_range IS 'E.g., "$50,000 - $70,000" or "Competitive"';