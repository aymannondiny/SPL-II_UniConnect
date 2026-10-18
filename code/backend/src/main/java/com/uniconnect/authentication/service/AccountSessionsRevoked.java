package com.uniconnect.authentication.service;

/** Published inside the account transaction and observed only after commit. */
public record AccountSessionsRevoked(long userId) {}
