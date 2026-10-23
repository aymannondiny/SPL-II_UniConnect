package com.uniconnect.career.service;

import com.uniconnect.career.dto.CareerPostReportSnapshot;

/** Career-owned report label, owner identity, and reporter-visible evidence. */
public record CareerPostReportTarget(String label, long ownerUserId, CareerPostReportSnapshot snapshot) {}
