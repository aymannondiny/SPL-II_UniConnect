package com.uniconnect.authentication.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

@Component
public class SmtpVerificationEmailSender implements VerificationEmailSender {
    private final JavaMailSender mailSender;
    private final String from;

    public SmtpVerificationEmailSender(JavaMailSender mailSender,
            @Value("${uniconnect.verification.from}") String from) {
        this.mailSender = mailSender;
        this.from = from;
    }

    @Override
    public void send(String email, String code) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(email);
        message.setSubject("Verify your UniConnect email");
        message.setText("Your UniConnect email verification code is: " + code
                + "\nThis code expires in 10 minutes."
                + "\nIf you did not request this, ignore this email.");
        try {
            mailSender.send(message);
        } catch (MailException exception) {
            // Do not propagate mail-provider details containing recipient or message content.
            throw new VerificationDeliveryException();
        }
    }

}
