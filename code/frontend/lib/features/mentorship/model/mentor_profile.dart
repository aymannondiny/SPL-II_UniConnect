import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';

@immutable
class MentorExpertise {
  const MentorExpertise({
    required this.topic,
    this.description,
  });

  final String topic;
  final String? description;

  factory MentorExpertise.fromJson(Map<String, dynamic> json) {
    return MentorExpertise(
      topic: json['topic'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'topic': topic,
    if (description != null) 'description': description,
  };
}

@immutable
class MentorProfile {
  const MentorProfile({
    required this.mentorProfileId,
    required this.userId,
    required this.fullName,
    required this.role,
    this.departmentName,
    this.yearOfStudy,
    this.graduationYear,
    this.profilePhotoUrl,
    required this.mentoringBio,
    required this.status,
    required this.expertise,
    this.registeredAt,
    this.updatedAt,
  });

  final int mentorProfileId;
  final int userId;
  final String fullName;
  final String role;
  final String? departmentName;
  final int? yearOfStudy;
  final int? graduationYear;
  final String? profilePhotoUrl;
  final String mentoringBio;
  final MentorStatus status;
  final List<MentorExpertise> expertise;
  final DateTime? registeredAt;
  final DateTime? updatedAt;

  factory MentorProfile.fromJson(Map<String, dynamic> json) {
    return MentorProfile(
      mentorProfileId: (json['mentorProfileId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String? ?? 'Mentor',
      role: json['role'] as String? ?? 'STUDENT',
      departmentName: json['departmentName'] as String?,
      yearOfStudy: (json['yearOfStudy'] as num?)?.toInt(),
      graduationYear: (json['graduationYear'] as num?)?.toInt(),
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      mentoringBio: json['mentoringBio'] as String? ?? '',
      status: MentorStatusX.fromApi(json['status'] as String?),
      expertise: (json['expertise'] as List<dynamic>?)
              ?.map((e) => MentorExpertise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      registeredAt: json['registeredAt'] != null
          ? DateTime.tryParse(json['registeredAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
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
    'mentoringBio': mentoringBio,
    'status': status.toApi(),
    'expertise': expertise.map((e) => e.toJson()).toList(),
    if (registeredAt != null) 'registeredAt': registeredAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}
