import 'package:flutter/material.dart';

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });
  final String label;
  final bool busy;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: busy || !enabled ? null : onPressed,
      child: busy
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: '$label in progress',
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(label)),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
    );
  }
}
