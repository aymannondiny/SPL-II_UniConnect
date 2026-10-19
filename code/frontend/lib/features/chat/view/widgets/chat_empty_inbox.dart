import 'package:flutter/material.dart';

class ChatEmptyInbox extends StatelessWidget {
  const ChatEmptyInbox({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 46,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text('Your inbox is quiet'),
            const SizedBox(height: 4),
            Text(
              'Start a chat with one of your accepted connections.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.add),
              label: const Text('New message'),
            ),
          ],
        ),
      ),
    ),
  );
}
