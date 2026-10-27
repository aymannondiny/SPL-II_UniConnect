import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uniconnect/features/authentication/model/verification_validation.dart';

class SixDigitCodeField extends StatefulWidget {
  const SixDigitCodeField({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;
  final VoidCallback? onChanged;

  @override
  State<SixDigitCodeField> createState() => _SixDigitCodeFieldState();
}

class _SixDigitCodeFieldState extends State<SixDigitCodeField> {
  final _digits = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final digit in _digits) {
      digit.dispose();
    }
    for (final focus in _focus) {
      focus.dispose();
    }
    super.dispose();
  }

  void _changed(int index, String value, FormFieldState<String> field) {
    if (value.length > 1) {
      final start = value.length == 6 ? 0 : index;
      for (
        var offset = 0;
        offset < value.length && start + offset < 6;
        offset++
      ) {
        _digits[start + offset].text = value[offset];
      }
      _focus[(start + value.length).clamp(0, 5)].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _focus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
    widget.controller.text = _digits.map((digit) => digit.text).join();
    field.didChange(widget.controller.text);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: '',
      validator: (_) => VerificationValidation.code(widget.controller.text),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              6,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 5 ? 0 : 6),
                  child: Focus(
                    onKeyEvent: (_, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.backspace &&
                          _digits[index].text.isEmpty &&
                          index > 0) {
                        _focus[index - 1].requestFocus();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Semantics(
                      label: 'Verification code digit ${index + 1} of 6',
                      child: TextField(
                        key: ValueKey('reset-code-digit-$index'),
                        controller: _digits[index],
                        focusNode: _focus[index],
                        enabled: widget.enabled,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                        keyboardType: TextInputType.number,
                        autofillHints: index == 0
                            ? const [AutofillHints.oneTimeCode]
                            : null,
                        textInputAction: index == 5
                            ? TextInputAction.done
                            : TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (value) => _changed(index, value, field),
                        onSubmitted: (_) => index == 5
                            ? widget.onSubmit()
                            : _focus[index + 1].requestFocus(),
                        decoration: InputDecoration(
                          hintText: '–',
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
