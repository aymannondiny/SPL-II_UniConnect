import 'package:flutter/material.dart';

/// Comma-separated editing with a live preview of the canonical vocabulary.
class ProfileTagsField extends StatelessWidget {
  const ProfileTagsField({
    required this.label,
    required this.controller,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  static List<String> values(String text) => text
      .split(',')
      .map((s) => s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            helperText: 'Separate with commas. Up to 30 items.',
          ),
          validator: (text) {
            final entries = (text ?? '')
                .split(',')
                .where((s) => s.trim().isNotEmpty)
                .toList();
            if (entries.length > 30) return 'Use at most 30 items.';
            if (entries.any((s) => s.trim().length > 60)) {
              return 'Keep each item within 60 characters.';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, value, _) => Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final tag in values(value.text)) Chip(label: Text(tag)),
            ],
          ),
        ),
      ],
    ),
  );
}
