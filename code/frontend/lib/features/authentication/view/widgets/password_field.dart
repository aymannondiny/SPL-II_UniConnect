import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/registration_validation.dart';
import 'package:uniconnect/features/authentication/view/widgets/password_strength_indicator.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.error,
    this.validator,
    super.key,
  });
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final String? error;
  final FormFieldValidator<String>? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _hidden,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.newPassword],
          validator: widget.validator ?? RegistrationValidation.password,
          forceErrorText: widget.error,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'At least 8 characters',
            suffixIcon: IconButton(
              tooltip: _hidden ? 'Show password' : 'Hide password',
              onPressed: widget.enabled
                  ? () => setState(() => _hidden = !_hidden)
                  : null,
              icon: Icon(
                _hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        PasswordStrengthIndicator(controller: widget.controller),
      ],
    );
  }
}
