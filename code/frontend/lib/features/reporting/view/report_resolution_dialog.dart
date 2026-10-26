import 'package:flutter/material.dart';

class ReportResolutionDialog extends StatefulWidget {
  const ReportResolutionDialog({super.key});

  @override
  State<ReportResolutionDialog> createState() => _ReportResolutionDialogState();
}

class _ReportResolutionDialogState extends State<ReportResolutionDialog> {
  final _form = GlobalKey<FormState>();
  final _summary = TextEditingController();
  final _notes = TextEditingController();
  final _evidence = TextEditingController();
  String _outcome = 'NO_ACTION';
  String _source = 'ACCOUNT_MODERATION';

  @override
  void dispose() {
    _summary.dispose();
    _notes.dispose();
    _evidence.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, <String, dynamic>{
      'outcome': _outcome,
      'resolutionSummary': _summary.text.trim(),
      'internalNotes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'actionEvidence': _outcome == 'NO_ACTION'
          ? null
          : {'source': _source, 'id': int.parse(_evidence.text.trim())},
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Resolve report'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _outcome,
                decoration: const InputDecoration(labelText: 'Outcome'),
                items: const [
                  DropdownMenuItem(
                    value: 'NO_ACTION',
                    child: Text('No action required'),
                  ),
                  DropdownMenuItem(
                    value: 'ACTION_TAKEN',
                    child: Text('Action already taken'),
                  ),
                ],
                onChanged: (value) => setState(() => _outcome = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summary,
                maxLength: 1000,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Summary visible to reporter',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a resolution summary.'
                    : null,
              ),
              TextFormField(
                controller: _notes,
                maxLength: 2000,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Internal notes (optional)',
                ),
              ),
              if (_outcome == 'ACTION_TAKEN') ...[
                const Text(
                  'Complete the moderation action first, then use its audit action ID. The server verifies the evidence.',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _source,
                  decoration: const InputDecoration(
                    labelText: 'Evidence source',
                  ),
                  items: [
                    for (final source in [
                      'ACCOUNT_MODERATION',
                      'CLUB_LIFECYCLE',
                      'PUBLICATION',
                    ])
                      DropdownMenuItem(
                        value: source,
                        child: Text(source.replaceAll('_', ' ')),
                      ),
                  ],
                  onChanged: (value) => setState(() => _source = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _evidence,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Committed action ID',
                  ),
                  validator: (value) =>
                      (int.tryParse(value?.trim() ?? '') ?? 0) > 0
                      ? null
                      : 'Enter a positive action ID.',
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Resolve report')),
    ],
  );
}
