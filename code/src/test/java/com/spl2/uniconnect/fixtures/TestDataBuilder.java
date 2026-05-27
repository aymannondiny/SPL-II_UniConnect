package com.spl2.uniconnect.fixtures;

import com.spl2.uniconnect.domain.user.*;
import com.spl2.uniconnect.dto.request.auth.LoginRequest;
import com.spl2.uniconnect.dto.request.auth.RegisterRequest;

/**
 * Builder class to create test data easily
 * Prevents code duplication across tests
 *
 * NOTE: These builders return partially built objects.
 *       Fields like Programme, DegreeLevel (required FK relationships)
 *       must be set in tests that need them.
 */
public class TestDataBuilder {

    // ============================================
    // AUTH REQUEST BUILDERS
    // ============================================

    public static RegisterRequest studentRegistrationRequest() {
        return RegisterRequest.builder()
                .email("student@iut-dhaka.edu")
                .password("Test@1234")
                .fullName("Test Student")
                .role(UserRole.STUDENT)
                .build();
    }

    public static RegisterRequest alumniRegistrationRequest() {
        return RegisterRequest.builder()
                .email("alumni@iut-dhaka.edu")
                .password("Test@1234")
                .fullName("Test Alumni")
                .role(UserRole.ALUMNI)
                .build();
    }

    public static RegisterRequest clubRegistrationRequest() {
        return RegisterRequest.builder()
                .email("club@iut-dhaka.edu")
                .password("Test@1234")
                .fullName("Test Club")
                .role(UserRole.CLUB_ADMIN)
                .build();
    }

    public static RegisterRequest invalidEmailRegistrationRequest() {
        return RegisterRequest.builder()
                .email("student@gmail.com")   // NOT university email
                .password("Test@1234")
                .fullName("Test Student")
                .role(UserRole.STUDENT)
                .build();
    }

    public static RegisterRequest weakPasswordRegistrationRequest() {
        return RegisterRequest.builder()
                .email("student@iut-dhaka.edu")
                .password("123")              // Too short
                .fullName("Test Student")
                .role(UserRole.STUDENT)
                .build();
    }

    public static LoginRequest loginRequest(String email, String password) {
        return LoginRequest.builder()
                .email(email)
                .password(password)
                .build();
    }

    public static LoginRequest validLoginRequest() {
        return LoginRequest.builder()
                .email("student@iut-dhaka.edu")
                .password("Test@1234")
                .build();
    }

    // ============================================
    // USER ENTITY BUILDERS
    // Match EXACTLY with User.java field names:
    //   email, passwordHash, fullName, role, emailVerified
    // ============================================

    public static User.UserBuilder verifiedStudent() {
        return User.builder()
                .email("student@iut-dhaka.edu")
                .passwordHash("$2a$10$hashedpassword")
                .fullName("Test Student")
                .role(UserRole.STUDENT)
                .emailVerified(true);
    }

    public static User.UserBuilder unverifiedStudent() {
        return User.builder()
                .email("unverified@iut-dhaka.edu")
                .passwordHash("$2a$10$hashedpassword")
                .fullName("Unverified Student")
                .role(UserRole.STUDENT)
                .emailVerified(false);
    }

    public static User.UserBuilder verifiedAlumni() {
        return User.builder()
                .email("alumni@iut-dhaka.edu")
                .passwordHash("$2a$10$hashedpassword")
                .fullName("Test Alumni")
                .role(UserRole.ALUMNI)
                .emailVerified(true);
    }

    public static User.UserBuilder verifiedClub() {
        return User.builder()
                .email("club@iut-dhaka.edu")
                .passwordHash("$2a$10$hashedpassword")
                .fullName("Test Club")
                .role(UserRole.CLUB_ADMIN)
                .emailVerified(true);
    }

    public static User.UserBuilder verifiedAdmin() {
        return User.builder()
                .email("admin@iut-dhaka.edu")
                .passwordHash("$2a$10$hashedpassword")
                .fullName("Test Admin")
                .role(UserRole.SYSTEM_ADMIN)
                .emailVerified(true);
    }

    // ============================================
    // PROFILE ENTITY BUILDERS
    // NOTE: StudentProfile and AlumniProfile require
    //       Programme and DegreeLevel - set in test
    // ============================================

    /**
     * Basic StudentProfile builder
     * Programme and DegreeLevel must be set separately
     * because they require database records
     */
    public static StudentProfile.StudentProfileBuilder studentProfile(User user) {
        return StudentProfile.builder()
                .user(user)
                .yearOfStudy(3)
                .bio("Test student bio")
                .lookingForTeammates(true)
                .openToMentorship(false);
    }

    /**
     * Basic AlumniProfile builder
     * Programme and DegreeLevel must be set separately
     */
    public static AlumniProfile.AlumniProfileBuilder alumniProfile(User user) {
        return AlumniProfile.builder()
                .user(user)
                .graduationYear(2020)
                .currentCompany("Tech Corp")
                .currentPosition("Software Engineer")
                .industry("Technology");
    }

    /**
     * ClubProfile builder
     * category is a String in ClubProfile entity
     */
    public static ClubProfile.ClubProfileBuilder clubProfile(User user) {
        return ClubProfile.builder()
                .user(user)
                .clubName("Test Tech Club")
                .description("A club for tech enthusiasts at IUT")
                .category("Tech")
                .foundedYear(2015);
    }

    /**
     * AdminProfile builder
     * field is adminRole (not department)
     */
    public static AdminProfile.AdminProfileBuilder adminProfile(User user) {
        return AdminProfile.builder()
                .user(user)
                .adminRole("Content Moderator");
    }
}
