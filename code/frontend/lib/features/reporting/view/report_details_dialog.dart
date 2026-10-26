import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/reporting/data/report_repository.dart';
import 'package:uniconnect/features/reporting/model/content_report.dart';
import 'package:uniconnect/features/reporting/view/report_resolution_dialog.dart';

class ReportDetailsDialog extends StatefulWidget {
  const ReportDetailsDialog({
    required this.repository,
    required this.id,
    this.administration = false,
    this.currentUserId,
    super.key,
  });
  final ReportRepository repository;
  final int id;
  final bool administration;
  final int? currentUserId;

  @override
  State<ReportDetailsDialog> createState() => _ReportDetailsDialogState();
}

class _ReportDetailsDialogState extends State<ReportDetailsDialog> {
  ContentReport? _report;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => _run(() async {
    final report = await widget.repository.detail(
      widget.id,
      administration: widget.administration,
    );
    if (mounted) setState(() => _report = report);
  });

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review() async {
    await _run(() => widget.repository.review(widget.id));
    if (mounted && _error == null) await _load();
  }

  Future<void> _resolve() async {
    final decision = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const ReportResolutionDialog(),
    );
    if (decision == null || !mounted) return;
    await _run(() => widget.repository.resolve(widget.id, decision));
    if (mounted && _error == null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return AlertDialog(
      title: Text('Report #${widget.id}'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Retry'),
                ),
              ],
              if (report != null) ...[
                Text(
                  report.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${report.targetType} #${report.targetId} · ${report.status.replaceAll('_', ' ')}',
                ),
                const SizedBox(height: 16),
                SelectableText(report.reason),
                if (report.resolution != null) ...[
                  const Divider(height: 28),
                  const Text('Resolution'),
                  SelectableText(report.resolution!),
                ],
                if (widget.administration) ...[
                  const Divider(height: 28),
                  Text('Reviewer: ${report.reviewerId ?? 'Unassigned'}'),
                  if (report.snapshot != null) ...[
                    const SizedBox(height: 12),
                    const Text('Retained evidence'),
                    SelectableText(report.snapshot!),
                  ],
                  if (report.internalNotes != null) ...[
                    const SizedBox(height: 12),
                    const Text('Internal notes'),
                    SelectableText(report.internalNotes!),
                  ],
                  if (report.action != null)
                    SelectableText(
                      const JsonEncoder.withIndent('  ').convert(report.action),
                    ),
                  const SizedBox(height: 12),
                  const Text('Review history'),
                  for (final entry in report.history)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${entry['eventType']}'),
                      subtitle: Text(
                        '${entry['occurredAt']} · Actor ${entry['actorId']}\n${entry['internalNote'] ?? ''}',
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (widget.administration && report?.status == 'SUBMITTED')
          FilledButton(
            onPressed: _busy ? null : _review,
            child: const Text('Claim review'),
          ),
        if (widget.administration &&
            report?.status == 'UNDER_REVIEW' &&
            report?.reviewerId == widget.currentUserId)
          FilledButton(
            onPressed: _busy ? null : _resolve,
            child: const Text('Resolve'),
          ),
      ],
    );
  }
}
