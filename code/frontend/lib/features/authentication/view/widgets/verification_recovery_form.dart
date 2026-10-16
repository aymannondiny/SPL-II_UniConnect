import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/controller/email_verification_controller.dart';
import 'package:uniconnect/features/authentication/model/registration_validation.dart';

class VerificationRecoveryForm extends StatefulWidget {
  const VerificationRecoveryForm({required this.controller, super.key});

  final EmailVerificationController controller;

  @override
  State<VerificationRecoveryForm> createState() =>
      _VerificationRecoveryFormState();
}

class _VerificationRecoveryFormState extends State<VerificationRecoveryForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.controller.resend(_email.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 40),
          Text(
            'Need a new link?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            enabled: !controller.resending,
            validator: RegistrationValidation.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'IUT email',
              hintText: 'you@iut-dhaka.edu',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: controller.resending ? null : _submit,
            child: Text(
              controller.resending ? 'Requesting…' : 'Send a new link',
            ),
          ),
          if (controller.resendNotice != null || controller.resendError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(controller.resendNotice ?? controller.resendError!),
              ),
            ),
        ],
      ),
    );
  }
}
