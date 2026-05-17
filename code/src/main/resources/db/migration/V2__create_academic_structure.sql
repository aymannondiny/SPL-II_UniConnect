-- ================================================
-- V2: Academic Structure Tables (WITH CONSTRAINTS)
-- ================================================

-- Departments
CREATE TABLE departments (
                             department_id SERIAL PRIMARY KEY,
                             department_name VARCHAR(255) UNIQUE NOT NULL CHECK (LENGTH(department_name) >= 3),
                             department_code VARCHAR(20) UNIQUE NOT NULL CHECK (department_code ~ '^[A-Z]{2,10}$'),
    description TEXT CHECK (LENGTH(description) <= 5000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_departments_code ON departments(department_code);
CREATE INDEX idx_departments_name ON departments(department_name);

-- Programmes
CREATE TABLE programmes (
                            programme_id SERIAL PRIMARY KEY,
                            department_id INTEGER NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
                            programme_name VARCHAR(255) NOT NULL CHECK (LENGTH(programme_name) >= 3),
                            programme_code VARCHAR(20) NOT NULL CHECK (programme_code ~ '^[A-Z]{2,10}$'),
    description TEXT CHECK (LENGTH(description) <= 5000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(department_id, programme_code)
);

CREATE INDEX idx_programmes_department ON programmes(department_id);
CREATE INDEX idx_programmes_code ON programmes(programme_code);

-- Degree Levels
CREATE TABLE degree_levels (
                               degree_level_id SERIAL PRIMARY KEY,
                               degree_name VARCHAR(50) UNIQUE NOT NULL
                                   CHECK (degree_name IN ('Undergraduate', 'Masters', 'PhD', 'Diploma', 'Certificate')),
                               min_years INTEGER NOT NULL CHECK (min_years >= 1 AND min_years <= 10),
                               max_years INTEGER NOT NULL CHECK (max_years >= 1 AND max_years <= 10),
                               description TEXT CHECK (LENGTH(description) <= 5000),
                               CONSTRAINT valid_year_range CHECK (min_years <= max_years)
);

CREATE INDEX idx_degree_levels_name ON degree_levels(degree_name);

-- Programme Degrees (Junction)
CREATE TABLE programme_degrees (
                                   programme_degree_id SERIAL PRIMARY KEY,
                                   programme_id INTEGER NOT NULL REFERENCES programmes(programme_id) ON DELETE CASCADE,
                                   degree_level_id INTEGER NOT NULL REFERENCES degree_levels(degree_level_id) ON DELETE CASCADE,
                                   duration_years INTEGER NOT NULL CHECK (duration_years >= 1 AND duration_years <= 10),
                                   UNIQUE(programme_id, degree_level_id)
);

CREATE INDEX idx_programme_degrees_programme ON programme_degrees(programme_id);
CREATE INDEX idx_programme_degrees_degree ON programme_degrees(degree_level_id);

-- ================================================
-- SEED DATA
-- ================================================

-- Degree Levels
INSERT INTO degree_levels (degree_name, min_years, max_years, description) VALUES
                                                                               ('Undergraduate', 3, 5, 'Bachelor degree programmes (B.Sc., BBA, B.Sc.TE)'),
                                                                               ('Masters',       1, 2, 'Masters degree programmes (M.Sc., M.Engg, M.Sc.TE)'),
                                                                               ('PhD',           3, 7, 'Doctoral research programmes'),
                                                                               ('Diploma',       1, 2, 'Diploma level technical programmes'),
                                                                               ('Certificate',   1, 1, 'Short certificate programmes');

-- Departments (all 7 IUT departments)
INSERT INTO departments (department_name, department_code, description) VALUES
                                                                            ('Computer Science and Engineering',        'CSE', 'Covers computing, software, algorithms, AI and related disciplines'),
                                                                            ('Electrical and Electronic Engineering',   'EEE', 'Power systems, electronics, telecommunications and control engineering'),
                                                                            ('Mechanical and Production Engineering',   'MPE', 'Mechanical systems, thermodynamics, manufacturing and industrial engineering'),
                                                                            ('Civil and Environmental Engineering',     'CEE', 'Structural, geotechnical, environmental and water resources engineering'),
                                                                            ('Business and Technology Management',      'BTM', 'Management, business administration and technology management'),
                                                                            ('Technical and Vocational Education',      'TVE', 'Technical teacher education and vocational training'),
                                                                            ('Natural Sciences',                        'NSC', 'Mathematics, physics, chemistry and other foundational sciences');


-- ================================================
-- PROGRAMMES (per department)
-- ================================================

DO $$
DECLARE
    -- Department IDs
cse_id  INTEGER;
    eee_id  INTEGER;
    mpe_id  INTEGER;
    cee_id  INTEGER;
    btm_id  INTEGER;
    tve_id  INTEGER;
    nsc_id  INTEGER;

    -- Degree Level IDs
    undergrad_id  INTEGER;
    masters_id    INTEGER;
    phd_id        INTEGER;
    diploma_id    INTEGER;
    cert_id       INTEGER;

    -- Programme IDs — CSE
    p_cse_id  INTEGER;
    p_swe_id  INTEGER;
    p_csa_id  INTEGER;

    -- Programme IDs — EEE
    p_eee_id  INTEGER;

    -- Programme IDs — MPE
    p_me_id   INTEGER;
    p_ipe_id  INTEGER;

    -- Programme IDs — CEE
    p_ce_id   INTEGER;

    -- Programme IDs — BTM
    p_tm_id   INTEGER;

    -- Programme IDs — TVE
    p_bscte_id  INTEGER;
    p_mscte_id  INTEGER;

    -- Programme IDs — NSc  (service dept — one foundational programme)
    p_ns_id  INTEGER;

BEGIN
    -- Fetch Department IDs
SELECT department_id INTO cse_id FROM departments WHERE department_code = 'CSE';
SELECT department_id INTO eee_id FROM departments WHERE department_code = 'EEE';
SELECT department_id INTO mpe_id FROM departments WHERE department_code = 'MPE';
SELECT department_id INTO cee_id FROM departments WHERE department_code = 'CEE';
SELECT department_id INTO btm_id FROM departments WHERE department_code = 'BTM';
SELECT department_id INTO tve_id FROM departments WHERE department_code = 'TVE';
SELECT department_id INTO nsc_id FROM departments WHERE department_code = 'NSC';

-- Fetch Degree Level IDs
SELECT degree_level_id INTO undergrad_id FROM degree_levels WHERE degree_name = 'Undergraduate';
SELECT degree_level_id INTO masters_id   FROM degree_levels WHERE degree_name = 'Masters';
SELECT degree_level_id INTO phd_id       FROM degree_levels WHERE degree_name = 'PhD';
SELECT degree_level_id INTO diploma_id   FROM degree_levels WHERE degree_name = 'Diploma';
SELECT degree_level_id INTO cert_id      FROM degree_levels WHERE degree_name = 'Certificate';

-- ------------------------------------------------
-- CSE Programmes
-- ------------------------------------------------
INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (cse_id, 'Computer Science and Engineering', 'CSE', 'Core CS programme covering algorithms, systems, AI and software engineering')
    RETURNING programme_id INTO p_cse_id;

INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (cse_id, 'Software Engineering', 'SWE', 'Software design, development, testing and project management')
    RETURNING programme_id INTO p_swe_id;

INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (cse_id, 'Computer Science and Applications', 'CSA', 'Postgraduate programme focusing on applied computing and research')
    RETURNING programme_id INTO p_csa_id;

-- ------------------------------------------------
-- EEE Programmes
-- ------------------------------------------------
INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (eee_id, 'Electrical and Electronic Engineering', 'EEE', 'Power systems, electronics, telecommunications and control')
    RETURNING programme_id INTO p_eee_id;

-- ------------------------------------------------
-- MPE Programmes
-- ------------------------------------------------
INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (mpe_id, 'Mechanical Engineering', 'ME', 'Thermodynamics, fluid mechanics, machine design and manufacturing')
    RETURNING programme_id INTO p_me_id;

INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (mpe_id, 'Industrial and Production Engineering', 'IPE', 'Production systems, operations research and industrial management')
    RETURNING programme_id INTO p_ipe_id;

-- ------------------------------------------------
-- CEE Programmes
-- ------------------------------------------------
INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (cee_id, 'Civil Engineering', 'CE', 'Structural, geotechnical, environmental and water resources engineering')
    RETURNING programme_id INTO p_ce_id;

-- ------------------------------------------------
-- BTM Programmes
-- ------------------------------------------------
INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (btm_id, 'Technology Management', 'TM', 'BBA programme combining business administration with technology management')
    RETURNING programme_id INTO p_tm_id;

-- ------------------------------------------------
-- TVE Programmes
-- ------------------------------------------------
INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (tve_id, 'Technical Education', 'TE', 'B.Sc. in Technical Education — trains technical teachers and vocational educators')
    RETURNING programme_id INTO p_bscte_id;

INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (tve_id, 'Technical Education Postgraduate', 'TEP', 'M.Sc. in Technical Education and PhD for advanced research in vocational education')
    RETURNING programme_id INTO p_mscte_id;

-- ------------------------------------------------
-- NSc Programme (service/foundational dept)
-- ------------------------------------------------
INSERT INTO programmes (department_id, programme_name, programme_code, description)
VALUES (nsc_id, 'Natural Sciences', 'NS', 'Foundational sciences: mathematics, physics and chemistry supporting all engineering departments')
    RETURNING programme_id INTO p_ns_id;


-- ================================================
-- PROGRAMME-DEGREE LINKS
-- ================================================

-- CSE → Undergraduate (4 years), Masters (2 years), PhD (5 years)
INSERT INTO programme_degrees (programme_id, degree_level_id, duration_years) VALUES
                                                                                  (p_cse_id, undergrad_id, 4),
                                                                                  (p_cse_id, masters_id,   2),
                                                                                  (p_cse_id, phd_id,       5);

-- SWE → Undergraduate only (4 years)
INSERT INTO programme_degrees (programme_id, degree_level_id, duration_years) VALUES
    (p_swe_id, undergrad_id, 4);

-- CSA → Masters only (postgrad programme)
INSERT INTO programme_degrees (programme_id, degree_level_id, duration_years) VALUES
    (p_csa_id, masters_id, 2);

-- EEE → Undergraduate (4 years), Masters (2 years), PhD (5 years)
INSERT INTO programme_degrees (programme_id, degree_level_id, duration_years) VALUES
                                                                                  (p_eee_id, undergrad_id, 4),
                                                                                  (p_eee_id, masters_id,   2),
                                                                                  (p_eee_id, phd_id,       5);

-- ME → Undergraduate (4 years), Masters (2 years), PhD (5 years)
INSERT INTO programme_degrees (programme_id, degree_level_id, duration_years) VALUES
                                                                                  (p_me_id, undergrad_id, 4),
                                                                                  (p_me_id, masters_id,   2),
                                                                                  (p_me_id, phd_id,       5);

-- IPE → Undergraduate (4 years), Masters (2 years)
INSERT INTO programme_degrees (programme_id, degree_level_id, duration_years) VALUES
                                                                                  (p_ipe_id, undergrad_id, 4),
                                                                                  (p_ipe_id, masters_id,   2);

-- CE → Undergraduate (4 years), Masters (2 years), PhD (5 years)
INSERT INTO programme_degrees (programme_id, degree_level_id, duration_years) VALUES
                                                                                  (p_ce_id, undergrad_id, 4),
                                                                                  (p_ce_id, masters_id,   2),
                                                                                  (p_ce_id, phd_id,       5);

-- TM (BBA) → Undergraduate (4 years)
INSERT INTO programme_degrees (programme_id, degree_level_id, duration_years) VALUES
    (p_tm_id, undergrad_id, 4);

-- TVE B.Sc.TE → Undergraduate (3 years)
INSERT INTO programme_degrees (programme_id, degree_level_id, duration_years) VALUES
    (p_bscte_id, undergrad_id, 3);

-- TVE Postgraduate → Masters (2 years), PhD (5 years)
INSERT INTO programme_degrees (programme_id, degree_level_id, duration_years) VALUES
                                                                                  (p_mscte_id, masters_id, 2),
                                                                                  (p_mscte_id, phd_id,     5);

-- NSc → no standalone degree offered (service dept), skipped intentionally

END $$;