import 'package:flutter/material.dart';

/// One navigation inventory for the desktop sidebar and mobile More sheet.
class WorkspaceDestination {
  const WorkspaceDestination(this.label, this.icon, {this.soon = false});
  final String label;
  final IconData icon;
  final bool soon;
}

const workspaceGroups = <String, List<WorkspaceDestination>>{
  'Main': [
    WorkspaceDestination('Home', Icons.home_outlined),
    WorkspaceDestination('Discover', Icons.search),
    WorkspaceDestination('Connections', Icons.people_outline),
    WorkspaceDestination('Messages', Icons.chat_bubble_outline),
    WorkspaceDestination('Notifications', Icons.notifications_none),
  ],
  'Campus': [
    WorkspaceDestination('Clubs & events', Icons.calendar_today_outlined),
    WorkspaceDestination('Project finder', Icons.layers_outlined),
    WorkspaceDestination('Career board', Icons.work_outline),
    WorkspaceDestination('Mentorship', Icons.school_outlined),
  ],
  'Account': [
    WorkspaceDestination('My reports', Icons.flag_outlined),
    WorkspaceDestination('My profile', Icons.person_outline),
    WorkspaceDestination('Administration', Icons.shield_outlined),
  ],
};
