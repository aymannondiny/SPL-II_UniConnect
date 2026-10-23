package com.uniconnect.project.service;

import com.uniconnect.project.dto.ProjectReportSnapshot;

/** Project-owned report label, owner identity, and reporter-visible evidence. */
public record ProjectReportTarget(String label, long ownerUserId, ProjectReportSnapshot snapshot) {}
