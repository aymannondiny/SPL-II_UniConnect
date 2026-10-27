import 'package:uniconnect/features/home/model/workspace_access.dart';

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

const administrationDestinations = [
  WorkspaceDestination('Account management', Icons.manage_accounts_outlined),
  WorkspaceDestination('Club administration', Icons.account_balance_outlined),
  WorkspaceDestination('Club requests', Icons.playlist_add_check_outlined),
  WorkspaceDestination('Report queue', Icons.flag_outlined),
  WorkspaceDestination('Academic catalog', Icons.menu_book_outlined),
];

Map<String, List<WorkspaceDestination>> destinationsFor(
  WorkspaceAccess access,
) {
  if (access.administration) {
    return {
      'Main': const [
        WorkspaceDestination('Home', Icons.home_outlined),
        WorkspaceDestination('Notifications', Icons.notifications_none),
      ],
      'Management': administrationDestinations,
      'Account': const [
        WorkspaceDestination('My profile', Icons.person_outline),
      ],
    };
  }
  if (access.club) {
    return {
      'Club': const [
        WorkspaceDestination('Home', Icons.home_outlined),
        WorkspaceDestination('Club workspace', Icons.groups_outlined),
        WorkspaceDestination('Notifications', Icons.notifications_none),
      ],
      'Account': const [
        WorkspaceDestination('My profile', Icons.person_outline),
      ],
    };
  }
  return {
    for (final group in workspaceGroups.entries)
      if (group.value.any((item) => access.allows(item.label)))
        group.key: group.value
            .where((item) => access.allows(item.label))
            .toList(),
  };
}
