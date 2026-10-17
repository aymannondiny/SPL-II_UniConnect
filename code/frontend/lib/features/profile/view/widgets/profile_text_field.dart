import 'package:flutter/material.dart';

/// Standard text fields with contract-aligned length and required validation.
class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    required this.label,
    required this.controller,
    this.required = false,
    this.limit = 150,
    this.lines = 1,
    this.hint,
    this.validator,
    this.numeric = false,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final bool required;
  final int limit;
  final int lines;
  final String? hint;
  final bool numeric;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: controller,
      maxLength: limit,
      maxLines: lines,
      keyboardType: numeric
          ? TextInputType.number
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Enter $label.';
        }
        return validator?.call(value);
      },
    ),
  );
}
