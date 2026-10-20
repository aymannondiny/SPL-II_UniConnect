import 'package:flutter/foundation.dart';

@immutable
class EnrollSlotRequest {
  const EnrollSlotRequest({this.joinMessage, this.learningGoal});

  final String? joinMessage;
  final String? learningGoal;

  String? validate() {
    if (joinMessage != null && joinMessage!.trim().length > 300) {
      return 'Join message cannot exceed 300 characters.';
    }
    if (learningGoal != null && learningGoal!.trim().length > 1000) {
      return 'Learning goal cannot exceed 1000 characters.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    if (joinMessage != null && joinMessage!.trim().isNotEmpty)
      'joinMessage': joinMessage!.trim(),
    if (learningGoal != null && learningGoal!.trim().isNotEmpty)
      'learningGoal': learningGoal!.trim(),
  };
}
