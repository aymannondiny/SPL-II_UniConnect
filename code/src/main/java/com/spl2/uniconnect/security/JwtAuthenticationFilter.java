package com.spl2.uniconnect.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    private final JwtTokenProvider tokenProvider;
    private final UserDetailsServiceImpl userDetailsService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        try {
            String jwt = getJwtFromRequest(request);

            if (StringUtils.hasText(jwt) && tokenProvider.validateToken(jwt)) {
                Long userId = tokenProvider.getUserIdFromToken(jwt);

                UserDetails userDetails = userDetailsService.loadUserById(userId);

                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities()
                        );

                authentication.setDetails(
                        new WebAuthenticationDetailsSource().buildDetails(request)
                );

                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (Exception ex) {
            logger.error("Could not set user authentication in security context", ex);
        }

        filterChain.doFilter(request, response);
    }

    /**
     * Extract JWT from Authorization header
     */
    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");

        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }

        return null;
    }
}



//HTTP Request: GET /api/posts
//Header: "Authorization: Bearer abc123token"
//        ↓
//        JwtAuthenticationFilter.doFilterInternal()
//                ↓
//getJwtFromRequest()
//                ↓
//Extract "abc123token" from header
//                ↓
//                        StringUtils.hasText("abc123token") → true ✅
//        ↓
//        tokenProvider.validateToken("abc123token") → true ✅
//        ↓
//        tokenProvider.getUserIdFromToken() → userId = 42
//        ↓
//        userDetailsService.loadUserById(42)
//                ↓
//DB lookup → User found → UserDetailsImpl.build()
//                ↓
//                        new UsernamePasswordAuthenticationToken(userDetails, null, authorities)
//                ↓
//                        authentication.setDetails(requestDetails)
//                ↓
//                        SecurityContextHolder.getContext().setAuthentication(authentication)
//                ↓
//                        filterChain.doFilter() → passes to next filter
//                ↓
//Controller receives request
//                ↓
//@AuthenticationPrincipal → gives you the logged in user ✅




//Person arrives at building (HTTP Request)
//        ↓
//Guard checks for ID badge (Authorization header)
//        ↓
//No badge? → Let them in as VISITOR (unauthenticated)
//        ↓
//Badge found → Check if badge is real (validateToken)
//        ↓
//Fake badge → Let them in as VISITOR (unauthenticated)
//        ↓
//Real badge → Read name on badge (getUserIdFromToken)
//        ↓
//Check employee records (loadUserById)
//        ↓
//Give them their access level (setAuthentication)
//        ↓
//Let them through to their floor (filterChain.doFilter)