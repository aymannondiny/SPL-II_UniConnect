import 'confirm_password_field.dart';

import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/password_recovery_controller.dart';
import 'package:uniconnect/features/authentication/model/password_reset_validation.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_error_notice.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_form_heading.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_submit_button.dart';
import 'package:uniconnect/features/authentication/view/widgets/password_field.dart';

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({
    required this.controller,
    required this.email,
    required this.code,
    super.key,
  });
  final PasswordRecoveryController controller;
  final String email;
  final String code;

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.controller.reset(widget.email, widget.code, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AutofillGroup(
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthFormHeading(
              badge: 'Step 3 of 3',
              title: 'Choose a new password',
              subtitle: 'Your code has been verified. Choose a new password.',
            ),
            PasswordField(
              controller: _password,
              enabled: !controller.busy,
              validator: PasswordResetValidation.password,
              error: controller.failure?.fieldErrors['newPassword'],
              onChanged: (_) => controller.clearFailure(),
            ),
            const SizedBox(height: 20),
            ConfirmPasswordField(
              controller: _confirmation,
              password: _password,
              enabled: !controller.busy,
              onSubmitted: _submit,
            ),
            AuthErrorNotice(message: controller.failure?.message),
            const SizedBox(height: 24),
            AuthSubmitButton(
              label: 'Update password',
              busy: controller.busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
