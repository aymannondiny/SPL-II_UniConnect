import 'confirm_password_field.dart';

import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/registration_controller.dart';
import 'package:uniconnect/features/authentication/model/registration.dart';
import 'package:uniconnect/features/authentication/model/registration_validation.dart';
import 'package:uniconnect/features/authentication/view/widgets/password_field.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({required this.controller, super.key});
  final RegistrationController controller;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  RegistrationRole _role = RegistrationRole.student;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.controller.submit(
      RegistrationRequest(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final errors = controller.failure?.fieldErrors ?? {};
    return AutofillGroup(
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: const Text('JOIN THE COMMUNITY'),
                backgroundColor: Theme.of(context).colorScheme.primary
                    .withValues(alpha: .1),
                side: BorderSide.none,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create your account',
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            const Text('Use your university email to get started.'),
            const SizedBox(height: 28),
            TextFormField(
              controller: _name,
              enabled: !controller.busy,
              autofillHints: const [AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: RegistrationValidation.fullName,
              forceErrorText: errors['fullName'],
              onChanged: (_) => controller.clearFieldError('fullName'),
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'Your full name',
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              enabled: !controller.busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: RegistrationValidation.email,
              forceErrorText: errors['email'],
              onChanged: (_) => controller.clearFieldError('email'),
              decoration: const InputDecoration(
                labelText: 'University email',
                hintText: 'yourid@iut-dhaka.edu',
              ),
            ),
            const SizedBox(height: 20),
            PasswordField(
              controller: _password,
              enabled: !controller.busy,
              error: errors['password'],
              onChanged: (_) => controller.clearFieldError('password'),
            ),
            const SizedBox(height: 20),
            ConfirmPasswordField(
              controller: _confirmation,
              password: _password,
              enabled: !controller.busy,
              onSubmitted: _submit,
            ),
            const SizedBox(height: 24),
            const Text('I am a', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SegmentedButton<RegistrationRole>(
              segments: const [
                ButtonSegment(
                  value: RegistrationRole.student,
                  label: Text('Student'),
                  icon: Icon(Icons.school_outlined),
                ),
                ButtonSegment(
                  value: RegistrationRole.alumni,
                  label: Text('Alumni'),
                  icon: Icon(Icons.work_outline),
                ),
              ],
              selected: {_role},
              onSelectionChanged: controller.busy
                  ? null
                  : (roles) => setState(() => _role = roles.single),
            ),
            if (errors['platformRole'] != null) Text(errors['platformRole']!),
            if (controller.failure != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  controller.failure!.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: controller.busy ? null : _submit,
              child: controller.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Creating account',
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: Text('Create my account')),
                        SizedBox(width: 12),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'By continuing you agree to the community guidelines.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
