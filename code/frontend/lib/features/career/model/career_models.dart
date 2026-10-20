enum CareerEmploymentType { internship, partTime, fullTime, contract }

enum CareerWorkMode { onsite, remote, hybrid }

enum CareerSort { newest, deadline }

enum CareerAvailability { published, expired, closed, removed, unavailable }

enum CareerApplicationChannel { url, email }

extension CareerEmploymentTypeLabel on CareerEmploymentType {
  String get label => switch (this) {
    CareerEmploymentType.internship => 'Internship',
    CareerEmploymentType.partTime => 'Part-time',
    CareerEmploymentType.fullTime => 'Full-time',
    CareerEmploymentType.contract => 'Contract',
  };

  String get apiValue => switch (this) {
    CareerEmploymentType.internship => 'INTERNSHIP',
    CareerEmploymentType.partTime => 'PART_TIME',
    CareerEmploymentType.fullTime => 'FULL_TIME',
    CareerEmploymentType.contract => 'CONTRACT',
  };

  static CareerEmploymentType? fromApi(String? value) => switch (value) {
    'INTERNSHIP' => CareerEmploymentType.internship,
    'PART_TIME' => CareerEmploymentType.partTime,
    'FULL_TIME' => CareerEmploymentType.fullTime,
    'CONTRACT' => CareerEmploymentType.contract,
    _ => null,
  };
}

extension CareerWorkModeLabel on CareerWorkMode {
  String get label => switch (this) {
    CareerWorkMode.onsite => 'On-site',
    CareerWorkMode.remote => 'Remote',
    CareerWorkMode.hybrid => 'Hybrid',
  };

  String get apiValue => switch (this) {
    CareerWorkMode.onsite => 'ONSITE',
    CareerWorkMode.remote => 'REMOTE',
    CareerWorkMode.hybrid => 'HYBRID',
  };

  static CareerWorkMode? fromApi(String? value) => switch (value) {
    'ONSITE' => CareerWorkMode.onsite,
    'REMOTE' => CareerWorkMode.remote,
    'HYBRID' => CareerWorkMode.hybrid,
    _ => null,
  };
}

extension CareerAvailabilityLabel on CareerAvailability {
  String get label => switch (this) {
    CareerAvailability.published => 'Open',
    CareerAvailability.expired => 'Expired',
    CareerAvailability.closed => 'Closed',
    CareerAvailability.removed => 'Removed',
    CareerAvailability.unavailable => 'Unavailable',
  };

  static CareerAvailability parse(String? value) => switch (value) {
    'EXPIRED' => CareerAvailability.expired,
    'CLOSED' => CareerAvailability.closed,
    'REMOVED' => CareerAvailability.removed,
    'UNAVAILABLE' => CareerAvailability.unavailable,
    _ => CareerAvailability.published,
  };
}

extension CareerApplicationChannelLabel on CareerApplicationChannel {
  String get label => switch (this) {
    CareerApplicationChannel.url => 'Application website',
    CareerApplicationChannel.email => 'Email the poster',
  };

  String get apiValue => switch (this) {
    CareerApplicationChannel.url => 'URL',
    CareerApplicationChannel.email => 'EMAIL',
  };
}

class CareerSkill {
  const CareerSkill({
    required this.id,
    required this.name,
    required this.required,
  });

  final int id;
  final String name;
  final bool required;

  factory CareerSkill.fromJson(Map<String, dynamic> json) => CareerSkill(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? 'Unavailable skill',
    required: json['required'] as bool? ?? false,
  );
}

class CareerSkillInput {
  const CareerSkillInput({required this.name, required this.required});

  final String name;
  final bool required;

  Map<String, Object> toJson() => {'name': name.trim(), 'required': required};
}

class CareerPostInput {
  const CareerPostInput({
    required this.title,
    required this.companyName,
    required this.description,
    required this.qualifications,
    required this.location,
    required this.employmentType,
    required this.workMode,
    required this.salaryRange,
    required this.applicationUrl,
    required this.applicationEmail,
    required this.applicationDeadline,
    required this.skills,
  });

  final String title;
  final String companyName;
  final String description;
  final String qualifications;
  final String? location;
  final CareerEmploymentType employmentType;
  final CareerWorkMode workMode;
  final String? salaryRange;
  final String? applicationUrl;
  final String? applicationEmail;
  final DateTime applicationDeadline;
  final List<CareerSkillInput> skills;

