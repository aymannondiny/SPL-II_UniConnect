import 'package:flutter/foundation.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';

@immutable
class MentorFilterParams {
  const MentorFilterParams({
    this.topic,
    this.departmentId,
    this.yearOfStudy,
    this.page = 0,
    this.size = 10,
  });

  final String? topic;
  final int? departmentId;
  final int? yearOfStudy;
  final int page;
  final int size;

  bool get hasFilters =>
      (topic != null && topic!.trim().isNotEmpty) ||
      departmentId != null ||
      yearOfStudy != null;

  MentorFilterParams copyWith({
    String? topic,
    int? departmentId,
    int? yearOfStudy,
    int? page,
    int? size,
    bool clearTopic = false,
    bool clearDepartment = false,
    bool clearYear = false,
  }) {
    return MentorFilterParams(
      topic: clearTopic ? null : (topic ?? this.topic),
      departmentId: clearDepartment
          ? null
          : (departmentId ?? this.departmentId),
      yearOfStudy: clearYear ? null : (yearOfStudy ?? this.yearOfStudy),
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (topic != null && topic!.trim().isNotEmpty) {
      params['topic'] = topic!.trim();
    }
    if (departmentId != null) {
      params['departmentId'] = departmentId.toString();
    }
    if (yearOfStudy != null) {
      params['yearOfStudy'] = yearOfStudy.toString();
    }
    return params;
  }
}

@immutable
class SlotFilterParams {
  const SlotFilterParams({
    this.status = SlotStatus.open,
    this.mode,
    this.topic,
    this.page = 0,
    this.size = 10,
  });

  final SlotStatus? status;
  final SlotMode? mode;
  final String? topic;
  final int page;
  final int size;

  SlotFilterParams copyWith({
    SlotStatus? status,
    SlotMode? mode,
    String? topic,
    int? page,
    int? size,
    bool clearStatus = false,
    bool clearMode = false,
    bool clearTopic = false,
  }) {
    return SlotFilterParams(
      status: clearStatus ? null : (status ?? this.status),
      mode: clearMode ? null : (mode ?? this.mode),
      topic: clearTopic ? null : (topic ?? this.topic),
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (status != null) {
      params['status'] = status!.toApi();
    }
    if (mode != null) {
      params['mode'] = mode!.toApi();
    }
    if (topic != null && topic!.trim().isNotEmpty) {
      params['topic'] = topic!.trim();
    }
    return params;
  }
}
