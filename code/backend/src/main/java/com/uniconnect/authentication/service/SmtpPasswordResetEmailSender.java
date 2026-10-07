package com.uniconnect.authentication.service;

import java.net.URI;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

@Component
public class SmtpPasswordResetEmailSender implements PasswordResetEmailSender {
    private final JavaMailSender mailSender;
    private final String from;
    private final String resetUrl;

    public SmtpPasswordResetEmailSender(JavaMailSender mailSender,
            @Value("${uniconnect.password-reset.from}") String from,
            @Value("${uniconnect.password-reset.url}") String resetUrl) {
        URI uri = URI.create(resetUrl);
        if (!("https".equals(uri.getScheme()) || "http".equals(uri.getScheme()))
                || uri.getHost() == null || uri.getFragment() != null || uri.getUserInfo() != null) {
            throw new IllegalArgumentException("Password reset URL must be an absolute HTTP(S) URL without a fragment or credentials");
        }
        this.mailSender = mailSender;
        this.from = from;
        this.resetUrl = resetUrl;
    }

    @Override
    public void send(String email, String rawToken) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(email);
        message.setSubject("Reset your UniConnect password");
        message.setText("Reset your password using this link within one hour:\n"
                + resetUrl + "#token=" + rawToken
                + "\nIf you did not request this, ignore this email.");
        try {
            mailSender.send(message);
        } catch (MailException exception) {
            // Do not propagate mail-provider details containing recipient or message content.
            throw new PasswordResetDeliveryException();
        }
    }

}
