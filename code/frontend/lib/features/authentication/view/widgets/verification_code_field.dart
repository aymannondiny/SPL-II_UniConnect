import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uniconnect/features/authentication/model/verification_validation.dart';

class VerificationCodeField extends StatelessWidget {
  const VerificationCodeField({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('verification-code'),
      controller: controller,
      enabled: enabled,
      validator: VerificationValidation.code,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      onFieldSubmitted: (_) => onSubmit(),
      decoration: const InputDecoration(
        labelText: 'Verification code',
        hintText: '012345',
        prefixIcon: Icon(Icons.pin_outlined),
      ),
    );
  }
}
