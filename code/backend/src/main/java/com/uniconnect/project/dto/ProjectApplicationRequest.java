package com.uniconnect.project.dto;
import jakarta.validation.constraints.Size;
public record ProjectApplicationRequest(@Size(max = 500) String message) {}
