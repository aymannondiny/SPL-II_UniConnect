import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';

import '../../model/connection_models.dart';

/// Renders only fields permitted in the public member contract.
class MemberProfileDetails extends StatelessWidget {
  const MemberProfileDetails({required this.member, super.key});
  final MemberProfile member;

  @override
  Widget build(BuildContext context) {
    if (!member.detailsVisible || member.details == null) {
      return const SectionCard(
        title: 'Private profile details',
        child: Text(
          'This member shares their details with connections only. Connect to learn more.',
        ),
      );
    }
    final details = member.details!;
    final alumni = details['alumni'] as Map<String, dynamic>?;
    final student = details['student'] as Map<String, dynamic>?;
    final facts = <String, Object?>{
      'Year of study': student?['yearOfStudy'],
      'Expected graduation': student?['expectedGraduationYear'],
      'Graduation year': alumni?['graduationYear'],
      'Company': alumni?['currentCompany'],
      'Position': alumni?['currentPosition'],
      'Industry': alumni?['industry'],
      'Career background': alumni?['careerBackground'],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'About',
          child: Text(
            (details['bio'] as String?)?.trim().isNotEmpty == true
                ? details['bio'] as String
                : 'No introduction added yet.',
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Skills & interests',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tags(context, 'Skills', details['skills']),
              const SizedBox(height: 12),
              _tags(context, 'Interests', details['interests']),
              if ((details['sharedSkills'] as List<dynamic>?)?.isNotEmpty ==
                  true) ...[
                const SizedBox(height: 12),
                _tags(context, 'Skills in common', details['sharedSkills']),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: alumni == null ? 'Academic details' : 'Professional details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in facts.entries)
                if (entry.value != null && '${entry.value}'.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
              if (student?['projectAvailability'] is bool)
                Text(
                  student!['projectAvailability'] == true
                      ? 'Open to projects'
                      : 'Not currently seeking projects',
                ),
              if (student?['mentorshipAvailability'] is bool)
                Text(
                  student!['mentorshipAvailability'] == true
                      ? 'Open to mentorship'
                      : 'Not currently seeking mentorship',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tags(BuildContext context, String label, Object? value) {
    final values = (value as List<dynamic>?)?.cast<String>() ?? <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        if (values.isEmpty)
          const Text('None added yet.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [for (final value in values) Chip(label: Text(value))],
          ),
      ],
    );
  }
}
