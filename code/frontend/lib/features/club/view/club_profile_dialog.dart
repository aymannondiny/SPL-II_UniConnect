part of 'club_management_panel.dart';

class _ProfileData {
  const _ProfileData(
    this.name,
    this.category,
    this.description,
    this.logoUrl,
    this.contactEmail,
  );
  final String name, category, description;
  final String? logoUrl, contactEmail;
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.club});
  final Club club;
  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.club.name);
  late final _category = TextEditingController(text: widget.club.category);
  late final _description = TextEditingController(
    text: widget.club.description,
  );
  late final _logo = TextEditingController(text: widget.club.logoUrl ?? '');
  late final _email = TextEditingController(
    text: widget.club.contactEmail ?? '',
  );
  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _logo.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required.' : null;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit club profile'),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'Club name'),
                validator: _required,
              ),
              TextFormField(
                controller: _category,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: _required,
              ),
              TextFormField(
                controller: _description,
                maxLength: 5000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: _required,
              ),
              TextFormField(
                controller: _logo,
                decoration: const InputDecoration(
                  labelText: 'Logo URL (optional)',
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
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Contact email (optional)',
                ),
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        !value.contains('@')
                    ? 'Enter a valid email.'
                    : null,
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
          Navigator.pop(
            context,
            _ProfileData(
              _name.text.trim(),
              _category.text.trim(),
              _description.text.trim(),
              _logo.text.trim().isEmpty ? null : _logo.text.trim(),
              _email.text.trim().isEmpty ? null : _email.text.trim(),
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}
