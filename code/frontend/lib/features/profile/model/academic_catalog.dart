import 'package:uniconnect/features/profile/model/personal_profile.dart';

/// Immutable academic choices supplied by the administrator-managed catalog.
class AcademicOption {
  const AcademicOption({
    required this.id,
    required this.label,
    this.parentId,
    this.minimumYear = 1,
    this.maximumYear = 20,
  });
  final int id;
  final String label;
  final int? parentId;
  final int minimumYear;
  final int maximumYear;
}

class AcademicCatalog {
  const AcademicCatalog({
    required this.departments,
    required this.programmes,
    required this.degrees,
  });
  final List<AcademicOption> departments;
  final List<AcademicOption> programmes;
  final List<AcademicOption> degrees;

  factory AcademicCatalog.fromJson(Map<String, dynamic> json) =>
      AcademicCatalog(
        departments: [
          for (final item in json['departments'] as List)
            AcademicOption(
              id: item['id'] as int,
              label: item['name'] as String,
            ),
        ],
        programmes: [
          for (final item in json['programmes'] as List)
            AcademicOption(
              id: item['id'] as int,
              label: item['name'] as String,
              parentId: item['departmentId'] as int,
            ),
        ],
        degrees: [
          for (final item in json['degrees'] as List)
            AcademicOption(
              id: item['id'] as int,
              label: (item['degreeLevel'] as String).toLowerCase(),
              parentId: item['programmeId'] as int,
              minimumYear: item['minimumYear'] as int,
              maximumYear: item['maximumYear'] as int,
            ),
        ],
      );
  AcademicCatalog withCurrentProfile(PersonalProfile? profile) {
    final catalog = this;
    if (profile == null ||
        catalog.degrees.any((d) => d.id == profile.degreeId)) {
      return catalog;
    }
    // Existing owners can retain a previously selected inactive degree.
    final degree = profile.json['degree'] as Map;
    return AcademicCatalog(
      departments: [
        ...catalog.departments,
        if (!catalog.departments.any((d) => d.id == profile.departmentId))
          AcademicOption(
            id: profile.departmentId,
            label: (profile.json['department'] as Map)['name'] as String,
          ),
      ],
      programmes: [
        ...catalog.programmes,
        if (!catalog.programmes.any((p) => p.id == profile.programmeId))
          AcademicOption(
            id: profile.programmeId,
            label: profile.academicLabel,
            parentId: profile.departmentId,
          ),
      ],
      degrees: [
        ...catalog.degrees,
        AcademicOption(
          id: profile.degreeId,
          label: '${degree['degreeLevel']} (current)',
          parentId: profile.programmeId,
          minimumYear: degree['minimumYear'] as int,
          maximumYear: degree['maximumYear'] as int,
        ),
      ],
    );
  }
}
