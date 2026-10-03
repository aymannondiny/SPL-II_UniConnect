package com.uniconnect.authentication.service;

public interface VerificationEmailSender {
    void send(String email, String rawToken);
}
