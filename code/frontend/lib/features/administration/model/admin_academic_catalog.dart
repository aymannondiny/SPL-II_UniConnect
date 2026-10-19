class AdminDepartment {
  const AdminDepartment({
    required this.id,
    required this.name,
    required this.code,
  });
  final int id;
  final String name;
  final String code;

  factory AdminDepartment.fromJson(Map<String, dynamic> json) =>
      AdminDepartment(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        code: json['code'] as String,
      );
}

class AdminProgramme {
  const AdminProgramme({
    required this.id,
    required this.departmentId,
    required this.name,
    required this.code,
  });
  final int id;
  final int departmentId;
  final String name;
  final String code;

  factory AdminProgramme.fromJson(Map<String, dynamic> json) => AdminProgramme(
    id: (json['id'] as num).toInt(),
    departmentId: (json['departmentId'] as num).toInt(),
    name: json['name'] as String,
    code: json['code'] as String,
  );
}

class AdminDegree {
  const AdminDegree({
    required this.id,
    required this.programmeId,
    required this.level,
    required this.durationYears,
    required this.minimumYear,
    required this.maximumYear,
    required this.active,
  });
  final int id;
  final int programmeId;
  final String level;
  final int durationYears;
  final int minimumYear;
  final int maximumYear;
  final bool active;

  factory AdminDegree.fromJson(Map<String, dynamic> json) => AdminDegree(
    id: (json['id'] as num).toInt(),
    programmeId: (json['programmeId'] as num).toInt(),
    level: json['degreeLevel'] as String,
    durationYears: (json['durationYears'] as num).toInt(),
    minimumYear: (json['minimumYear'] as num).toInt(),
    maximumYear: (json['maximumYear'] as num).toInt(),
    active: json['active'] as bool,
  );
}

class AdminAcademicCatalog {
  const AdminAcademicCatalog({
    required this.departments,
    required this.programmes,
    required this.degrees,
  });
  final List<AdminDepartment> departments;
  final List<AdminProgramme> programmes;
  final List<AdminDegree> degrees;

  factory AdminAcademicCatalog.fromJson(Map<String, dynamic> json) =>
      AdminAcademicCatalog(
        departments: [
          for (final item in json['departments'] as List)
            AdminDepartment.fromJson(item as Map<String, dynamic>),
        ],
        programmes: [
          for (final item in json['programmes'] as List)
            AdminProgramme.fromJson(item as Map<String, dynamic>),
        ],
        degrees: [
          for (final item in json['degrees'] as List)
            AdminDegree.fromJson(item as Map<String, dynamic>),
        ],
      );
}
