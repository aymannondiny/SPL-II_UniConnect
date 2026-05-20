package com.spl2.uniconnect.security;

import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import lombok.AllArgsConstructor;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;

@Getter
@AllArgsConstructor
public class UserDetailsImpl implements UserDetails {

    private Long userId;
    private String email;
    private String password;
    private UserRole role;
    private boolean emailVerified;
    private Collection<? extends GrantedAuthority> authorities;

    /**
     * Build UserDetails from User entity
     */
    public static UserDetailsImpl build(User user) {
        GrantedAuthority authority = new SimpleGrantedAuthority("ROLE_" + user.getRole().name());

        return new UserDetailsImpl(
                user.getUserId(),
                user.getEmail(),
                user.getPasswordHash(),
                user.getRole(),
                user.getEmailVerified(),
                Collections.singletonList(authority)
        );
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return emailVerified; // User must verify email to login
    }
}


//User submits email + password
//        ↓
//Spring Security looks up user
//        ↓
//Your UserDetailsService calls UserDetailsImpl.build(user)
//        ↓
//UserDetailsImpl created with all user info
//        ↓
//Spring Security checks:
//        ✅ isEnabled()           → emailVerified?
//        ✅ isAccountNonLocked()  → true
//        ✅ password matches?     → BCrypt compare
//        ↓
//Authentication SUCCESS
//        ↓
//JWT token generated with userId, email, role
//        ↓
//User can access protected endpoints