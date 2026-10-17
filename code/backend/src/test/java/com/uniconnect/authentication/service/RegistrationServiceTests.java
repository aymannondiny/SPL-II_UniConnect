package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.exception.ConflictException;
import com.uniconnect.shared.security.AccountStatus;
import com.uniconnect.shared.security.PlatformRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class RegistrationServiceTests {

    private UserRepository userRepository;
    private PasswordEncoder passwordEncoder;
    private RegistrationService registrationService;
    private EmailVerificationService verificationService;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        passwordEncoder = mock(PasswordEncoder.class);
        verificationService = mock(EmailVerificationService.class);

        registrationService = new RegistrationService(
                userRepository,
                passwordEncoder,
                verificationService
        );
    }

    @Test
    void registersUserWithEncodedPasswordAndPendingVerificationStatus() {
        when(userRepository.existsByEmail("ayman@iut-dhaka.edu"))
                .thenReturn(false);

        when(passwordEncoder.encode("plain-password"))
                .thenReturn("encoded-password");

        when(userRepository.save(any(User.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        User result = registrationService.register(
                "Ayman",
                "ayman@iut-dhaka.edu",
                "plain-password",
                PlatformRole.STUDENT
        );

        assertThat(result.getEmail()).isEqualTo("ayman@iut-dhaka.edu");
        assertThat(result.getPasswordHash()).isEqualTo("encoded-password");
        assertThat(result.getPlatformRole()).isEqualTo(PlatformRole.STUDENT);
        assertThat(result.getAccountStatus())
                .isEqualTo(AccountStatus.PENDING_VERIFICATION);

        verify(verificationService).issueForRegistration(result);
        verify(passwordEncoder).encode("plain-password");
        verify(userRepository).save(any(User.class));
    }

    @Test
    void rejectsDuplicateEmailBeforeEncodingOrSaving() {
        when(userRepository.existsByEmail("duplicate@iut-dhaka.edu"))
                .thenReturn(true);

        assertThatThrownBy(() -> registrationService.register(
                "Ayman",
                "duplicate@iut-dhaka.edu",
                "plain-password",
                PlatformRole.STUDENT
        ))
                .isInstanceOf(ConflictException.class);

        verify(passwordEncoder, never()).encode(anyString());
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void plaintextPasswordIsNeverPassedToPersistence() {
        when(userRepository.existsByEmail("ayman@iut-dhaka.edu"))
                .thenReturn(false);

        when(passwordEncoder.encode("plain-password"))
                .thenReturn("encoded-password");

        when(userRepository.save(any(User.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        registrationService.register(
                "Ayman",
                "ayman@iut-dhaka.edu",
                "plain-password",
                PlatformRole.STUDENT
        );

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);

        verify(userRepository).save(captor.capture());

        User savedUser = captor.getValue();

        assertThat(savedUser.getPasswordHash())
                .isEqualTo("encoded-password");

        assertThat(savedUser.getPasswordHash())
                .isNotEqualTo("plain-password");
    }

    @Test
    void rejectsSystemAdminRegistration() {
        assertThatThrownBy(() -> registrationService.register(
                "Admin",
                "admin@iut-dhaka.edu",
                "plain-password",
                PlatformRole.SYSTEM_ADMIN
        ))
                .isInstanceOf(BadRequestException.class);

        verifyNoInteractions(passwordEncoder);
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void normalizesEmailBeforeDuplicateCheckAndPersistence() {
        when(userRepository.existsByEmail("ayman@iut-dhaka.edu"))
                .thenReturn(false);

        when(passwordEncoder.encode("plain-password"))
                .thenReturn("encoded-password");

        when(userRepository.save(any(User.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        User result = registrationService.register(
                "Ayman",
                "  AYMAN@IUT-DHAKA.EDU  ",
                "plain-password",
                PlatformRole.STUDENT
        );

        assertThat(result.getEmail()).isEqualTo("ayman@iut-dhaka.edu");

        verify(userRepository)
                .existsByEmail("ayman@iut-dhaka.edu");
    }

    @Test
    void rejectsNonIutEmailAddress() {
        assertThatThrownBy(() -> registrationService.register(
                "Ayman",
                "ayman@gmail.com",
                "plain-password",
                PlatformRole.STUDENT
        ))
                .isInstanceOf(BadRequestException.class);

        verifyNoInteractions(passwordEncoder);
        verify(userRepository, never()).save(any(User.class));
    }
}
