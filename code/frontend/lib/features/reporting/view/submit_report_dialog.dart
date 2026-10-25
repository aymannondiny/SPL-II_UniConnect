import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';
import 'package:uniconnect/features/reporting/data/report_repository.dart';

const reportTargetTypes = [
  'USER',
  'CLUB',
  'ANNOUNCEMENT',
  'EVENT',
  'CHAT_MESSAGE',
  'PROJECT',
  'CAREER_POST',
];

class SubmitReportDialog extends StatefulWidget {
  const SubmitReportDialog({
    required this.repository,
    this.targetType,
    this.targetId,
    super.key,
  });
  final ReportRepository repository;
  final String? targetType;
  final int? targetId;

  @override
  State<SubmitReportDialog> createState() => _SubmitReportDialogState();
}

class _SubmitReportDialogState extends State<SubmitReportDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late final TextEditingController _id;
  late String _type;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.targetType ?? 'USER';
    _id = TextEditingController(text: widget.targetId?.toString());
  }

  @override
  void dispose() {
    _reason.dispose();
    _id.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.submit(
        _type,
        int.parse(_id.text.trim()),
        _reason.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Report content'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Explain the concern for the moderation team. Only content you can access can be reported.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Content type'),
                items: [
                  for (final type in reportTargetTypes)
                    DropdownMenuItem(
                      value: type,
                      child: Text(type.replaceAll('_', ' ')),
                    ),
                ],
                onChanged: _saving || widget.targetType != null
                    ? null
                    : (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _id,
                readOnly: widget.targetId != null,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Content ID'),
                validator: (value) =>
                    (int.tryParse(value?.trim() ?? '') ?? 0) > 0
                    ? null
                    : 'Enter a positive content ID.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reason,
                maxLength: 1000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Explain the concern.'
                    : null,
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _submit,
        child: Text(_saving ? 'Submitting…' : 'Submit report'),
      ),
    ],
  );
}
