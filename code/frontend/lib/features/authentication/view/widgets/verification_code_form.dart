import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/email_verification_controller.dart';
import 'package:uniconnect/features/authentication/model/verification_validation.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_error_notice.dart';
import 'package:uniconnect/features/authentication/view/widgets/verification_code_field.dart';

class VerificationCodeForm extends StatefulWidget {
  const VerificationCodeForm({
    required this.controller,
    required this.email,
    super.key,
  });

  final EmailVerificationController controller;
  final String email;

  @override
  State<VerificationCodeForm> createState() => _VerificationCodeFormState();
}

class _VerificationCodeFormState extends State<VerificationCodeForm> {
  final _form = GlobalKey<FormState>();
  final _emailField = GlobalKey<FormFieldState<String>>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    if (widget.controller.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.controller.verify(_email.text, _code.text);
  }

  void _resend() {
    if (widget.controller.busy || !_emailField.currentState!.validate()) return;
    widget.controller.resend(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AutofillGroup(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Check your email',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Check your inbox and enter the six-digit verification code to complete signup. '
              'Codes expire 10 minutes after they are sent.',
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: _emailField,
              controller: _email,
              enabled: !controller.busy,
              validator: VerificationValidation.email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'University email',
                hintText: 'you@iut-dhaka.edu',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 20),
            VerificationCodeField(
              controller: _code,
              enabled: !controller.busy,
              onSubmit: _verify,
            ),
            const SizedBox(height: 12),
            const Text(
              'Use the latest code. After five incorrect attempts, '
              'request a replacement.',
            ),
            AuthErrorNotice(message: controller.error),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: controller.busy ? null : _verify,
              child: Text(controller.verifying ? 'Verifying…' : 'Verify email'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: controller.busy ? null : _resend,
              child: Text(controller.resending ? 'Requesting…' : 'Resend code'),
            ),
            const SizedBox(height: 12),
            const Text(
              'No code? Check spam, or request another. Allow at least '
              '60 seconds between requests; up to five codes per hour.',
            ),
            if (controller.resendNotice != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(controller.resendNotice!),
              ),
            ],
            AuthErrorNotice(message: controller.resendError),
          ],
        ),
      ),
    );
  }
}
