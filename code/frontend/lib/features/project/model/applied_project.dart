import 'project_listing.dart';
import 'project_application.dart';

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
