package com.uniconnect.authentication.controller;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.RegisterRequest;
import com.uniconnect.authentication.dto.RegisterResponse;
import com.uniconnect.authentication.service.RegistrationService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthenticationController {

    private final RegistrationService registrationService;

    public AuthenticationController(
            RegistrationService registrationService
    ) {
        this.registrationService = registrationService;
    }

    @PostMapping("/register")
    public ResponseEntity<RegisterResponse> register(
            @Valid @RequestBody RegisterRequest request
    ) {
        User user = registrationService.register(
                request.fullName(),
                request.email(),
                request.password(),
                request.platformRole()
        );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(RegisterResponse.from(user));
    }
}
