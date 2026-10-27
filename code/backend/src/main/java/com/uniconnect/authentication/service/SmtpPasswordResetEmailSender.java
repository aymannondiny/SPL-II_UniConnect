package com.uniconnect.authentication.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

@Component
public class SmtpPasswordResetEmailSender implements PasswordResetEmailSender {
    private final JavaMailSender mailSender;
    private final String from;

    public SmtpPasswordResetEmailSender(JavaMailSender mailSender,
            @Value("${uniconnect.password-reset.from}") String from) {
        this.mailSender = mailSender;
        this.from = from;
    }

    @Override
    public void send(String email, String code) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(email);
        message.setSubject("Reset your UniConnect password");
        message.setText("Your UniConnect password reset code is: " + code
                + "\nEnter this six-digit code with your email and new password within 10 minutes."
                + "\nIf you did not request this, ignore this email.");
        try {
            mailSender.send(message);
        } catch (MailException exception) {
            // Do not propagate mail-provider details containing recipient or message content.
            throw new PasswordResetDeliveryException();
        }
    }

}
