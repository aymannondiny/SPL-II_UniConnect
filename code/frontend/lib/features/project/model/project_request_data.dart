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
