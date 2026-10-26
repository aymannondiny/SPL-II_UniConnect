import 'package:uniconnect/features/reporting/view/report_content_button.dart';
import 'package:flutter/material.dart';

import '../data/connection_repository.dart';
import '../model/connection_models.dart';
import 'widgets/member_profile_details.dart';

/// Loads the public representation so privacy remains enforced by the server.
class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({
    required this.repository,
    required this.memberId,
    required this.onConnect,
    required this.onMessage,
    super.key,
  });
  final ConnectionRepository repository;
  final int memberId;
  final Future<void> Function(MemberProfile)? onConnect;
  final ValueChanged<MemberProfile> onMessage;
  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  late Future<MemberProfile> _profile;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _profile = widget.repository.member(widget.memberId);

  Future<void> _connect(MemberProfile member) async {
    setState(() => _busy = true);
    try {
      await widget.onConnect!(member);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _reload();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Member profile'),
      actions: [
        ReportContentButton(targetType: 'USER', targetId: widget.memberId),
      ],
    ),
    body: FutureBuilder<MemberProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This member profile could not be loaded. It may no longer be available.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final member = snapshot.requireData;
        final status = member.connection?.status;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              child: Text(
                                member.name.trim().isEmpty
                                    ? '?'
                                    : member.name.characters.first
                                          .toUpperCase(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              member.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(member.headline),
                            const SizedBox(height: 20),
                            if (status == 'ACCEPTED')
                              FilledButton.icon(
                                onPressed: () => widget.onMessage(member),
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Message'),
                              )
                            else if (status == 'PENDING')
                              Chip(
                                label: Text(
                                  member.connection!.outgoing
                                      ? 'Request sent'
                                      : 'Respond in Connections',
                                ),
                              )
                            else
                              FilledButton.icon(
                                onPressed: _busy || widget.onConnect == null
                                    ? null
                                    : () => _connect(member),
                                icon: const Icon(Icons.person_add_alt_1),
                                label: Text(_busy ? 'Sending…' : 'Connect'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    MemberProfileDetails(member: member),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
