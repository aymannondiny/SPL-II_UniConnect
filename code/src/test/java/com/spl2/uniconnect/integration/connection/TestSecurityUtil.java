package com.spl2.uniconnect.integration.connection;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.security.UserDetailsImpl;

import java.util.Collections;

public class TestSecurityUtil {

    /**
     * Authenticate a user in the security context for testing
     */
    public static void authenticateUser(User user) {
        // Use the build() method from UserDetailsImpl
        UserDetailsImpl userDetails = UserDetailsImpl.build(user);

        Authentication auth = new UsernamePasswordAuthenticationToken(
                userDetails,
                user.getPasswordHash(),
                userDetails.getAuthorities()
        );

        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    /**
     * Clear the security context
     */
    public static void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }
}