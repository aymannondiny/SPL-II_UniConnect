package com.uniconnect.shared.security;

import com.uniconnect.authentication.service.InvalidSessionException;
import com.uniconnect.authentication.service.SessionService;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.Collections;
import java.util.List;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

public class SessionAuthenticationFilter extends OncePerRequestFilter {
    private static final org.slf4j.Logger LOGGER = org.slf4j.LoggerFactory.getLogger(SessionAuthenticationFilter.class);
    private final SecurityErrorResponseWriter errorWriter;
    private final SessionService sessions;
    private final ApiAuthenticationEntryPoint entryPoint;

    public SessionAuthenticationFilter(SessionService sessions, ApiAuthenticationEntryPoint entryPoint, SecurityErrorResponseWriter errorWriter) {
        this.errorWriter = errorWriter;
        this.sessions = sessions;
        this.entryPoint = entryPoint;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
            FilterChain chain) throws ServletException, IOException {
        var headers = Collections.list(request.getHeaders("Authorization"));
        if (!headers.isEmpty()) {
            String header = headers.getFirst();
            try {
                if (headers.size() != 1 || !header.regionMatches(true, 0, "Bearer ", 0, 7)) {
                    throw new InvalidSessionException();
                }
                var principal = sessions.authenticate(header.substring(7));
                var authentication = UsernamePasswordAuthenticationToken.authenticated(principal, null,
                        List.of(new SimpleGrantedAuthority(principal.platformRole().name())));
                var context = SecurityContextHolder.createEmptyContext();
                context.setAuthentication(authentication);
                SecurityContextHolder.setContext(context);
            } catch (InvalidSessionException e) {
                SecurityContextHolder.clearContext();
                entryPoint.commence(request, response, new BadCredentialsException("Invalid session"));
                return;
            } catch (RuntimeException e) {
                SecurityContextHolder.clearContext();
                LOGGER.error("Session authentication failed: {}", e.getClass().getSimpleName());
                errorWriter.write(request, response, org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR,
                        "INTERNAL_ERROR", "An unexpected server error occurred.");
                return;
            }
        }
        chain.doFilter(request, response);
    }
}
