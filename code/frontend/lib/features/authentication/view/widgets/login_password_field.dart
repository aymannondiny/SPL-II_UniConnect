import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/login_validation.dart';

/// Existing-password input intentionally omits registration strength guidance.
class LoginPasswordField extends StatefulWidget {
  const LoginPasswordField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSubmit,
    this.error,
    super.key,
  });
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final String? error;

  @override
  State<LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<LoginPasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _hidden,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      validator: LoginValidation.password,
      forceErrorText: widget.error,
      onChanged: widget.onChanged,
      onFieldSubmitted: (_) => widget.onSubmit(),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Your password',
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Show password' : 'Hide password',
          onPressed: widget.enabled
              ? () => setState(() => _hidden = !_hidden)
              : null,
          icon: Icon(
            _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}
