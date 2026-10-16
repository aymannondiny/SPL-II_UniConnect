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
    required this.token,
    super.key,
  });
  final PasswordRecoveryController controller;
  final String token;

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
    widget.controller.reset(widget.token, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return AutofillGroup(
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthFormHeading(
              badge: 'Account help',
              title: 'Choose a new password',
              subtitle: 'Use a password you haven’t used before.',
            ),
            PasswordField(
              controller: _password,
              enabled: !controller.busy,
              validator: PasswordResetValidation.password,
              error: controller.failure?.fieldErrors['newPassword'],
              onChanged: (_) => controller.clearFailure(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _confirmation,
              enabled: !controller.busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) =>
                  value == _password.text && (value ?? '').isNotEmpty
                  ? null
                  : 'Passwords must match.',
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                hintText: 'Re-enter your new password',
              ),
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
