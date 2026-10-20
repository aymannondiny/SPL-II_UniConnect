import 'package:flutter/foundation.dart';

@immutable
class MentorExpertiseInput {
  const MentorExpertiseInput({required this.topic, this.description});

  final String topic;
  final String? description;

  Map<String, dynamic> toJson() => {
    'topic': topic.trim(),
    if (description != null && description!.trim().isNotEmpty)
      'description': description!.trim(),
  };
}

@immutable
class MentorRegistrationRequest {
  const MentorRegistrationRequest({
    required this.mentoringBio,
    required this.expertise,
  });

  final String mentoringBio;
  final List<MentorExpertiseInput> expertise;

  String? validate() {
    final bio = mentoringBio.trim();
    if (bio.length < 10) {
      return 'Mentoring bio must be at least 10 characters.';
    }
    if (bio.length > 5000) {
      return 'Mentoring bio must be at most 5000 characters.';
    }
    if (expertise.isEmpty) {
      return 'Please specify at least one expertise topic.';
    }
    for (final exp in expertise) {
      if (exp.topic.trim().isEmpty) {
        return 'Expertise topic cannot be empty.';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'mentoringBio': mentoringBio.trim(),
    'expertise': expertise.map((e) => e.toJson()).toList(),
  };
}
