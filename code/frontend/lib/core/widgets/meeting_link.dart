import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MeetingLink extends StatelessWidget {
  const MeetingLink({required this.url, super.key});

  final String url;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url.trim());
    var opened = false;
    if (uri != null &&
        {'https', 'http'}.contains(uri.scheme) &&
        uri.host.isNotEmpty) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Object {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open this meeting link. Check the address and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => _open(context),
    icon: const Icon(Icons.open_in_new, size: 16),
    label: Text(url, maxLines: 3, overflow: TextOverflow.ellipsis),
  );
}
