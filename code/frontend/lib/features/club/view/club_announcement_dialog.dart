part of 'club_management_panel.dart';

class _AnnouncementData {
  const _AnnouncementData(
    this.title,
    this.content,
    this.priority,
    this.expiresAt,
    this.publishNow,
  );
  final String title, content, priority;
  final DateTime? expiresAt;
  final bool publishNow;
}

class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog({this.item, required this.canPublish});
  final ClubAnnouncement? item;
  final bool canPublish;
  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item?.title ?? '');
  late final _content = TextEditingController(text: widget.item?.content ?? '');
  late final _expiry = TextEditingController(
    text:
        widget.item?.expiresAt?.toLocal().toIso8601String().substring(0, 16) ??
        '',
  );
  late String _priority = widget.item?.priority ?? 'NORMAL';
  bool _publish = false;
  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _expiry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'New announcement' : 'Edit announcement'),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _content,
                maxLength: 10000,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(labelText: 'Announcement'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                  DropdownMenuItem(
                    value: 'IMPORTANT',
                    child: Text('Important'),
                  ),
                  DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                ],
                onChanged: (value) =>
                    setState(() => _priority = value ?? _priority),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expiry,
                decoration: const InputDecoration(
                  labelText: 'Expiry (optional)',
                  hintText: 'YYYY-MM-DDTHH:MM',
                ),
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        DateTime.tryParse(value.trim()) == null
                    ? 'Use YYYY-MM-DDTHH:MM.'
                    : null,
              ),
              if (widget.item == null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publish immediately'),
                  value: _publish,
                  onChanged: widget.canPublish
                      ? (value) => setState(() => _publish = value)
                      : null,
                ),
                if (!widget.canPublish)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Publishing is paused. This announcement will remain a draft.',
                    ),
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
      FilledButton(
        onPressed: () {
          if (!(_form.currentState?.validate() ?? false)) return;
          final expiry = _expiry.text.trim().isEmpty
              ? null
              : DateTime.parse(_expiry.text.trim());
          Navigator.pop(
            context,
            _AnnouncementData(
              _title.text.trim(),
              _content.text.trim(),
              _priority,
              expiry,
              _publish,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}
