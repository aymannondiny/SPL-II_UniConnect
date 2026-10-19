package com.uniconnect.career.dto;

import jakarta.validation.constraints.Size;

public record UpdateSavedNoteRequest(@Size(max = 1000) String note) {}
