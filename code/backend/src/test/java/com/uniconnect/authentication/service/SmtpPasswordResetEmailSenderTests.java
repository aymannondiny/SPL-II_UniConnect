package com.uniconnect.authentication.service;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class SmtpPasswordResetEmailSenderTests {
    @Test
    void sendsSixDigitCodeWithoutLink() {
        JavaMailSender mail = mock(JavaMailSender.class);
        var sender = new SmtpPasswordResetEmailSender(mail, "noreply@example.com");
        sender.send("member@iut-dhaka.edu", "012345");
        var message = ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(mail).send(message.capture());
        assertThat(message.getValue().getTo()).containsExactly("member@iut-dhaka.edu");
        assertThat(message.getValue().getText()).contains("012345", "10 minutes").doesNotContain("http", "#token=");
    }

    @Test
    void sanitizesDeliveryException() {
        JavaMailSender mail = mock(JavaMailSender.class);
        doThrow(new MailSendException("sensitive provider details")).when(mail).send(any(SimpleMailMessage.class));
        var sender = new SmtpPasswordResetEmailSender(mail, "noreply@example.com");
        assertThatThrownBy(() -> sender.send("member@iut-dhaka.edu", "secret"))
                .isInstanceOf(PasswordResetDeliveryException.class).hasNoCause()
                .hasMessageNotContaining("sensitive").hasMessageNotContaining("secret");
    }
}
