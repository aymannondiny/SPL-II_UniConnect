import 'package:flutter/material.dart';

class AccountTransitionDialog extends StatefulWidget {
  const AccountTransitionDialog({
    required this.name,
    required this.suspend,
    super.key,
  });
  final String name;
  final bool suspend;

  @override
  State<AccountTransitionDialog> createState() =>
      _AccountTransitionDialogState();
}

class _AccountTransitionDialogState extends State<AccountTransitionDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.suspend ? 'Suspend' : 'Restore'} ${widget.name}?'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.suspend
                    ? 'Suspension signs the member out of all sessions and suspends publishing for clubs they administer.'
                    : 'The member can sign in again. Club publishing requires a separate restoration.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reason,
                maxLength: 1000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a reason for the audit history.'
                    : null,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _confirmed,
                title: const Text('I confirm this account action.'),
                onChanged: (value) => setState(() => _confirmed = value!),
              ),
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
      FilledButton(
        onPressed: !_confirmed
            ? null
            : () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(context, _reason.text.trim());
                }
              },
        child: Text(widget.suspend ? 'Suspend account' : 'Restore account'),
      ),
    ],
  );
}
