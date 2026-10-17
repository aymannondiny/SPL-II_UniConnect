package com.uniconnect.shared.exception;

import org.junit.jupiter.api.Test;
import org.springframework.core.MethodParameter;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.mock.http.MockHttpInputMessage;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.lang.reflect.Method;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTests {

    private final GlobalExceptionHandler handler =
            new GlobalExceptionHandler();

    @Test
    void mapsApplicationExceptionToConsistentErrorResponse() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/users/42");

        ResourceNotFoundException exception =
                new ResourceNotFoundException("User", 42L);

        ResponseEntity<ApiError> response =
                handler.handleApplicationException(exception, request);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).isNotNull();

        ApiError body = response.getBody();

        assertThat(body.status()).isEqualTo(404);
        assertThat(body.error()).isEqualTo("Not Found");
        assertThat(body.code()).isEqualTo("RESOURCE_NOT_FOUND");
        assertThat(body.message())
                .isEqualTo("User with identifier '42' was not found.");
        assertThat(body.path()).isEqualTo("/api/users/42");
        assertThat(body.fieldErrors()).isEmpty();
        assertThat(body.timestamp()).isNotNull();
    }

    @Test
    void mapsValidationErrorsToFieldErrors() throws Exception {
        Method method = ValidationTarget.class.getDeclaredMethod(
                "create",
                SampleRequest.class
        );

        MethodParameter parameter = new MethodParameter(method, 0);

        SampleRequest target = new SampleRequest("");
        BeanPropertyBindingResult bindingResult =
                new BeanPropertyBindingResult(target, "request");

        bindingResult.addError(
                new FieldError(
                        "request",
                        "name",
                        "must not be blank"
                )
        );

        MethodArgumentNotValidException exception =
                new MethodArgumentNotValidException(
                        parameter,
                        bindingResult
                );

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/test");

        ResponseEntity<ApiError> response =
                handler.handleValidationException(exception, request);

        assertThat(response.getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();

        ApiError body = response.getBody();

        assertThat(body.code()).isEqualTo("VALIDATION_FAILED");
        assertThat(body.message())
                .isEqualTo("Request validation failed.");
        assertThat(body.path()).isEqualTo("/api/test");
        assertThat(body.fieldErrors())
                .containsExactly(
                        new ApiError.FieldViolation(
                                "name",
                                "must not be blank"
                        )
                );
    }

    @Test
    void hidesInternalDetailsForUnexpectedExceptions() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/test");

        Exception exception =
                new IllegalStateException("Sensitive internal detail");

        ResponseEntity<ApiError> response =
                handler.handleUnexpectedException(exception, request);

        assertThat(response.getStatusCode())
                .isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody()).isNotNull();

        ApiError body = response.getBody();

        assertThat(body.code()).isEqualTo("INTERNAL_ERROR");
        assertThat(body.message())
                .isEqualTo("An unexpected server error occurred.");
        assertThat(body.message())
                .doesNotContain("Sensitive internal detail");
        assertThat(body.path()).isEqualTo("/api/test");
    }

    @Test
    void mapsConflictExceptionTo409() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/v1/test");

        ConflictException exception =
                new ConflictException(
                        "TEST_CONFLICT",
                        "The requested operation conflicts with current state."
                );

        ResponseEntity<ApiError> response =
                handler.handleApplicationException(exception, request);

        assertThat(response.getStatusCode())
                .isEqualTo(HttpStatus.CONFLICT);
        assertThat(response.getBody()).isNotNull();

        ApiError body = response.getBody();

        assertThat(body.status()).isEqualTo(409);
        assertThat(body.error()).isEqualTo("Conflict");
        assertThat(body.code()).isEqualTo("TEST_CONFLICT");
        assertThat(body.message())
                .isEqualTo(
                        "The requested operation conflicts with current state."
                );
        assertThat(body.path()).isEqualTo("/api/v1/test");
        assertThat(body.fieldErrors()).isEmpty();
    }

    @Test
    void mapsMalformedRequestToSafe400Response() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/v1/test");

        HttpMessageNotReadableException exception =
                new HttpMessageNotReadableException(
                        "Sensitive JSON parser detail",
                        new MockHttpInputMessage(new byte[0])
                );

        ResponseEntity<ApiError> response =
                handler.handleMalformedRequest(exception, request);

        assertThat(response.getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();

        ApiError body = response.getBody();

        assertThat(body.status()).isEqualTo(400);
        assertThat(body.error()).isEqualTo("Bad Request");
        assertThat(body.code()).isEqualTo("MALFORMED_REQUEST");
        assertThat(body.message())
                .isEqualTo("Request body is malformed or unreadable.");
        assertThat(body.message())
                .doesNotContain("Sensitive JSON parser detail");
        assertThat(body.path()).isEqualTo("/api/v1/test");
        assertThat(body.fieldErrors()).isEmpty();
    }

    @Test
    void mapsMissingResourceToSafe404Response() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/v1/missing");

        NoResourceFoundException exception =
                new NoResourceFoundException(
                        HttpMethod.GET,
                        "/api/v1/missing",
                        "classpath:/static/"
                );

        ResponseEntity<ApiError> response =
                handler.handleNoResourceFound(exception, request);

        assertThat(response.getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).isNotNull();

        ApiError body = response.getBody();

        assertThat(body.status()).isEqualTo(404);
        assertThat(body.error()).isEqualTo("Not Found");
        assertThat(body.code()).isEqualTo("RESOURCE_NOT_FOUND");
        assertThat(body.message())
                .isEqualTo("The requested resource was not found.");
        assertThat(body.path()).isEqualTo("/api/v1/missing");
        assertThat(body.fieldErrors()).isEmpty();
    }
    private static final class ValidationTarget {

        @SuppressWarnings("unused")
        void create(SampleRequest request) {
        }
    }

    private record SampleRequest(String name) {
    }
}
