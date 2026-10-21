class ProjectSkill {
  const ProjectSkill({
    required this.id,
    required this.name,
    required this.isRequired,
  });

  final int id;
  final String name;
  final bool isRequired;

  factory ProjectSkill.fromJson(Map<String, dynamic> json) => ProjectSkill(
    id: (json['skillId'] as num).toInt(),
    name: json['name'] as String? ?? 'Skill',
    isRequired: json['required'] as bool? ?? false,
  );
}

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
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((item) => parseItem(item as Map<String, dynamic>))
        .toList(),
    page: (json['page'] as num?)?.toInt() ?? 0,
    size: (json['size'] as num?)?.toInt() ?? 20,
    totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
  );
}

class ProjectApplication {
  const ProjectApplication({
    required this.id,
    required this.projectId,
    required this.applicantUserId,
    required this.applicantDisplayName,
    required this.message,
    required this.status,
    required this.appliedAt,
    required this.respondedAt,
  });

  final int id;
  final int projectId;
  final int applicantUserId;
  final String applicantDisplayName;
  final String? message;
  final String status;
  final String appliedAt;
  final String? respondedAt;

  factory ProjectApplication.fromJson(Map<String, dynamic> json) =>
      ProjectApplication(
        id: (json['id'] as num).toInt(),
        projectId: (json['projectId'] as num).toInt(),
        applicantUserId: (json['applicantUserId'] as num).toInt(),
        applicantDisplayName:
            json['applicantDisplayName'] as String? ?? 'UniConnect student',
        message: json['message'] as String?,
        status: json['status'] as String? ?? 'PENDING',
        appliedAt: json['appliedAt'] as String? ?? '',
        respondedAt: json['respondedAt'] as String?,
      );
}

class AppliedProject {
  const AppliedProject({required this.project, required this.application});

  final ProjectListing? project;
  final ProjectApplication application;

  factory AppliedProject.fromJson(Map<String, dynamic> json) {
    final projectJson = json['project'] as Map<String, dynamic>?;
    return AppliedProject(
      project: projectJson == null
          ? null
          : ProjectListing.fromJson(projectJson),
      application: ProjectApplication.fromJson(
        json['application'] as Map<String, dynamic>,
      ),
    );
  }
}

