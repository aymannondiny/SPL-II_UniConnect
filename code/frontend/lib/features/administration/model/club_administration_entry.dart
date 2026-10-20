import 'package:uniconnect/features/club/model/club.dart';

class ClubAdministratorAssignment {
  const ClubAdministratorAssignment({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.current,
  });
  final int id;
  final int userId;
  final String fullName;
  final bool current;

  factory ClubAdministratorAssignment.fromJson(Map<String, dynamic> json) =>
      ClubAdministratorAssignment(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        fullName: json['fullName'] as String,
        current: json['current'] as bool,
      );
}

class ClubAdministrationEntry {
  const ClubAdministrationEntry({
    required this.club,
    required this.administrators,
  });
  final Club club;
  final List<ClubAdministratorAssignment> administrators;

  factory ClubAdministrationEntry.fromJson(Map<String, dynamic> json) =>
      ClubAdministrationEntry(
        club: Club.fromJson(json['club'] as Map<String, dynamic>),
        administrators: (json['administrators'] as List<dynamic>)
            .map(
              (value) => ClubAdministratorAssignment.fromJson(
                value as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
}

class EligibleClubAdministrator {
  const EligibleClubAdministrator({
    required this.id,
    required this.fullName,
    required this.email,
  });
  final int id;
  final String fullName;
  final String email;

  factory EligibleClubAdministrator.fromJson(Map<String, dynamic> json) =>
      EligibleClubAdministrator(
        id: (json['userId'] as num).toInt(),
        fullName: json['fullName'] as String,
        email: json['email'] as String,
      );
}
