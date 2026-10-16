import 'package:flutter/material.dart';

/// Shared handoff until the separate login frontend is implemented.
void showLoginNotice(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Login screen coming next'),
      content: const Text(
        'The login screen is not available yet. If your email is verified, '
        'your account is ready to log in when that screen is available.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
