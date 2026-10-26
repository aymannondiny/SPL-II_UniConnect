import 'package:flutter/material.dart';

/// Confirms a new secret locally; confirmation is never sent to the API.
class ConfirmPasswordField extends StatefulWidget {
  const ConfirmPasswordField({
    required this.controller,
    required this.password,
    required this.enabled,
    this.onSubmitted,
    super.key,
  });
  final TextEditingController controller;
  final TextEditingController password;
  final bool enabled;
  final VoidCallback? onSubmitted;

  @override
  State<ConfirmPasswordField> createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<ConfirmPasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.password,
        builder: (context, _, _) => TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _hidden,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.newPassword],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          validator: (value) => (value ?? '').isEmpty
              ? 'Confirm your password.'
              : value != widget.password.text
              ? 'Passwords must match.'
              : null,
          decoration: InputDecoration(
            labelText: 'Confirm password',
            hintText: 'Re-enter your password',
            errorMaxLines: 2,
            suffixIcon: IconButton(
              tooltip: _hidden ? 'Show confirmation' : 'Hide confirmation',
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
      );
}
