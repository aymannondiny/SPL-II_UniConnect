/// Owner-only profile. Never used to display another member's details.
class PersonalProfile {
  const PersonalProfile(this.json);
  factory PersonalProfile.fromJson(Map<String, dynamic> json) {
    final profile = PersonalProfile(Map.unmodifiable(json));
    if (profile.name.trim().isEmpty ||
        !['STUDENT', 'ALUMNI'].contains(profile.role)) {
      throw const FormatException('Invalid owner identity');
    }
    for (final key in ['department', 'programme', 'degree']) {
      final option = json[key] as Map<String, dynamic>;
      if ((option['id'] as int) <= 0) {
        throw const FormatException('Invalid academic option');
      }
      if (key != 'degree') option['name'] as String;
    }
    final degree = json['degree'] as Map<String, dynamic>;
    degree['minimumYear'] as int;
    degree['maximumYear'] as int;
    degree['degreeLevel'] as String;
    for (final key in ['skills', 'interests']) {
      List<String>.from(json[key] as List);
    }
    final subtype =
        json[profile.role == 'ALUMNI' ? 'alumni' : 'student']
            as Map<String, dynamic>;
    if (profile.role == 'STUDENT') {
      subtype['studentNumber'] as String;
      subtype['yearOfStudy'] as int;
      subtype['projectAvailability'] as bool;
      subtype['mentorshipAvailability'] as bool;
    } else {
      subtype['graduationYear'] as int;
    }
    return profile;
  }
  final Map<String, dynamic> json;
  String get name => json['fullName'] as String;
  String get role => json['platformRole'] as String;
  int get departmentId => (json['department'] as Map)['id'] as int;
  int get programmeId => (json['programme'] as Map)['id'] as int;
  int get degreeId => (json['degree'] as Map)['id'] as int;
  String get academicLabel => (json['programme'] as Map)['name'] as String;
  Map<String, dynamic> get editable => {
    'fullName': name,
    'programmeDegreeId': degreeId,
    'bio': json['bio'],
    'profilePhotoUrl': json['profilePhotoUrl'],
    'skills': json['skills'],
    'interests': json['interests'],
    ...?json[role == 'ALUMNI' ? 'alumni' : 'student'] as Map<String, dynamic>?,
  };
}
