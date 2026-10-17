import 'package:flutter/material.dart';
import 'package:uniconnect/features/profile/view/widgets/profile_text_field.dart';

class AlumniFields extends StatelessWidget {
  const AlumniFields({required this.fields, super.key});
  final Map<String, TextEditingController> fields;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ProfileTextField(
        label: 'Graduation year',
        controller: fields['graduationYear']!,
        required: true,
        limit: 4,
        numeric: true,
        validator: (v) {
          final year = int.tryParse(v ?? '');
          return year == null ||
                  year < 1900 ||
                  year > DateTime.now().toUtc().year
              ? 'Enter a year from 1900 to ${DateTime.now().toUtc().year}.'
              : null;
        },
      ),
      ProfileTextField(
        label: 'Current company',
        controller: fields['currentCompany']!,
      ),
      ProfileTextField(
        label: 'Current position',
        controller: fields['currentPosition']!,
      ),
      ProfileTextField(
        label: 'Industry',
        controller: fields['industry']!,
        limit: 100,
      ),
      ProfileTextField(
        label: 'Career background',
        controller: fields['careerBackground']!,
        limit: 2000,
        lines: 3,
      ),
      ProfileTextField(
        label: 'LinkedIn URL',
        controller: fields['linkedinUrl']!,
        limit: 2048,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final uri = Uri.tryParse(v.trim());
          return uri != null &&
                  ['https', 'http'].contains(uri.scheme) &&
                  uri.userInfo.isEmpty &&
                  (uri.host == 'linkedin.com' ||
                      uri.host.endsWith('.linkedin.com'))
              ? null
              : 'Enter a valid linkedin.com URL.';
        },
      ),
    ],
  );
}
