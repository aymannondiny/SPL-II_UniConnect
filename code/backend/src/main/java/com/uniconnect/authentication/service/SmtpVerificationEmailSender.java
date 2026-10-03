package com.uniconnect.authentication.service;

import java.net.URI;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

@Component
public class SmtpVerificationEmailSender implements VerificationEmailSender {
    private final JavaMailSender mailSender;
    private final String from;
    private final String verificationUrl;

    public SmtpVerificationEmailSender(JavaMailSender mailSender,
            @Value("${uniconnect.verification.from}") String from,
            @Value("${uniconnect.verification.url}") String verificationUrl) {
        URI uri = URI.create(verificationUrl);
        if (!("https".equals(uri.getScheme()) || "http".equals(uri.getScheme()))
                || uri.getHost() == null || uri.getFragment() != null || uri.getUserInfo() != null) {
            throw new IllegalArgumentException("Verification URL must be an absolute HTTP(S) URL without a fragment or credentials");
        }
        this.mailSender = mailSender;
        this.from = from;
        this.verificationUrl = verificationUrl;
    }

    @Override
    public void send(String email, String rawToken) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(email);
        message.setSubject("Verify your UniConnect email");
        message.setText("Confirm your email using this link within 24 hours:\n"
                + verificationUrl + "#token=" + rawToken
                + "\nIf you did not request this, ignore this email.");
        try {
            mailSender.send(message);
        } catch (MailException exception) {
            // Do not propagate mail-provider details containing recipient or message content.
            throw new VerificationDeliveryException();
        }
    }

}
