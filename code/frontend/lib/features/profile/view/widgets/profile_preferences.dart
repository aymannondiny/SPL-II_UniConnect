import 'package:flutter/material.dart';

class ProfilePreferences extends StatelessWidget {
  const ProfilePreferences({
    required this.student,
    required this.projects,
    required this.mentorship,
    required this.visibility,
    required this.onProjects,
    required this.onMentorship,
    required this.onVisibility,
    super.key,
  });
  final bool student;
  final bool projects;
  final bool mentorship;
  final String visibility;
  final ValueChanged<bool> onProjects;
  final ValueChanged<bool> onMentorship;
  final ValueChanged<String> onVisibility;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (student) ...[
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Open to projects'),
          subtitle: const Text('Share your interest in finding teammates.'),
          value: projects,
          onChanged: onProjects,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Open to mentorship'),
          subtitle: const Text('Save your mentorship availability.'),
          value: mentorship,
          onChanged: onMentorship,
        ),
        const SizedBox(height: 16),
      ],
      DropdownButtonFormField<String>(
        initialValue: visibility,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Who can see my details'),
        items: const [
          DropdownMenuItem(
            value: 'CONNECTIONS_ONLY',
            child: Text('Connections only'),
          ),
          DropdownMenuItem(value: 'ALL_MEMBERS', child: Text('All members')),
        ],
        onChanged: (value) {
          if (value != null) onVisibility(value);
        },
      ),
      const SizedBox(height: 12),
      const Text(
        'Members can discover your name, role, photo and academic programme. Your email and student number stay private.',
      ),
    ],
  );
}
