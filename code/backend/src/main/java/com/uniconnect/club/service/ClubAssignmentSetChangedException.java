package com.uniconnect.club.service;

/** Internal retry signal. It must escape the transaction so every acquired lock is released. */
public final class ClubAssignmentSetChangedException extends RuntimeException {}
