package com.uniconnect.project.dto;
import jakarta.validation.constraints.AssertTrue;
public record ProjectDeleteRequest(@AssertTrue(message = "Project deletion must be explicitly confirmed.") boolean confirmed) {}
