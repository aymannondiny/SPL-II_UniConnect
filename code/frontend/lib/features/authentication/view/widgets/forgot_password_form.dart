import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/password_recovery_controller.dart';
import 'package:uniconnect/features/authentication/model/login_validation.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_error_notice.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_form_heading.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_submit_button.dart';

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({
    required this.controller,
    required this.onCodeSent,
    super.key,
  });
  final PasswordRecoveryController controller;
  final ValueChanged<String> onCodeSent;

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

  Future<void> _submit() async {
    if (widget.controller.busy || widget.controller.completed) return;
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.controller.requestCode(_email.text);
    if (mounted && widget.controller.completed) {
      widget.onCodeSent(widget.controller.requestedEmail!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthFormHeading(
            badge: 'Step 1 of 3',
            title: 'Reset your password',
            subtitle: "Enter your email and we’ll send you a six-digit code to reset your password.",
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
            label: 'Send verification code',
            busy: controller.busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
