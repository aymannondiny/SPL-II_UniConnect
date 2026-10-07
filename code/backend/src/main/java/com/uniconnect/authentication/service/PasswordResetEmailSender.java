package com.uniconnect.authentication.service;

public interface PasswordResetEmailSender {
    void send(String email, String rawToken);
}
