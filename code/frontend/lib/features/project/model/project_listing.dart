import 'project_skill.dart';

class ProjectListing {
  const ProjectListing({
    required this.id,
    required this.creatorUserId,
    required this.creatorDisplayName,
    required this.creatorDepartmentId,
    required this.creatorDepartmentCode,
    required this.creatorDepartmentName,
    required this.title,
    required this.description,
    required this.teamSizeLimit,
    required this.duration,
    required this.courseName,
    required this.applicationDeadline,
    required this.status,
    required this.availability,
    required this.membershipCount,
    required this.vacancies,
    required this.full,
    required this.canApply,
    required this.currentApplicationStatus,
    required this.skills,
    required this.createdAt,
    required this.updatedAt,
    required this.closedAt,
  });

  final int id;
  final int? creatorUserId;
  final String creatorDisplayName;
  final int? creatorDepartmentId;
  final String? creatorDepartmentCode;
  final String? creatorDepartmentName;
  final String title;
  final String description;
  final int teamSizeLimit;
  final String? duration;
  final String? courseName;
  final String applicationDeadline;
  final String status;
  final String availability;
  final int membershipCount;
  final int vacancies;
  final bool full;
  final bool canApply;
  final String? currentApplicationStatus;
  final List<ProjectSkill> skills;
  final String createdAt;
  final String updatedAt;
  final String? closedAt;

  factory ProjectListing.fromJson(Map<String, dynamic> json) => ProjectListing(
    id: (json['id'] as num).toInt(),
    creatorUserId: (json['creatorUserId'] as num?)?.toInt(),
    creatorDisplayName: json['creatorDisplayName'] as String? ?? 'Former User',
    creatorDepartmentId: (json['creatorDepartmentId'] as num?)?.toInt(),
    creatorDepartmentCode: json['creatorDepartmentCode'] as String?,
    creatorDepartmentName: json['creatorDepartmentName'] as String?,
    title: json['title'] as String? ?? 'Project listing',
    description: json['description'] as String? ?? '',
    teamSizeLimit: (json['teamSizeLimit'] as num?)?.toInt() ?? 2,
    duration: json['duration'] as String?,
    courseName: json['courseName'] as String?,
    applicationDeadline: json['applicationDeadline'] as String? ?? '',
    status: json['status'] as String? ?? 'OPEN',
    availability: json['availability'] as String? ?? 'AVAILABLE',
    membershipCount: (json['membershipCount'] as num?)?.toInt() ?? 1,
    vacancies: (json['vacancies'] as num?)?.toInt() ?? 0,
    full: json['full'] as bool? ?? false,
    canApply: json['canApply'] as bool? ?? false,
    currentApplicationStatus: json['currentApplicationStatus'] as String?,
    skills: (json['skills'] as List<dynamic>? ?? const [])
        .map((item) => ProjectSkill.fromJson(item as Map<String, dynamic>))
        .toList(),
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
    closedAt: json['closedAt'] as String?,
  );
}

class ProjectPage<T> {
  const ProjectPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
  });

  final List<T> items;
  final int page;
  final int size;
  final int totalElements;

  factory ProjectPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parseItem,
  ) => ProjectPage<T>(
    items: (json['items'] as List<dynamic>)
        .map((item) => parseItem(item as Map<String, dynamic>))
        .toList(),
    page: (json['page'] as num?)?.toInt() ?? 0,
    size: (json['size'] as num?)?.toInt() ?? 20,
    totalElements: (json['totalElements'] as num).toInt(),
  );
}
