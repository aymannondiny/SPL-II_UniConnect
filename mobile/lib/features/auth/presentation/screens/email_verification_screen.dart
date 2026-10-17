import 'dart:async';
import 'package:flutter/material.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  /// Optional backend resend function.
  /// Return true if resend success, false if failed.
  final Future<bool> Function(String email)? onResendEmail;

  /// Optional custom action for login button.
  final VoidCallback? onGoToLogin;

  /// Optional custom action for changing email.
  final VoidCallback? onChangeEmail;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.onResendEmail,
    this.onGoToLogin,
    this.onChangeEmail,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _emailResent = false;
  int _cooldownSeconds = 30;
  Timer? _timer;

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color darkTextColor = Color(0xFF111827);
  static const Color greyTextColor = Color(0xFF6B7280);
  static const Color lightBlueColor = Color(0xFFEFF6FF);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();

    setState(() {
      _cooldownSeconds = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _cooldownSeconds = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cooldownSeconds--;
          });
        }
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _emailResent = false;
    });

    try {
      bool success = true;

      if (widget.onResendEmail != null) {
        success = await widget.onResendEmail!(widget.email);
      } else {
        // Temporary frontend-only behavior.
        // Later you can connect this with backend resend API.
        await Future.delayed(const Duration(seconds: 1));
        success = true;
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _emailResent = true;
        });

        _startCooldown();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent again.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend verification email.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _goToLogin() {
    if (widget.onGoToLogin != null) {
      widget.onGoToLogin!();
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  void _changeEmail() {
    if (widget.onChangeEmail != null) {
      widget.onChangeEmail!();
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool canResend = _cooldownSeconds == 0 && !_isResending;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo / Icon
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: lightBlueColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: primaryColor,
                  size: 46,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: darkTextColor,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'We have sent a verification link to your university email address.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: greyTextColor,
                ),
              ),

              const SizedBox(height: 24),

              // Email Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      color: primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Instruction Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What to do next?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: darkTextColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    _InstructionItem(
                      number: '1',
                      text: 'Open your university email inbox.',
                    ),
                    SizedBox(height: 12),
                    _InstructionItem(
                      number: '2',
                      text: 'Click the verification link sent by UniConnect.',
                    ),
                    SizedBox(height: 12),
                    _InstructionItem(
                      number: '3',
                      text: 'After verification, come back and login.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              if (_emailResent)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF059669),
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A new verification email has been sent.',
                          style: TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Go Login Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _goToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'I have verified, go to login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Resend Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: canResend ? _resendVerificationEmail : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(
                      color: canResend ? primaryColor : borderColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isResending
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                    ),
                  )
                      : Text(
                    _cooldownSeconds > 0
                        ? 'Resend email in $_cooldownSeconds s'
                        : 'Resend verification email',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextButton(
                onPressed: _changeEmail,
                child: const Text(
                  'Wrong email? Change email',
                  style: TextStyle(
                    color: greyTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Did not receive the email? Check your spam or junk folder.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: greyTextColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _EmailVerificationScreenState.lightBlueColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: _EmailVerificationScreenState.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.4,
              color: _EmailVerificationScreenState.darkTextColor,
            ),
          ),
        ),
      ],
    );
  }
}