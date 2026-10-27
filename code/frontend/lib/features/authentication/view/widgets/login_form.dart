import 'package:flutter/material.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/login_validation.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_error_notice.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_form_heading.dart';
import 'package:uniconnect/features/authentication/view/widgets/auth_submit_button.dart';
import 'package:uniconnect/features/authentication/view/widgets/login_password_field.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({required this.controller, super.key});
  final SessionController controller;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.controller.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.controller.login(_email.text, _password.text);
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
              badge: 'Welcome back',
              title: 'Log in to UniConnect',
              subtitle: 'Pick up where you left off.',
            ),
            TextFormField(
              controller: _email,
              enabled: !controller.busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: LoginValidation.email,
              forceErrorText: controller.failure?.fieldErrors['email'],
              onChanged: (_) => controller.clearFailure(),
              decoration: const InputDecoration(
                labelText: 'University email',
                hintText: 'yourid@iut-dhaka.edu',
              ),
            ),
            const SizedBox(height: 20),
            LoginPasswordField(
              controller: _password,
              enabled: !controller.busy,
              error: controller.failure?.fieldErrors['password'],
              onChanged: (_) => controller.clearFailure(),
              onSubmit: _submit,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: controller.busy
                    ? null
                    : () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.forgotPassword,
                      ),
                child: const Text('Forgot password?'),
              ),
            ),
            AuthErrorNotice(message: controller.failure?.message),
            const SizedBox(height: 24),
            AuthSubmitButton(
              label: 'Log in',
              busy: controller.busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('New here?'),
                TextButton(
                  onPressed: controller.busy
                      ? null
                      : () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.signUp,
                        ),
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
