package com.spl2.uniconnect.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = FutureOrPresentYearValidator.class)
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
public @interface FutureOrPresentYear {

    String message() default "Year must not be in the past";

    int maxYearsAhead() default 10; // How many years ahead is allowed

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}