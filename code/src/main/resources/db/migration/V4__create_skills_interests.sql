-- ================================================
-- V4: Skills & Interests Tables
-- ================================================

-- Skills
CREATE TABLE skills (
                        skill_id SERIAL PRIMARY KEY,
                        skill_name VARCHAR(100) UNIQUE NOT NULL,
                        category VARCHAR(50)
);

CREATE INDEX idx_skills_name ON skills(skill_name);
CREATE INDEX idx_skills_category ON skills(category);

-- User Skills (Junction Table)
CREATE TABLE user_skills (
                             user_skill_id SERIAL PRIMARY KEY,
                             user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                             skill_id INTEGER NOT NULL REFERENCES skills(skill_id) ON DELETE CASCADE,
                             proficiency_level VARCHAR(20) NOT NULL CHECK (proficiency_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')),
                             created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                             UNIQUE(user_id, skill_id)
);

CREATE INDEX idx_user_skills_user ON user_skills(user_id);
CREATE INDEX idx_user_skills_skill ON user_skills(skill_id);
CREATE INDEX idx_user_skills_proficiency ON user_skills(proficiency_level);

-- Interests
CREATE TABLE interests (
                           interest_id SERIAL PRIMARY KEY,
                           interest_name VARCHAR(100) UNIQUE NOT NULL
);

CREATE INDEX idx_interests_name ON interests(interest_name);

-- User Interests (Junction Table)
CREATE TABLE user_interests (
                                user_interest_id SERIAL PRIMARY KEY,
                                user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                                interest_id INTEGER NOT NULL REFERENCES interests(interest_id) ON DELETE CASCADE,
                                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                UNIQUE(user_id, interest_id)
);

CREATE INDEX idx_user_interests_user ON user_interests(user_id);
CREATE INDEX idx_user_interests_interest ON user_interests(interest_id);

-- ================================================
-- SAMPLE SKILLS DATA (IUT-relevant)
-- ================================================

INSERT INTO skills (skill_name, category) VALUES

                                              -- ── Programming (CSE / SWE students) ──────────────────────────
                                              ('Java',             'Programming'),
                                              ('Python',           'Programming'),
                                              ('JavaScript',       'Programming'),
                                              ('TypeScript',       'Programming'),
                                              ('C',                'Programming'),
                                              ('C++',              'Programming'),
                                              ('C#',               'Programming'),
                                              ('Go',               'Programming'),
                                              ('Rust',             'Programming'),
                                              ('PHP',              'Programming'),
                                              ('Kotlin',           'Programming'),
                                              ('Swift',            'Programming'),
                                              ('SQL',              'Programming'),
                                              ('HTML/CSS',         'Programming'),
                                              ('Bash/Shell',       'Programming'),
                                              ('Assembly',         'Programming'),        -- EEE/CSE low-level programming

                                              -- ── Web & Mobile Frameworks ────────────────────────────────────
                                              ('React',            'Web Development'),
                                              ('Angular',          'Web Development'),
                                              ('Vue.js',           'Web Development'),
                                              ('Next.js',          'Web Development'),
                                              ('Spring Boot',      'Web Development'),
                                              ('Django',           'Web Development'),
                                              ('FastAPI',          'Web Development'),
                                              ('Node.js',          'Web Development'),
                                              ('Express.js',       'Web Development'),
                                              ('Laravel',          'Web Development'),
                                              ('Flutter',          'Mobile Development'),
                                              ('React Native',     'Mobile Development'),
                                              ('Android Dev',      'Mobile Development'),

                                              -- ── Database ──────────────────────────────────────────────────
                                              ('PostgreSQL',       'Database'),
                                              ('MySQL',            'Database'),
                                              ('MongoDB',          'Database'),
                                              ('Redis',            'Database'),
                                              ('Oracle DB',        'Database'),           -- taught in some IUT DB courses
                                              ('Firebase',         'Database'),

                                              -- ── AI / Machine Learning (CSE + Data Science track) ──────────
                                              ('Machine Learning', 'AI/ML'),
                                              ('Deep Learning',    'AI/ML'),
                                              ('Computer Vision',  'AI/ML'),
                                              ('NLP',              'AI/ML'),
                                              ('TensorFlow',       'AI/ML'),
                                              ('PyTorch',          'AI/ML'),
                                              ('Scikit-learn',     'AI/ML'),
                                              ('Data Analysis',    'AI/ML'),
                                              ('Data Science',     'AI/ML'),
                                              ('MATLAB',           'AI/ML'),              -- heavily used in EEE and MPE

                                              -- ── Electrical & Electronic Engineering ───────────────────────
                                              ('Circuit Design',          'Electrical Engineering'),
                                              ('PCB Design',              'Electrical Engineering'),
                                              ('Embedded Systems',        'Electrical Engineering'),
                                              ('Microcontroller (AVR)',    'Electrical Engineering'),
                                              ('Arduino',                 'Electrical Engineering'),
                                              ('Raspberry Pi',            'Electrical Engineering'),
                                              ('PLC Programming',         'Electrical Engineering'),
                                              ('Power Systems Analysis',  'Electrical Engineering'),
                                              ('Signal Processing',       'Electrical Engineering'),
                                              ('VHDL/Verilog',            'Electrical Engineering'),
                                              ('Proteus Simulation',      'Electrical Engineering'),
                                              ('Multisim',                'Electrical Engineering'),
                                              ('AutoCAD Electrical',      'Electrical Engineering'),

                                              -- ── Mechanical & Production Engineering ───────────────────────
                                              ('SolidWorks',              'Mechanical Engineering'),
                                              ('AutoCAD',                 'Mechanical Engineering'),
                                              ('ANSYS',                   'Mechanical Engineering'),
                                              ('CAD/CAM',                 'Mechanical Engineering'),
                                              ('CNC Programming',         'Mechanical Engineering'),
                                              ('Finite Element Analysis', 'Mechanical Engineering'),
                                              ('Thermodynamics',          'Mechanical Engineering'),
                                              ('Fluid Mechanics',         'Mechanical Engineering'),
                                              ('Manufacturing Processes', 'Mechanical Engineering'),
                                              ('Industrial Engineering',  'Mechanical Engineering'),
                                              ('Lean Manufacturing',      'Mechanical Engineering'),
                                              ('Six Sigma',               'Mechanical Engineering'),

                                              -- ── Civil & Environmental Engineering ─────────────────────────
                                              ('Structural Analysis',     'Civil Engineering'),
                                              ('AutoCAD Civil 3D',        'Civil Engineering'),
                                              ('ETABS',                   'Civil Engineering'),
                                              ('SAP2000',                 'Civil Engineering'),
                                              ('Revit',                   'Civil Engineering'),
                                              ('GIS / ArcGIS',            'Civil Engineering'),
                                              ('Surveying',               'Civil Engineering'),
                                              ('Geotechnical Analysis',   'Civil Engineering'),
                                              ('Water Resources Engg',    'Civil Engineering'),
                                              ('Environmental Assessment','Civil Engineering'),
                                              ('Primavera / MS Project',  'Civil Engineering'),

                                              -- ── DevOps / Cloud ─────────────────────────────────────────────
                                              ('Git',                     'DevOps'),
                                              ('Docker',                  'DevOps'),
                                              ('Kubernetes',              'DevOps'),
                                              ('CI/CD',                   'DevOps'),
                                              ('AWS',                     'DevOps'),
                                              ('Azure',                   'DevOps'),
                                              ('Google Cloud',            'DevOps'),
                                              ('Linux Administration',    'DevOps'),
                                              ('Nginx',                   'DevOps'),

                                              -- ── Design ────────────────────────────────────────────────────
                                              ('UI Design',               'Design'),
                                              ('UX Design',               'Design'),
                                              ('Figma',                   'Design'),
                                              ('Adobe XD',                'Design'),
                                              ('Photoshop',               'Design'),
                                              ('Illustrator',             'Design'),
                                              ('Graphic Design',          'Design'),

                                              -- ── Business & Management (BTM students) ──────────────────────
                                              ('Project Management',      'Business'),
                                              ('Business Analysis',       'Business'),
                                              ('Market Research',         'Business'),
                                              ('Financial Analysis',      'Business'),
                                              ('Operations Management',   'Business'),
                                              ('Supply Chain Management', 'Business'),
                                              ('Strategic Planning',      'Business'),
                                              ('Digital Marketing',       'Business'),
                                              ('Entrepreneurship',        'Business'),

                                              -- ── Technical Education (TVE students) ────────────────────────
                                              ('Curriculum Development',  'Education'),
                                              ('Instructional Design',    'Education'),
                                              ('Technical Training',      'Education'),
                                              ('Workshop Management',     'Education'),

                                              -- ── Research & Academic ────────────────────────────────────────
                                              ('LaTeX',                   'Research'),
                                              ('Research Methodology',    'Research'),
                                              ('Academic Writing',        'Research'),
                                              ('Thesis Writing',          'Research'),
                                              ('Statistical Analysis',    'Research'),
                                              ('SPSS',                    'Research'),
                                              ('R Programming',           'Research'),

                                              -- ── Tools ─────────────────────────────────────────────────────
                                              ('JIRA',                    'Tools'),
                                              ('Trello',                  'Tools'),
                                              ('Postman',                 'Tools'),
                                              ('VS Code',                 'Tools'),
                                              ('IntelliJ IDEA',           'Tools'),
                                              ('Eclipse',                 'Tools'),

                                              -- ── Soft Skills ───────────────────────────────────────────────
                                              ('Communication',           'Soft Skills'),
                                              ('Leadership',              'Soft Skills'),
                                              ('Problem Solving',         'Soft Skills'),
                                              ('Teamwork',                'Soft Skills'),
                                              ('Public Speaking',         'Soft Skills'),
                                              ('Critical Thinking',       'Soft Skills'),
                                              ('Time Management',         'Soft Skills'),
                                              ('Technical Writing',       'Soft Skills');


-- ================================================
-- SAMPLE INTERESTS DATA (IUT-relevant)
-- ================================================

INSERT INTO interests (interest_name) VALUES

                                          -- ── CSE / SWE ─────────────────────────────────────────────────
                                          ('Web Development'),
                                          ('Mobile App Development'),
                                          ('Game Development'),
                                          ('Software Architecture'),
                                          ('API Development'),
                                          ('Database Design'),
                                          ('Operating Systems'),
                                          ('Compiler Design'),
                                          ('Cybersecurity'),
                                          ('Ethical Hacking'),
                                          ('Open Source Contribution'),
                                          ('Competitive Programming'),    -- very popular at IUT (ICPC culture)

                                          -- ── AI / Data ─────────────────────────────────────────────────
                                          ('Artificial Intelligence'),
                                          ('Machine Learning'),
                                          ('Deep Learning'),
                                          ('Computer Vision'),
                                          ('Natural Language Processing'),
                                          ('Data Science'),
                                          ('Big Data'),
                                          ('Robotics'),                   -- cross-dept interest (CSE + EEE + MPE)

                                          -- ── EEE ───────────────────────────────────────────────────────
                                          ('Embedded Systems'),
                                          ('IoT (Internet of Things)'),
                                          ('Power Electronics'),
                                          ('Renewable Energy'),
                                          ('Telecommunications'),
                                          ('Signal Processing'),
                                          ('VLSI Design'),
                                          ('Drone Technology'),

                                          -- ── MPE ───────────────────────────────────────────────────────
                                          ('Manufacturing Technology'),
                                          ('Industrial Automation'),
                                          ('3D Printing / Additive Manufacturing'),
                                          ('Sustainable Engineering'),
                                          ('Thermal Engineering'),

                                          -- ── CEE ───────────────────────────────────────────────────────
                                          ('Structural Engineering'),
                                          ('Urban Planning'),
                                          ('Environmental Engineering'),
                                          ('Water Resources Management'),
                                          ('Green Building Design'),

                                          -- ── BTM ───────────────────────────────────────────────────────
                                          ('Entrepreneurship'),
                                          ('Startups'),
                                          ('Product Management'),
                                          ('Tech Business Strategy'),
                                          ('E-Commerce'),
                                          ('Digital Marketing'),
                                          ('Financial Technology (FinTech)'),

                                          -- ── TVE ───────────────────────────────────────────────────────
                                          ('Technical Education'),
                                          ('Vocational Training'),
                                          ('Curriculum Design'),
                                          ('E-Learning / EdTech'),

                                          -- ── Research & Innovation (all depts) ─────────────────────────
                                          ('Academic Research'),
                                          ('Innovation and Prototyping'),
                                          ('Patent and IP'),
                                          ('Science Communication'),

                                          -- ── Cloud & DevOps ────────────────────────────────────────────
                                          ('Cloud Computing'),
                                          ('DevOps'),
                                          ('Microservices'),
                                          ('Blockchain'),

                                          -- ── General Tech & Culture ────────────────────────────────────
                                          ('Open Hardware'),
                                          ('Tech Journalism'),
                                          ('UI/UX Design'),
                                          ('Photography'),
                                          ('Video Editing'),
                                          ('Community Service'),          -- IUT has strong OIC community culture
                                          ('Sports & Athletics'),
                                          ('Debate and Public Speaking');