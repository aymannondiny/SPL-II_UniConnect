import 'package:flutter/material.dart';
import 'package:uniconnect/features/profile/model/personal_profile.dart';
import 'package:uniconnect/features/profile/view/widgets/profile_tags_field.dart';

/// Editable owner fields; preserves optional stored photo URLs on full PUTs.
class ProfileDraft {
  ProfileDraft(String name, PersonalProfile? profile) {
    final initial = profile?.editable ?? {'fullName': name};
    for (final key in keys) {
      final value = initial[key];
      fields[key] = TextEditingController(
        text: value is List ? value.join(', ') : value?.toString() ?? '',
      );
    }
    department = profile?.departmentId;
    programme = profile?.programmeId;
    degree = profile?.degreeId;
    projects = initial['projectAvailability'] == true;
    mentorship = initial['mentorshipAvailability'] == true;
    photoUrl = initial['profilePhotoUrl'] as String?;
  }
  static const keys = [
    'fullName',
    'bio',
    'skills',
    'interests',
    'studentNumber',
    'yearOfStudy',
    'expectedGraduationYear',
    'graduationYear',
    'currentCompany',
    'currentPosition',
    'industry',
    'careerBackground',
    'linkedinUrl',
  ];
  final fields = <String, TextEditingController>{};
  int? department;
  int? programme;
  int? degree;
  bool projects = false;
  bool mentorship = false;
  String? photoUrl;

  Map<String, dynamic> payload(bool alumni) => {
    'fullName': fields['fullName']!.text.trim(),
    'programmeDegreeId': degree,
    'profilePhotoUrl': photoUrl,
    'bio': _optional('bio'),
    'skills': ProfileTagsField.values(fields['skills']!.text),
    'interests': ProfileTagsField.values(fields['interests']!.text),
    if (alumni) ...{
      'graduationYear': int.tryParse(fields['graduationYear']!.text),
      for (final key in [
        'currentCompany',
        'currentPosition',
        'industry',
        'careerBackground',
        'linkedinUrl',
      ])
        key: _optional(key),
    } else ...{
      'studentNumber': fields['studentNumber']!.text.trim().toUpperCase(),
      'yearOfStudy': int.tryParse(fields['yearOfStudy']!.text),
      'expectedGraduationYear': int.tryParse(
        fields['expectedGraduationYear']!.text,
      ),
      'projectAvailability': projects,
      'mentorshipAvailability': mentorship,
    },
  };
  String? _optional(String key) =>
      fields[key]!.text.trim().isEmpty ? null : fields[key]!.text.trim();
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
  }
}
