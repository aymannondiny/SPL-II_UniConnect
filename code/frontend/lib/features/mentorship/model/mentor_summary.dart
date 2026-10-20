import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';

@immutable
class MentorSummary {
  const MentorSummary({
    required this.mentorProfileId,
    required this.userId,
    required this.fullName,
    required this.role,
    this.departmentName,
    this.yearOfStudy,
    this.graduationYear,
    this.profilePhotoUrl,
    required this.status,
    required this.expertiseTopics,
  });

  final int mentorProfileId;
  final int userId;
  final String fullName;
  final String role;
  final String? departmentName;
  final int? yearOfStudy;
  final int? graduationYear;
  final String? profilePhotoUrl;
  final MentorStatus status;
  final List<String> expertiseTopics;

  factory MentorSummary.fromJson(Map<String, dynamic> json) {
    return MentorSummary(
      mentorProfileId: (json['mentorProfileId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String? ?? 'Mentor',
      role: json['role'] as String? ?? 'STUDENT',
      departmentName: json['departmentName'] as String?,
      yearOfStudy: (json['yearOfStudy'] as num?)?.toInt(),
      graduationYear: (json['graduationYear'] as num?)?.toInt(),
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      status: MentorStatusX.fromApi(json['status'] as String?),
      expertiseTopics: (json['expertiseTopics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'mentorProfileId': mentorProfileId,
    'userId': userId,
    'fullName': fullName,
    'role': role,
    'departmentName': departmentName,
    'yearOfStudy': yearOfStudy,
    'graduationYear': graduationYear,
    'profilePhotoUrl': profilePhotoUrl,
    'status': status.toApi(),
    'expertiseTopics': expertiseTopics,
  };
}
