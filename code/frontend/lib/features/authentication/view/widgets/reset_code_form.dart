import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/controller/password_recovery_controller.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_error_notice.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_form_heading.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_submit_button.dart';
import 'package:uniconnect/features/authentication/view/widgets/six_digit_code_field.dart';

class ResetCodeForm extends StatefulWidget {
  const ResetCodeForm({
    required this.controller,
    required this.email,
    required this.onVerified,
    super.key,
  });

  final PasswordRecoveryController controller;
  final String email;
  final ValueChanged<String> onVerified;

  @override
  State<ResetCodeForm> createState() => _ResetCodeFormState();
}

class _ResetCodeFormState extends State<ResetCodeForm> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  String? _notice;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.controller.completed) return;
    if (!_form.currentState!.validate() || widget.controller.busy) return;
    FocusScope.of(context).unfocus();
    await widget.controller.verifyCode(widget.email, _code.text);
    if (mounted && widget.controller.completed) widget.onVerified(_code.text);
  }

  Future<void> _resend() async {
    await widget.controller.resendCode(widget.email);
    if (!mounted || widget.controller.failure != null) return;
    setState(
      () => _notice = 'If this account is eligible, a new code will be sent.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthFormHeading(
            badge: 'Step 2 of 3',
            title: 'Enter verification code',
            subtitle: 'If this account is eligible, a six-digit code will be sent. Check your spam folder too.',
          ),
          Text(widget.email, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SixDigitCodeField(
            controller: _code,
            enabled: !controller.busy,
            onSubmit: _submit,
            onChanged: controller.clearFailure,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your code expires after 10 minutes. Five incorrect attempts require a new code.',
          ),
          AuthErrorNotice(message: controller.failure?.message),
          if (_notice != null)
            Semantics(liveRegion: true, child: Text(_notice!)),
          const SizedBox(height: 24),
          AuthSubmitButton(
            label: 'Verify code',
            busy: controller.busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: controller.busy ? null : _resend,
            child: const Text('Resend code'),
          ),
          const Text(
            'Wait 60 seconds between requests. Up to five codes per hour.',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: controller.busy
                ? null
                : () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.forgotPassword,
                  ),
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }
}
