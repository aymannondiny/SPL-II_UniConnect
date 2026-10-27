part of 'clubs_page.dart';

class _ClubRequestDialog extends StatefulWidget {
  const _ClubRequestDialog();
  @override
  State<_ClubRequestDialog> createState() => _ClubRequestDialogState();
}

class _ClubRequestDialogState extends State<_ClubRequestDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _logo = TextEditingController();
  final _email = TextEditingController();
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
    title: const Text('Request a new club'),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Proposed club name',
                ),
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
                maxLength: 2048,
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
              const SizedBox(height: 8),
              Text(
                'A system administrator reviews the proposal. Club administrator access begins only after approval.',
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
          Navigator.pop(context, <String, String?>{
            'name': _name.text.trim(),
            'category': _category.text.trim(),
            'description': _description.text.trim(),
            'logo': _logo.text.trim().isEmpty ? null : _logo.text.trim(),
            'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
          });
        },
        child: const Text('Submit request'),
      ),
    ],
  );
}
