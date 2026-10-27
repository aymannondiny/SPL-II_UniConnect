import 'package:uniconnect/features/club/model/club_workspace_context.dart';

/// Presentation permissions mirror role and context boundaries in the API.
/// The server remains responsible for authorizing every protected action.
class WorkspaceAccess {
  const WorkspaceAccess({
    this.role = 'STUDENT',
    this.context = const ClubWorkspaceContext(contextType: 'PERSONAL'),
  });

  final String role;
  final ClubWorkspaceContext context;

  bool get administration =>
      role == 'SYSTEM_ADMIN' && context.contextType == 'SYSTEM_ADMINISTRATION';
  bool get club =>
      role == 'STUDENT' &&
      context.contextType == 'CLUB' &&
      context.assignmentId != null &&
      context.clubId != null &&
      ['CLUB_ADMINISTRATOR', 'REPRESENTATIVE'].contains(context.clubRole);
  bool get personal => context.contextType == 'PERSONAL';
  bool get member => role == 'STUDENT' || role == 'ALUMNI';

  static const administrationSections = {
    'Academic catalog': 0,
    'Club administration': 1,
    'Club requests': 2,
    'Account management': 3,
    'Report queue': 4,
  };

  bool allows(String destination) {
    if (['Home', 'My profile', 'Notifications'].contains(destination)) {
      return true;
    }
    if (administration) {
      return destination == 'Administration' ||
          administrationSections.containsKey(destination);
    }
    if (club) return destination == 'Club workspace';
    if (!personal) return false;
    if (destination == 'Project finder') return role == 'STUDENT';
    if (['Career board', 'Mentorship'].contains(destination)) return member;
    return [
      'Discover',
      'Connections',
      'Messages',
      'Clubs & events',
      'My reports',
    ].contains(destination);
  }
}