class ProjectMember {
  const ProjectMember({
    required this.membershipId,
    required this.memberUserId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  final int membershipId;
  final int memberUserId;
  final String displayName;
  final String role;
  final String joinedAt;

  factory ProjectMember.fromJson(Map<String, dynamic> json) => ProjectMember(
    membershipId: (json['membershipId'] as num).toInt(),
    memberUserId: (json['memberUserId'] as num).toInt(),
    displayName: json['displayName'] as String? ?? 'UniConnect student',
    role: json['role'] as String? ?? 'TEAMMATE',
    joinedAt: json['joinedAt'] as String? ?? '',
  );
}

class ProjectRecommendation {
  const ProjectRecommendation({
    required this.userId,
    required this.displayName,
    required this.profilePhotoUrl,
    required this.departmentName,
    required this.matchedRequiredSkills,
    required this.matchedOptionalSkills,
  });

  final int userId;
  final String displayName;
  final String? profilePhotoUrl;
  final String? departmentName;
  final List<String> matchedRequiredSkills;
  final List<String> matchedOptionalSkills;

  factory ProjectRecommendation.fromJson(Map<String, dynamic> json) =>
      ProjectRecommendation(
        userId: (json['userId'] as num).toInt(),
        displayName: json['displayName'] as String? ?? 'UniConnect student',
        profilePhotoUrl: json['profilePhotoUrl'] as String?,
        departmentName: json['departmentName'] as String?,
        matchedRequiredSkills:
            (json['matchedRequiredSkills'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList(),
        matchedOptionalSkills:
            (json['matchedOptionalSkills'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList(),
      );
}

class ProjectCandidateSkill {
  const ProjectCandidateSkill({required this.name, required this.kind});

  final String name;
  final String kind;

  factory ProjectCandidateSkill.fromJson(Map<String, dynamic> json) =>
      ProjectCandidateSkill(
        name: json['name'] as String? ?? 'Skill',
        kind: json['kind'] as String? ?? 'REQUIRED',
      );
}

class ProjectCandidate {
  const ProjectCandidate({
    required this.userId,
    required this.fullName,
    required this.profilePhotoUrl,
    required this.departmentName,
    required this.programmeName,
    required this.yearOfStudy,
    required this.projectAvailable,
    required this.skills,
    required this.connectionStatus,
  });

  final int userId;
  final String fullName;
  final String? profilePhotoUrl;
  final String? departmentName;
  final String? programmeName;
  final int? yearOfStudy;
  final bool? projectAvailable;
  final List<ProjectCandidateSkill> skills;
  final String? connectionStatus;

  factory ProjectCandidate.fromJson(Map<String, dynamic> json) {
    final department = json['department'] as Map<String, dynamic>?;
    final programme = json['programme'] as Map<String, dynamic>?;
    final connection = json['connection'] as Map<String, dynamic>?;
    return ProjectCandidate(
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String? ?? 'UniConnect student',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      departmentName: department?['name'] as String?,
      programmeName: programme?['name'] as String?,
      yearOfStudy: (json['yearOfStudy'] as num?)?.toInt(),
      projectAvailable: json['projectAvailable'] as bool?,
      skills: (json['relevantSkills'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProjectCandidateSkill.fromJson)
          .toList(),
      connectionStatus: connection?['status'] as String?,
    );
  }
}

class ProjectAuditEntry {
  const ProjectAuditEntry({
    required this.id,
    required this.actorUserId,
    required this.applicationId,
    required this.eventType,
    required this.occurredAt,
  });

  final int id;
  final int? actorUserId;
  final int? applicationId;
  final String eventType;
  final String occurredAt;

  factory ProjectAuditEntry.fromJson(Map<String, dynamic> json) =>
      ProjectAuditEntry(
        id: (json['id'] as num).toInt(),
        actorUserId: (json['actorUserId'] as num?)?.toInt(),
        applicationId: (json['applicationId'] as num?)?.toInt(),
        eventType: json['eventType'] as String? ?? 'UPDATED',
        occurredAt: json['occurredAt'] as String? ?? '',
      );
}

class ProjectDepartment {
  const ProjectDepartment({
    required this.id,
    required this.name,
    required this.code,
  });
  final int id;
  final String name;
  final String code;

  factory ProjectDepartment.fromJson(Map<String, dynamic> json) =>
      ProjectDepartment(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? 'Department',
        code: json['code'] as String? ?? '',
      );
}

class ProjectRequestData {
  const ProjectRequestData({
    required this.title,
    required this.description,
    required this.teamSizeLimit,
    required this.duration,
    required this.courseName,
    required this.applicationDeadline,
    required this.skills,
  });

  final String title;
  final String description;
  final int teamSizeLimit;
  final String? duration;
  final String? courseName;
  final DateTime applicationDeadline;
  final List<({String name, bool isRequired})> skills;

  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'description': description.trim(),
    'teamSizeLimit': teamSizeLimit,
    'duration': duration?.trim().isEmpty == true ? null : duration?.trim(),
    'courseName': courseName?.trim().isEmpty == true
        ? null
        : courseName?.trim(),
    'applicationDeadline': _dateOnly(applicationDeadline),
    'skills': skills
        .where((skill) => skill.name.trim().isNotEmpty)
        .map(
          (skill) => {'name': skill.name.trim(), 'required': skill.isRequired},
        )
        .toList(),
  };

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class ProjectBrowseFilters {
  const ProjectBrowseFilters({
    this.skill = '',
    this.availability = '',
    this.sort = 'CREATED_DESC',
    this.departmentId,
  });

  final String skill;
  final String availability;
  final String sort;
  final int? departmentId;

  ProjectBrowseFilters copyWith({
    String? skill,
    String? availability,
    String? sort,
    int? departmentId,
    bool clearDepartment = false,
  }) => ProjectBrowseFilters(
    skill: skill ?? this.skill,
    availability: availability ?? this.availability,
    sort: sort ?? this.sort,
    departmentId: clearDepartment ? null : departmentId ?? this.departmentId,
  );

  Map<String, String> get query => {
    if (skill.trim().isNotEmpty) 'skill': skill.trim(),
    if (availability.isNotEmpty) 'availability': availability,
    if (departmentId != null) 'departmentId': '$departmentId',
    'sort': sort,
    'page': '0',
    'size': '20',
  };
}
