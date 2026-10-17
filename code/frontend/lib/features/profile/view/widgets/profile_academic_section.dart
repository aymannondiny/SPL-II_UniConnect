import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/profile/model/academic_catalog.dart';
import 'package:uniconnect/features/profile/view/profile_draft.dart';
import 'package:uniconnect/features/profile/view/widgets/academic_fields.dart';
import 'package:uniconnect/features/profile/view/widgets/alumni_fields.dart';
import 'package:uniconnect/features/profile/view/widgets/student_fields.dart';

class ProfileAcademicSection extends StatelessWidget {
  const ProfileAcademicSection({
    required this.draft,
    required this.catalog,
    required this.alumni,
    required this.onChanged,
    required this.onReload,
    super.key,
  });
  final ProfileDraft draft;
  final AcademicCatalog catalog;
  final bool alumni;
  final VoidCallback onChanged;
  final VoidCallback onReload;
  @override
  Widget build(BuildContext context) {
    final degree = catalog.degrees
        .where((d) => d.id == draft.degree)
        .firstOrNull;
    return SectionCard(
      title: alumni ? 'Education and career' : 'Your academic details',
      child: Column(
        children: [
          if (catalog.degrees.isEmpty) ...[
            const Text(
              'Academic options are not available yet. An administrator needs to add departments, programmes and degrees before you can finish setup.',
            ),
            TextButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload academic options'),
            ),
          ] else ...[
            AcademicFields(
              catalog: catalog,
              department: draft.department,
              programme: draft.programme,
              degree: draft.degree,
              onDepartment: (v) {
                draft.department = v;
                draft.programme = null;
                _degreeChanged(null);
              },
              onProgramme: (v) {
                draft.programme = v;
                _degreeChanged(null);
              },
              onDegree: _degreeChanged,
            ),
            if (alumni)
              AlumniFields(fields: draft.fields)
            else
              StudentFields(
                fields: draft.fields,
                minimumYear: degree?.minimumYear ?? 1,
                maximumYear: degree?.maximumYear ?? 20,
              ),
          ],
        ],
      ),
    );
  }

  void _degreeChanged(int? value) {
    draft.degree = value;
    draft.fields['yearOfStudy']!.clear();
    onChanged();
  }
}
