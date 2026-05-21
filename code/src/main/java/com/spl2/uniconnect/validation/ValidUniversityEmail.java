package com.spl2.uniconnect.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = UniversityEmailValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidUniversityEmail {

    String message() default "Only IUT email addresses (@iut-dhaka.edu) are allowed";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
