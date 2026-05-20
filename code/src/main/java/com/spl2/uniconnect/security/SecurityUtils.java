package com.spl2.uniconnect.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public class SecurityUtils {

    private SecurityUtils() {
        // Utility class
    }

    /**
     * Get current authenticated user ID
     */
    public static Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }

        Object principal = authentication.getPrincipal();

        if (principal instanceof UserDetailsImpl) {
            return ((UserDetailsImpl) principal).getUserId();
        }

        return null;
    }

    /**
     * Get current authenticated user details
     */
    public static UserDetailsImpl getCurrentUserDetails() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }

        Object principal = authentication.getPrincipal();

        if (principal instanceof UserDetailsImpl) {
            return (UserDetailsImpl) principal;
        }

        return null;
    }

    /**
     * Check if user is authenticated
     */
    public static boolean isAuthenticated() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.isAuthenticated()
                && authentication.getPrincipal() instanceof UserDetailsImpl;
    }
}


//HTTP Request with JWT
//        ↓
//JwtAuthenticationFilter
//        ↓
//Sets SecurityContextHolder with Ayman's data
//        ↓
//Request reaches PostService.createPost()
//        ↓
//                SecurityUtils.getCurrentUserId()
//        ↓
//Reads SecurityContextHolder
//        ↓
//Returns 42 (Ayman's userId)
//        ↓
//Post created with userId = 42 ✅



//SecurityContextHolder = Filing Cabinet
//Authentication = File Folder
//Principal = Document inside the folder
//UserDetailsImpl = The actual document with all info
//
//SecurityUtils = The assistant who:
//        → Opens the cabinet
//    → Finds the right folder
//    → Checks the document is the right type
//    → Hands you exactly what you need
//    → Returns null if anything is missing

