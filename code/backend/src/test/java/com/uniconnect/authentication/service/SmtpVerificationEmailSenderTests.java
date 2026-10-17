package com.uniconnect.authentication.service;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class SmtpVerificationEmailSenderTests {
    @Test
    void sendsConfiguredLinkWithTokenInFragment() {
        JavaMailSender mail = mock(JavaMailSender.class);
        var sender = new SmtpVerificationEmailSender(mail, "noreply@example.com", "https://example.com/verify-email");
        sender.send("member@iut-dhaka.edu", "opaque-token");
        var message = ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(mail).send(message.capture());
        assertThat(message.getValue().getTo()).containsExactly("member@iut-dhaka.edu");
        assertThat(message.getValue().getText()).contains("https://example.com/verify-email#token=opaque-token", "24 hours");
    }

    @Test
    void sanitizesDeliveryException() {
        JavaMailSender mail = mock(JavaMailSender.class);
        doThrow(new MailSendException("sensitive provider details")).when(mail).send(any(SimpleMailMessage.class));
        var sender = new SmtpVerificationEmailSender(mail, "noreply@example.com", "https://example.com/verify-email");
        assertThatThrownBy(() -> sender.send("member@iut-dhaka.edu", "secret"))
                .isInstanceOf(VerificationDeliveryException.class).hasNoCause()
                .hasMessageNotContaining("sensitive").hasMessageNotContaining("secret");
    }
}
