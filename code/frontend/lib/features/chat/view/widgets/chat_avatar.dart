import 'package:flutter/material.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final avatarColor = switch (initials.isEmpty ? '?' : initials[0]) {
      'N' => const Color(0xFFFF8F84),
      'T' => const Color(0xFF69D2BD),
      'M' => const Color(0xFFF6C85F),
      'R' => const Color(0xFF9AA8FF),
      _ => const Color(0xFF8EC9E8),
    };
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: avatarColor,
      foregroundColor: const Color(0xFF15212A),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(fontSize: size * .31, fontWeight: FontWeight.w700),
      ),
    );
  }
}
