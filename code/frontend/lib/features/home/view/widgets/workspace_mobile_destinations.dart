import 'package:flutter/material.dart';
import 'package:uniconnect/features/home/model/workspace_access.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_destinations.dart';

List<WorkspaceDestination> mobileDestinationsFor(WorkspaceAccess access) {
  if (access.administration) {
    return const [
      WorkspaceDestination('Home', Icons.home_outlined),
      WorkspaceDestination('Report queue', Icons.flag_outlined),
      WorkspaceDestination(
        'Account management',
        Icons.manage_accounts_outlined,
      ),
      WorkspaceDestination('Notifications', Icons.notifications_none),
    ];
  }
  if (access.club) {
    return const [
      WorkspaceDestination('Home', Icons.home_outlined),
      WorkspaceDestination('Club workspace', Icons.groups_outlined),
      WorkspaceDestination('Notifications', Icons.notifications_none),
    ];
  }
  return const [
    WorkspaceDestination('Home', Icons.home_outlined),
    WorkspaceDestination('Discover', Icons.search),
    WorkspaceDestination('Connections', Icons.people_outline),
    WorkspaceDestination('Messages', Icons.chat_bubble_outline),
  ];
}
