import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/network/authenticated_json_client.dart';
import 'package:uniconnect/core/session/session_scope.dart';
import 'package:uniconnect/features/reporting/data/report_repository.dart';
import 'package:uniconnect/features/reporting/view/submit_report_dialog.dart';

class ReportContentButton extends StatelessWidget {
  const ReportContentButton({
    required this.targetType,
    required this.targetId,
    super.key,
  });
  final String targetType;
  final int targetId;

  static Future<void> open(
    BuildContext context, {
    required String targetType,
    required int targetId,
  }) async {
    final client = ApiClient();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (_) => SubmitReportDialog(
          repository: ReportRepository(
            AuthenticatedJsonClient(client, SessionScope.of(context)),
          ),
          targetType: targetType,
          targetId: targetId,
        ),
      );
      if (submitted == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Report submitted. Track its progress in My reports.',
            ),
          ),
        );
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => open(context, targetType: targetType, targetId: targetId),
    icon: const Icon(Icons.flag_outlined, size: 18),
    label: const Text('Report'),
  );
}
