import 'package:uniconnect/features/profile/data/profile_repository.dart';
import 'package:uniconnect/features/profile/model/academic_catalog.dart';
import 'package:uniconnect/features/profile/model/personal_profile.dart';

/// Test-only fixtures; never imported by the production entry point.
class FakeProfileRepository implements ProfileRepository {
  PersonalProfile? profile;
  bool emptyCatalog = false;
  bool failLoad = false;
  bool failPrivacy = false;
  String detailsVisibility = 'CONNECTIONS_ONLY';
  Map<String, dynamic>? saved;
  String? savedRole;
  int loads = 0;
  @override
  Future<PersonalProfile?> load() async {
    loads++;
    if (failLoad) throw StateError('offline');
    return profile;
  }

  @override
  Future<AcademicCatalog> catalog() async => AcademicCatalog(
    departments: emptyCatalog
        ? []
        : [
            const AcademicOption(
              id: 1,
              label: 'Computer Science and Engineering',
            ),
          ],
    programmes: emptyCatalog
        ? []
        : [
            const AcademicOption(
              id: 2,
              parentId: 1,
              label: 'Software Engineering',
            ),
          ],
    degrees: emptyCatalog
        ? []
        : [
            const AcademicOption(
              id: 3,
              parentId: 2,
              label: 'Bachelor',
              minimumYear: 1,
              maximumYear: 4,
            ),
          ],
  );
  @override
  Future<PersonalProfile> save(String role, Map<String, dynamic> fields) async {
    saved = fields;
    savedRole = role;
    return profile = fixture(role: role, fields: fields);
  }

  static PersonalProfile fixture({
    String role = 'STUDENT',
    Map<String, dynamic> fields = const {},
  }) => PersonalProfile({
    'fullName': 'Test Member',
    'platformRole': role,
    'department': {'id': 1, 'name': 'Computer Science and Engineering'},
    'programme': {'id': 2, 'name': 'Software Engineering'},
    'degree': {
      'id': 3,
      'degreeLevel': 'BACHELOR',
      'minimumYear': 1,
      'maximumYear': 4,
    },
    'skills': ['Flutter'],
    'interests': ['Open source'],
    'bio': 'Building things for campus.',
    'student': role == 'STUDENT'
        ? {
            'studentNumber': '230042141',
            'yearOfStudy': 3,
            'expectedGraduationYear': 2028,
            'projectAvailability': true,
            'mentorshipAvailability': false,
          }
        : null,
    'alumni': role == 'ALUMNI'
        ? {
            'graduationYear': 2024,
            'currentCompany': 'Example company',
            'currentPosition': 'Software Engineer',
          }
        : null,
    ...fields,
    if (fields.isNotEmpty) (role == 'ALUMNI' ? 'alumni' : 'student'): fields,
  });
  @override
  Future<String> visibility() async => detailsVisibility;
  @override
  Future<void> saveVisibility(String visibility) async {
    if (failPrivacy) throw StateError('offline');
    detailsVisibility = visibility;
  }
}
