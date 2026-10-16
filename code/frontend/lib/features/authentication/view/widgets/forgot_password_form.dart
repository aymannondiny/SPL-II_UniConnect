import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/password_recovery_controller.dart';
import 'package:uniconnect/features/authentication/model/login_validation.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_error_notice.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_form_heading.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_submit_button.dart';

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({required this.controller, super.key});
  final PasswordRecoveryController controller;

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.controller.requestLink(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.completed) {
      return Semantics(
        liveRegion: true,
        child: const AuthFormHeading(
          badge: 'Account help',
          title: 'Check your inbox',
          subtitle: 'If this account is eligible, a reset link will be sent. Check your spam folder too.',
        ),
      );
    }
    return Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthFormHeading(
            badge: 'Account help',
            title: 'Reset your password',
            subtitle: "Enter your email and we’ll send you a link to choose a new password.",
          ),
          TextFormField(
            controller: _email,
            enabled: !controller.busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.done,
            validator: LoginValidation.email,
            forceErrorText: controller.failure?.fieldErrors['email'],
            onChanged: (_) => controller.clearFailure(),
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'University email',
              hintText: 'yourid@iut-dhaka.edu',
            ),
          ),
          AuthErrorNotice(message: controller.failure?.message),
          const SizedBox(height: 24),
          AuthSubmitButton(
            label: 'Send reset link',
            busy: controller.busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
