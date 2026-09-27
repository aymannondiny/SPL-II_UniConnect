package com.uniconnect.authentication.controller;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.RegisterRequest;
import com.uniconnect.authentication.dto.RegisterResponse;
import com.uniconnect.authentication.service.RegistrationService;
import com.uniconnect.shared.exception.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(
        name = "Authentication",
        description = "Authentication and account lifecycle endpoints"
)
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
    @Operation(
            summary = "Register a new user",
            description = """
                Registers a new UniConnect user using an IUT email address.
                Public registration supports STUDENT and ALUMNI roles only.
                Newly registered accounts start in PENDING_VERIFICATION status.
                """
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "201",
                    description = "User registered successfully",
                    content = @Content(
                            schema = @Schema(implementation = RegisterResponse.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Invalid registration request",
                    content = @Content(
                            schema = @Schema(implementation = ApiError.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "409",
                    description = "Email address is already registered",
                    content = @Content(
                            schema = @Schema(implementation = ApiError.class)
                    )
            )
    })
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
