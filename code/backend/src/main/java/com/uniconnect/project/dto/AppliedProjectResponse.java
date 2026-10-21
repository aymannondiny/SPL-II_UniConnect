package com.uniconnect.project.dto;

/** The project is null after its owner soft-deletes the listing. */
public record AppliedProjectResponse(ProjectResponse project, ProjectApplicationResponse application) {}
