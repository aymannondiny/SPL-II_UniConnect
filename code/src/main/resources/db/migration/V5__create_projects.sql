-- ================================================
-- V5: Projects Module Tables
-- ================================================

-- Projects
CREATE TABLE projects (
                          project_id SERIAL PRIMARY KEY,
                          creator_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                          title VARCHAR(200) NOT NULL CHECK (LENGTH(title) >= 5),
                          description TEXT NOT NULL CHECK (LENGTH(description) >= 20),
                          teammates_needed INTEGER NOT NULL CHECK (teammates_needed >= 1 AND teammates_needed <= 10),
                          course_name VARCHAR(100),
                          application_deadline DATE,
                          project_duration VARCHAR(100),
                          status VARCHAR(20) NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'Closed')),
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_projects_creator ON projects(creator_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_deadline ON projects(application_deadline);

-- Project Skills (Junction Table)
CREATE TABLE project_skills (
                                project_skill_id SERIAL PRIMARY KEY,
                                project_id INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
                                skill_id INTEGER NOT NULL REFERENCES skills(skill_id) ON DELETE CASCADE,
                                is_required BOOLEAN NOT NULL DEFAULT TRUE,
                                UNIQUE(project_id, skill_id)
);

CREATE INDEX idx_project_skills_project ON project_skills(project_id);
CREATE INDEX idx_project_skills_skill ON project_skills(skill_id);

-- Tags
CREATE TABLE tags (
                      tag_id SERIAL PRIMARY KEY,
                      tag_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE INDEX idx_tags_name ON tags(tag_name);

-- Project Tags (Junction Table)
CREATE TABLE project_tags (
                              project_tag_id SERIAL PRIMARY KEY,
                              project_id INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
                              tag_id INTEGER NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
                              UNIQUE(project_id, tag_id)
);

CREATE INDEX idx_project_tags_project ON project_tags(project_id);
CREATE INDEX idx_project_tags_tag ON project_tags(tag_id);

-- Project Applications
CREATE TABLE project_applications (
                                      application_id SERIAL PRIMARY KEY,
                                      project_id INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
                                      applicant_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                                      message TEXT,
                                      status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Accepted', 'Rejected')),
                                      applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                      responded_at TIMESTAMP,
                                      UNIQUE(project_id, applicant_id)
);

CREATE INDEX idx_project_applications_project ON project_applications(project_id);
CREATE INDEX idx_project_applications_applicant ON project_applications(applicant_id);
CREATE INDEX idx_project_applications_status ON project_applications(status);

-- Project Members
CREATE TABLE project_members (
                                 member_id SERIAL PRIMARY KEY,
                                 project_id INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
                                 user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                                 role VARCHAR(20) NOT NULL CHECK (LENGTH(role) >= 2),
                                 joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                 UNIQUE(project_id, user_id)
);

CREATE INDEX idx_project_members_project ON project_members(project_id);
CREATE INDEX idx_project_members_user ON project_members(user_id);

-- ================================================
-- SAMPLE TAGS DATA (IUT-relevant)
-- ================================================

INSERT INTO tags (tag_name) VALUES

                                -- ── CSE / SWE Project Types ────────────────────────────────────
                                ('Web Development'),
                                ('Mobile Development'),
                                ('Desktop Application'),
                                ('Full Stack'),
                                ('Backend'),
                                ('Frontend'),
                                ('REST API'),
                                ('Microservices'),

                                -- ── AI / Data ──────────────────────────────────────────────────
                                ('Machine Learning'),
                                ('Deep Learning'),
                                ('Computer Vision'),
                                ('Natural Language Processing'),
                                ('Data Science'),
                                ('Data Visualization'),
                                ('Recommendation System'),
                                ('Chatbot'),

                                -- ── Systems & Infrastructure ───────────────────────────────────
                                ('DevOps'),
                                ('Cloud Computing'),
                                ('Cybersecurity'),
                                ('Networking'),
                                ('Operating System'),
                                ('Compiler'),
                                ('Embedded Systems'),
                                ('IoT'),
                                ('Blockchain'),

                                -- ── EEE Project Types ──────────────────────────────────────────
                                ('Circuit Design'),
                                ('PCB Design'),
                                ('Power Systems'),
                                ('Renewable Energy'),
                                ('Signal Processing'),
                                ('Telecommunications'),
                                ('VLSI'),
                                ('Robotics'),
                                ('Drone'),
                                ('Arduino'),
                                ('Raspberry Pi'),
                                ('Home Automation'),

                                -- ── MPE Project Types ──────────────────────────────────────────
                                ('CAD Modelling'),
                                ('Simulation'),
                                ('Manufacturing'),
                                ('Industrial Automation'),
                                ('3D Printing'),
                                ('Thermal Systems'),
                                ('Fluid Dynamics'),

                                -- ── CEE Project Types ──────────────────────────────────────────
                                ('Structural Design'),
                                ('Urban Planning'),
                                ('Environmental Engineering'),
                                ('Water Resources'),
                                ('GIS Mapping'),
                                ('Green Building'),
                                ('Construction Management'),

                                -- ── BTM Project Types ──────────────────────────────────────────
                                ('Business Plan'),
                                ('Market Research'),
                                ('Startup'),
                                ('E-Commerce'),
                                ('FinTech'),
                                ('Digital Marketing'),
                                ('Product Management'),

                                -- ── TVE Project Types ──────────────────────────────────────────
                                ('EdTech'),
                                ('E-Learning Platform'),
                                ('Curriculum Design'),
                                ('Vocational Training'),

                                -- ── Academic / Research ────────────────────────────────────────
                                ('Thesis'),
                                ('Research Paper'),
                                ('Final Year Project'),
                                ('Capstone'),
                                ('Lab Project'),
                                ('Course Project'),
                                ('Innovation'),
                                ('Prototype'),

                                -- ── Cross-Department / General ─────────────────────────────────
                                ('Open Source'),
                                ('Hackathon'),
                                ('ICPC'),                       -- competitive programming culture at IUT
                                ('Game Development'),
                                ('AR/VR'),
                                ('UI/UX Design'),
                                ('Social Impact'),              -- OIC/community-focused projects
                                ('Interdisciplinary');          -- cross-dept collaboration projects