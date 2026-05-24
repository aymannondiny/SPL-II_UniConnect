package com.spl2.uniconnect.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = PastOrPresentYearValidator.class)
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
public @interface PastOrPresentYear {

    String message() default "Year must not be in the future";

    int minYearsBack() default 200; // How far back is allowed

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}