import 'package:flutter/material.dart';
import 'package:uniconnect/core/widgets/section_card.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/reporting/data/report_repository.dart';
import 'package:uniconnect/features/reporting/model/content_report.dart';
import 'package:uniconnect/features/reporting/view/report_details_dialog.dart';
import 'package:uniconnect/features/reporting/view/submit_report_dialog.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    required this.repository,
    this.administration = false,
    this.currentUserId,
    super.key,
  });
  final ReportRepository repository;
  final bool administration;
  final int? currentUserId;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<ContentReport> _items = [];
  int _total = 0;
  int _page = 0;
  bool _loading = false;
  bool _retryMore = false;
  String _status = '';
  String _targetType = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _retryMore = more;
    final page = more ? _page + 1 : 0;
    try {
      final result = await widget.repository.list(
        page: page,
        administration: widget.administration,
        status: _status,
        targetType: _targetType,
      );
      if (!mounted) return;
      setState(() {
        _items = more ? [..._items, ...result.items] : result.items;
        _total = result.total;
        _page = page;
      });
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => SubmitReportDialog(repository: widget.repository),
    );
    if (submitted == true && mounted) await _load();
  }

  Future<void> _open(int id) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ReportDetailsDialog(
        repository: widget.repository,
        id: id,
        administration: widget.administration,
        currentUserId: widget.currentUserId,
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    title: widget.administration ? 'Report review' : 'My reports',
    subtitle: widget.administration
        ? 'Review retained evidence and record a resolution.'
        : 'Submit concerns and track their resolution.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            if (!widget.administration)
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report content'),
              ),
            if (widget.administration) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _status,
                  onChanged: _loading
                      ? null
                      : (value) {
                          setState(() => _status = value!);
                          _load();
                        },
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All statuses'),
                    ),
                    for (final status in [
                      'SUBMITTED',
                      'UNDER_REVIEW',
                      'ACTION_TAKEN',
                      'NO_ACTION',
                    ])
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.replaceAll('_', ' ')),
                      ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _targetType,
                  onChanged: _loading
                      ? null
                      : (value) {
                          setState(() => _targetType = value!);
                          _load();
                        },
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All content types'),
                    ),
                    for (final type in reportTargetTypes)
                      DropdownMenuItem(
                        value: type,
                        child: Text(type.replaceAll('_', ' ')),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: _loading ? null : () => _load(more: _retryMore),
            child: const Text('Retry'),
          ),
        ] else if (!_loading && _items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No reports to show.'),
          ),
        for (final report in _items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: Text(report.label),
            subtitle: Text(
              '#${report.id} · ${report.targetType} · ${report.status.replaceAll('_', ' ')}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(report.id),
          ),
        if (_error == null && _items.length < _total)
          TextButton(
            onPressed: _loading ? null : () => _load(more: true),
            child: Text('Load more (${_items.length} of $_total)'),
          ),
      ],
    ),
  );
}
