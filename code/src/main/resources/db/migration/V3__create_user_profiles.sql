-- ================================================
-- V3: User Profile Tables
-- ================================================

-- Student Profiles
CREATE TABLE student_profiles (
                                  student_id SERIAL PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
                                  programme_id INTEGER NOT NULL REFERENCES programmes(programme_id),
                                  degree_level_id INTEGER NOT NULL REFERENCES degree_levels(degree_level_id),
                                  year_of_study INTEGER NOT NULL CHECK (year_of_study >= 1 AND year_of_study <= 7),
                                  expected_graduation_year INTEGER CHECK (expected_graduation_year >= 2024 AND expected_graduation_year <= 2050),
                                  bio TEXT CHECK (LENGTH(bio) <= 5000),
                                  looking_for_teammates BOOLEAN DEFAULT FALSE NOT NULL,
                                  open_to_mentorship BOOLEAN DEFAULT FALSE NOT NULL,
                                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_student_profiles_programme ON student_profiles(programme_id);
CREATE INDEX idx_student_profiles_degree ON student_profiles(degree_level_id);
CREATE INDEX idx_student_profiles_looking_teammates ON student_profiles(looking_for_teammates);

-- Alumni Profiles
-- Alumni Profiles (UPDATED: dynamic year constraint)
CREATE TABLE alumni_profiles (
                                 alumni_id SERIAL PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
                                 graduation_year INTEGER NOT NULL CHECK (graduation_year >= 1900), -- Only check lower bound, not upper
                                 programme_id INTEGER NOT NULL REFERENCES programmes(programme_id),
                                 degree_level_id INTEGER NOT NULL REFERENCES degree_levels(degree_level_id),
                                 current_company VARCHAR(255),
                                 current_position VARCHAR(255),
                                 industry VARCHAR(100),
                                 career_background TEXT CHECK (LENGTH(career_background) <= 5000),
                                 linkedin_url VARCHAR(500),
                                 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alumni_profiles_graduation_year ON alumni_profiles(graduation_year);
CREATE INDEX idx_alumni_profiles_programme ON alumni_profiles(programme_id);
CREATE INDEX idx_alumni_profiles_degree ON alumni_profiles(degree_level_id);
CREATE INDEX idx_alumni_profiles_industry ON alumni_profiles(industry);
-- Club Profiles
CREATE TABLE club_profiles (
                               club_id SERIAL PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
                               club_name VARCHAR(255) UNIQUE NOT NULL CHECK (LENGTH(club_name) >= 3),
                               description TEXT NOT NULL CHECK (LENGTH(description) >= 10),
                               category VARCHAR(50) NOT NULL CHECK (category IN ('Academic', 'Sports', 'Cultural', 'Tech', 'Arts', 'Service', 'Other')),
                               department_id INTEGER REFERENCES departments(department_id),
                               founded_year INTEGER CHECK (founded_year >= 1900 AND founded_year <= 2024),
                               meeting_schedule VARCHAR(255),
                               contact_email VARCHAR(255),
                               website_url VARCHAR(500),
                               club_logo VARCHAR(500),
                               created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_club_profiles_name ON club_profiles(club_name);
CREATE INDEX idx_club_profiles_category ON club_profiles(category);
CREATE INDEX idx_club_profiles_department ON club_profiles(department_id);

-- Admin Profiles
CREATE TABLE admin_profiles (
                                admin_id SERIAL PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
                                admin_role VARCHAR(100) NOT NULL CHECK (LENGTH(admin_role) >= 3)
);

CREATE INDEX idx_admin_profiles_role ON admin_profiles(admin_role);