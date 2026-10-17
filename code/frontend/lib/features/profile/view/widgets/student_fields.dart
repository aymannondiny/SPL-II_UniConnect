import 'package:flutter/material.dart';
import 'package:uniconnect/features/profile/view/widgets/profile_text_field.dart';

class StudentFields extends StatelessWidget {
  const StudentFields({
    required this.fields,
    required this.minimumYear,
    required this.maximumYear,
    super.key,
  });
  final Map<String, TextEditingController> fields;
  final int minimumYear;
  final int maximumYear;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ProfileTextField(
        label: 'Student number',
        controller: fields['studentNumber']!,
        required: true,
        limit: 40,
        validator: (v) =>
            RegExp(r'^[A-Za-z0-9-]{1,40}$').hasMatch(v?.trim() ?? '')
            ? null
            : 'Use letters, numbers, or hyphens.',
      ),
      ProfileTextField(
        label: 'Year of study',
        controller: fields['yearOfStudy']!,
        required: true,
        limit: 2,
        numeric: true,
        validator: (v) {
          final year = int.tryParse(v ?? '');
          return year == null || year < minimumYear || year > maximumYear
              ? 'Enter a year from $minimumYear to $maximumYear.'
              : null;
        },
      ),
      ProfileTextField(
        label: 'Expected graduation year',
        controller: fields['expectedGraduationYear']!,
        limit: 4,
        numeric: true,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final year = int.tryParse(v);
          return year == null ||
                  year < DateTime.now().toUtc().year ||
                  year > 2200
              ? 'Enter a year from ${DateTime.now().toUtc().year} to 2200.'
              : null;
        },
      ),
    ],
  );
}
