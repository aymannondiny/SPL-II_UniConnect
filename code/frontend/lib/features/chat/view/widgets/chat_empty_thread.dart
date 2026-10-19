import 'package:flutter/material.dart';

import 'chat_avatar.dart';

class ChatEmptyThread extends StatelessWidget {
  const ChatEmptyThread({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatAvatar(name: name, size: 70),
            const SizedBox(height: 14),
            Text(
              'Say hello to $name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Your first message will start this conversation.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
