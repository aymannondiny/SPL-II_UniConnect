part of '../project_dialogs.dart';

class ProjectApplyDialog extends StatefulWidget {
  const ProjectApplyDialog({required this.project, super.key});
  final ProjectListing project;

  @override
  State<ProjectApplyDialog> createState() => _ProjectApplyDialogState();
}

class _ProjectApplyDialogState extends State<ProjectApplyDialog> {
  final _message = TextEditingController();
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Apply to join'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.project.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _message,
            maxLength: 500,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Message to the project owner (optional)',
              hintText: 'Share how you could contribute.',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: () => Navigator.pop(context, _message.text.trim()),
        icon: const Icon(Icons.send_outlined, size: 18),
        label: const Text('Send application'),
      ),
    ],
  );
}
