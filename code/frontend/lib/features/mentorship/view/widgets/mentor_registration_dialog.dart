import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/model/mentor_registration_request.dart';

class MentorRegistrationDialog extends StatefulWidget {
  const MentorRegistrationDialog({required this.controller, super.key});

  final MentorshipController controller;

  static Future<bool?> show(
    BuildContext context, {
    required MentorshipController controller,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => MentorRegistrationDialog(controller: controller),
    );
  }

  @override
  State<MentorRegistrationDialog> createState() =>
      _MentorRegistrationDialogState();
}

class _MentorRegistrationDialogState extends State<MentorRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final List<TextEditingController> _topicControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _descControllers = [
    TextEditingController(),
  ];
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _bioController.dispose();
    for (final c in _topicControllers) {
      c.dispose();
    }
    for (final c in _descControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addTopic() {
    setState(() {
      _topicControllers.add(TextEditingController());
      _descControllers.add(TextEditingController());
    });
  }

  void _removeTopic(int index) {
    if (_topicControllers.length <= 1) return;
    setState(() {
      _topicControllers.removeAt(index).dispose();
      _descControllers.removeAt(index).dispose();
    });
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    final bio = _bioController.text.trim();
    if (bio.length < 10) {
      setState(
        () => _formError = 'Mentoring bio must be at least 10 characters.',
      );
      return;
    }

    final expertiseList = <MentorExpertiseInput>[];
    for (int i = 0; i < _topicControllers.length; i++) {
      final topic = _topicControllers[i].text.trim();
      final desc = _descControllers[i].text.trim();
      if (topic.isNotEmpty) {
        expertiseList.add(
          MentorExpertiseInput(
            topic: topic,
            description: desc.isNotEmpty ? desc : null,
          ),
        );
      }
    }

    if (expertiseList.isEmpty) {
      setState(
        () => _formError = 'Please specify at least one expertise topic.',
      );
      return;
    }

    setState(() => _submitting = true);
    final request = MentorRegistrationRequest(
      mentoringBio: bio,
      expertise: expertiseList,
    );
    final success = await widget.controller.registerMentor(request);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(
        () => _formError = widget.controller.error ?? 'Registration failed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: colors.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Become a Peer Mentor',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Share your academic and professional knowledge with fellow students.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (_formError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.error.withValues(alpha: .4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formError!,
                          style: TextStyle(
                            color: colors.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mentoring Bio',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Describe your background, academic achievements, and how you can support mentees...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Expertise Topics',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _addTopic,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Topic'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_topicControllers.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _topicControllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Topic ${index + 1}',
                                      hintText: 'e.g. Data Structures',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _descControllers[index],
                                    decoration: const InputDecoration(
                                      labelText: 'Description (optional)',
                                      hintText: 'e.g. Trees, graphs',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (_topicControllers.length > 1) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: colors.error,
                                    ),
                                    onPressed: () => _removeTopic(index),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Register as Mentor'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
