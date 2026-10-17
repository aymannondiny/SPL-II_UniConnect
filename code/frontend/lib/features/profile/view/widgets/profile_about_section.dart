import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/profile/view/profile_draft.dart';
import 'package:uniconnect/features/profile/view/widgets/profile_text_field.dart';
import 'package:uniconnect/features/profile/view/widgets/profile_tags_field.dart';

class ProfileAboutSection extends StatelessWidget {
  const ProfileAboutSection({required this.draft, super.key});
  final ProfileDraft draft;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'About you',
    subtitle: 'A few details to help your community find you.',
    child: Column(
      children: [
        ProfileTextField(
          label: 'Full name',
          controller: draft.fields['fullName']!,
          required: true,
          limit: 100,
        ),
        ProfileTextField(
          label: 'Short bio',
          controller: draft.fields['bio']!,
          limit: 2000,
          lines: 3,
          hint: 'What are you interested in?',
        ),
        ProfileTagsField(label: 'Skills', controller: draft.fields['skills']!),
        ProfileTagsField(
          label: 'Interests',
          controller: draft.fields['interests']!,
        ),
      ],
    ),
  );
}
