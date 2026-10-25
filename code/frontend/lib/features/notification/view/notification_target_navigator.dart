import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/network/authenticated_json_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/chat/data/chat_repository.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';
import 'package:uniconnect/features/club/data/club_repository.dart';
import 'package:uniconnect/features/club/view/widgets/campus_detail_dialog.dart';
import 'package:uniconnect/features/club/view/widgets/club_profile.dart';
import 'package:uniconnect/features/connection/data/connection_repository.dart';
import 'package:uniconnect/features/connection/view/member_profile_page.dart';
import 'package:uniconnect/features/mentorship/data/api_mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/data/mentorship_repository.dart';
import 'package:uniconnect/features/mentorship/view/widgets/mentorship_slot_details_dialog.dart';
import 'package:uniconnect/features/notification/model/app_notification.dart';
import 'package:uniconnect/features/project/data/project_repository.dart';
import 'package:uniconnect/features/project/view/project_dialogs.dart';
import 'package:uniconnect/features/reporting/data/report_repository.dart';
import 'package:uniconnect/features/reporting/view/report_details_dialog.dart';

/// Opens the referenced resource through its owning API and access checks.
class NotificationTargetNavigator {
  NotificationTargetNavigator({
    required this.client,
    required this.session,
    required this.onFeature,
    required this.onChat,
    this.projectRepository,
    this.mentorshipRepository,
    this.chatRepository,
    this.clubRepository,
    this.connectionRepository,
  });

  final ApiClient client;
  final SessionController session;
  final ValueChanged<String> onFeature;
  final ValueChanged<ChatConnection> onChat;
  final ProjectRepository? projectRepository;
  final MentorshipRepository? mentorshipRepository;
  final ChatRepository? chatRepository;
  final ClubRepository? clubRepository;
  final ConnectionRepository? connectionRepository;

  Future<void> open(BuildContext context, AppNotification notification) async {
    final id = notification.referenceId;
    if (id == null || id <= 0) {
      _message(context, 'This notification has no available destination.');
      return;
    }
    try {
      switch (notification.referenceType) {
        case 'PROJECT':
          final repository =
              projectRepository ?? ProjectRepository(client, session);
          final project = await repository.detail(id);
          if (!context.mounted) return;
          onFeature('Project finder');
          await showDialog<void>(
            context: context,
            builder: (_) =>
                ProjectDetailsDialog(project: project, repository: repository),
          );
        case 'MENTORSHIP_SLOT':
          onFeature('Mentorship');
          await MentorshipSlotDetailsDialog.show(
            context,
            slotId: id,
            repository:
                mentorshipRepository ??
                ApiMentorshipRepository(client, session),
          );
        case 'REPORT':
          onFeature('My reports');
          await showDialog<void>(
            context: context,
            builder: (_) => ReportDetailsDialog(
              id: id,
              repository: ReportRepository(
                AuthenticatedJsonClient(client, session),
              ),
            ),
          );
        case 'CONVERSATION':
          final conversations = await (chatRepository ?? ChatRepository(client))
              .conversations(await session.accessToken());
          final conversation = conversations
              .where((entry) => entry.id == id)
              .firstOrNull;
          if (!context.mounted) return;
          if (conversation == null) {
            throw const AuthFailure(
              'This conversation is no longer available.',
            );
          }
          onChat(
            ChatConnection(
              userId: conversation.otherUserId,
              fullName: conversation.otherFullName,
            ),
          );
        case 'CLUB':
          onFeature('Clubs & events');
          await showDialog<void>(
            context: context,
            builder: (_) => CampusDetailDialog(
              load: () =>
                  (clubRepository ?? ClubRepository(client, session)).club(id),
              builder: (club) => ClubProfile(club: club),
            ),
          );
        case 'USER':
          if (id == session.account?.userId) {
            onFeature('My profile');
          } else {
            await _member(context, id);
          }
        case 'CONNECTION':
          final data = await AuthenticatedJsonClient(
            client,
            session,
          ).request('/api/v1/connections/$id');
          final requester = (data['requesterId'] as num).toInt();
          final receiver = (data['receiverId'] as num).toInt();
          final otherId = requester == session.account?.userId
              ? receiver
              : requester;
          if (!context.mounted) return;
          onFeature('Connections');
          await _member(context, otherId);
        default:
          _message(
            context,
            'This notification destination is not supported yet.',
          );
      }
    } on AuthFailure catch (failure) {
      if (context.mounted) _message(context, failure.message);
    } on Object {
      if (context.mounted) {
        _message(
          context,
          'Unable to open this notification. The target may no longer be available.',
        );
      }
    }
  }

  Future<void> _member(BuildContext context, int id) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MemberProfilePage(
            repository:
                connectionRepository ?? ConnectionRepository(client, session),
            memberId: id,
            onConnect: null,
            onMessage: (member) {
              Navigator.pop(context);
              onChat(ChatConnection(userId: member.id, fullName: member.name));
            },
          ),
        ),
      );

  void _message(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}
