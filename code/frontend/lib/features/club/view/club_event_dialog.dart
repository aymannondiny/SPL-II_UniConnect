part of 'club_management_panel.dart';

class _EventData {
  const _EventData(
    this.title,
    this.description,
    this.location,
    this.registrationUrl,
    this.registrationDeadline,
    this.startsAt,
    this.endsAt,
  );
  final String title, description;
  final String? location, registrationUrl;
  final DateTime? registrationDeadline;
  final DateTime startsAt, endsAt;
}

class _EventDialog extends StatefulWidget {
  const _EventDialog({this.item});
  final ClubEvent? item;
  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item?.title ?? '');
  late final _description = TextEditingController(
    text: widget.item?.description ?? '',
  );
  late final _location = TextEditingController(
    text: widget.item?.location ?? '',
  );
  late final _url = TextEditingController(
    text: widget.item?.registrationUrl ?? '',
  );
  late final _deadline = TextEditingController(
    text:
        widget.item?.registrationDeadline
            ?.toLocal()
            .toIso8601String()
            .substring(0, 16) ??
        '',
  );
  late final _starts = TextEditingController(
    text: _dateInput(widget.item?.startsAt),
  );
  late final _ends = TextEditingController(
    text: _dateInput(widget.item?.endsAt),
  );
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _url.dispose();
    _deadline.dispose();
    _starts.dispose();
    _ends.dispose();
    super.dispose();
  }

  static String _dateInput(DateTime? date) =>
      date?.toLocal().toIso8601String().substring(0, 16) ?? '';
  String? _validateDate(String? value) =>
      DateTime.tryParse(value?.trim() ?? '') == null
      ? 'Use YYYY-MM-DDTHH:MM.'
      : null;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'New event' : 'Edit event'),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Event title'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLength: 10000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _starts,
                decoration: const InputDecoration(
                  labelText: 'Starts at',
                  hintText: 'YYYY-MM-DDTHH:MM',
                ),
                validator: _validateDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ends,
                decoration: const InputDecoration(
                  labelText: 'Ends at',
                  hintText: 'YYYY-MM-DDTHH:MM',
                ),
                validator: _validateDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _url,
                maxLength: 2048,
                decoration: const InputDecoration(
                  labelText: 'External registration URL (optional)',
                ),
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        Uri.tryParse(value.trim())?.scheme != 'https'
                    ? 'Use an HTTPS URL.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deadline,
                decoration: const InputDecoration(
                  labelText: 'Registration deadline (optional)',
                  hintText: 'YYYY-MM-DDTHH:MM',
                ),
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        DateTime.tryParse(value.trim()) == null
                    ? 'Use YYYY-MM-DDTHH:MM.'
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Time is entered in your local timezone and saved using UniConnect’s UTC convention.',
                style: Theme.of(context).textTheme.bodySmall,
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
        onPressed: () {
          if (!(_form.currentState?.validate() ?? false)) return;
          final starts = DateTime.parse(_starts.text.trim());
          final ends = DateTime.parse(_ends.text.trim());
          if (!ends.isAfter(starts)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End time must be after start time.'),
              ),
            );
            return;
          }
          final deadline = _deadline.text.trim().isEmpty
              ? null
              : DateTime.parse(_deadline.text.trim());
          Navigator.pop(
            context,
            _EventData(
              _title.text.trim(),
              _description.text.trim(),
              _location.text.trim().isEmpty ? null : _location.text.trim(),
              _url.text.trim().isEmpty ? null : _url.text.trim(),
              deadline,
              starts,
              ends,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required.' : null;