  Map<String, Object?> toJson() => {
    'title': title.trim(),
    'companyName': companyName.trim(),
    'description': description.trim(),
    'qualifications': qualifications.trim(),
    'location': _optional(location),
    'employmentType': employmentType.apiValue,
    'workMode': workMode.apiValue,
    'salaryRange': _optional(salaryRange),
    'applicationUrl': _optional(applicationUrl),
    'applicationEmail': _optional(applicationEmail),
    'applicationDeadline': _formatDate(applicationDeadline),
    'skills': skills.map((skill) => skill.toJson()).toList(),
  };
}

class CareerPost {
  const CareerPost({
    required this.id,
    required this.title,
    required this.companyName,
    required this.description,
    required this.qualifications,
    required this.location,
    required this.employmentType,
    required this.workMode,
    required this.salaryRange,
    required this.applicationUrl,
    required this.applicationEmail,
    required this.applicationDeadline,
    required this.status,
    required this.saved,
    required this.canApply,
    required this.applicationChannels,
    required this.skills,
    required this.authorUserId,
    required this.authorDisplayName,
    required this.postedAt,
    required this.updatedAt,
    required this.closedAt,
  });

  final int id;
  final String? title;
  final String? companyName;
  final String? description;
  final String? qualifications;
  final String? location;
  final CareerEmploymentType? employmentType;
  final CareerWorkMode? workMode;
  final String? salaryRange;
  final String? applicationUrl;
  final String? applicationEmail;
  final DateTime? applicationDeadline;
  final CareerAvailability status;
  final bool saved;
  final bool canApply;
  final Set<CareerApplicationChannel> applicationChannels;
  final List<CareerSkill> skills;
  final int? authorUserId;
  final String? authorDisplayName;
  final DateTime? postedAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;

  bool get isAvailable => status == CareerAvailability.published;
  bool get isRedacted =>
      status == CareerAvailability.removed ||
      status == CareerAvailability.unavailable;

  factory CareerPost.fromJson(Map<String, dynamic> json) => CareerPost(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String?,
    companyName: json['companyName'] as String?,
    description: json['description'] as String?,
    qualifications: json['qualifications'] as String?,
    location: json['location'] as String?,
    employmentType: CareerEmploymentTypeLabel.fromApi(
      json['employmentType'] as String?,
    ),
    workMode: CareerWorkModeLabel.fromApi(json['workMode'] as String?),
    salaryRange: json['salaryRange'] as String?,
    applicationUrl: json['applicationUrl'] as String?,
    applicationEmail: json['applicationEmail'] as String?,
    applicationDeadline: _date(json['applicationDeadline']),
    status: CareerAvailabilityLabel.parse(json['status'] as String?),
    saved: json['saved'] as bool? ?? false,
    canApply: json['canApply'] as bool? ?? false,
    applicationChannels: {
      for (final channel in (json['applicationChannels'] as List? ?? const []))
        if (channel == 'URL')
          CareerApplicationChannel.url
        else if (channel == 'EMAIL')
          CareerApplicationChannel.email,
    },
    skills: [
      for (final skill in (json['skills'] as List? ?? const []))
        CareerSkill.fromJson(skill as Map<String, dynamic>),
    ],
    authorUserId: (json['authorUserId'] as num?)?.toInt(),
    authorDisplayName: json['authorDisplayName'] as String?,
    postedAt: _date(json['postedAt']),
    updatedAt: _date(json['updatedAt']),
    closedAt: _date(json['closedAt']),
  );
}

class SavedCareerPost {
  const SavedCareerPost({
    required this.id,
    required this.note,
    required this.savedAt,
    required this.updatedAt,
    required this.post,
  });

  final int id;
  final String? note;
  final DateTime? savedAt;
  final DateTime? updatedAt;
  final CareerPost post;

  factory SavedCareerPost.fromJson(Map<String, dynamic> json) =>
      SavedCareerPost(
        id: (json['id'] as num).toInt(),
        note: json['note'] as String?,
        savedAt: _date(json['savedAt']),
        updatedAt: _date(json['updatedAt']),
        post: CareerPost.fromJson(json['post'] as Map<String, dynamic>),
      );
}

class CareerPage<T> {
  const CareerPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
  });

  final List<T> items;
  final int page;
  final int size;
  final int totalElements;

  factory CareerPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) => CareerPage<T>(
    items: [
      for (final item in json['items'] as List? ?? const [])
        parse(item as Map<String, dynamic>),
    ],
    page: (json['page'] as num?)?.toInt() ?? 0,
    size: (json['size'] as num?)?.toInt() ?? 20,
    totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
  );
}

DateTime? _date(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

String? _optional(String? value) {
  final cleaned = value?.trim();
  return cleaned == null || cleaned.isEmpty ? null : cleaned;
}

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
