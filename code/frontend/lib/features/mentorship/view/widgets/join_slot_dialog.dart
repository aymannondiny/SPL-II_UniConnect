import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/model/enroll_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';

class JoinSlotDialog extends StatefulWidget {
  const JoinSlotDialog({
    required this.slot,
    required this.controller,
    super.key,
  });

  final MentorshipSlotSummary slot;
  final MentorshipController controller;

  static Future<bool?> show(
    BuildContext context, {
    required MentorshipSlotSummary slot,
    required MentorshipController controller,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => JoinSlotDialog(slot: slot, controller: controller),
    );
  }

  @override
  State<JoinSlotDialog> createState() => _JoinSlotDialogState();
}

class _JoinSlotDialogState extends State<JoinSlotDialog> {
  final _messageController = TextEditingController();
  final _goalController = TextEditingController();
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    final msg = _messageController.text.trim();
    final goal = _goalController.text.trim();

    if (msg.length > 300) {
      setState(() => _formError = 'Message must be under 300 characters.');
      return;
    }
    if (goal.length > 1000) {
      setState(
        () => _formError = 'Learning goal must be under 1000 characters.',
      );
      return;
    }

    setState(() => _submitting = true);
    final request = EnrollSlotRequest(
      joinMessage: msg.isNotEmpty ? msg : null,
      learningGoal: goal.isNotEmpty ? goal : null,
    );

    final success = await widget.controller.joinSlot(
      widget.slot.slotId,
      request,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(
        () => _formError = widget.controller.error ?? 'Failed to join session.',
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
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add_alt_1, color: colors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Join Mentorship Session',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Reserve your spot for "${widget.slot.topic}" with ${widget.slot.mentorName}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (_formError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formError!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Introduction Message (Optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _messageController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'A brief greeting or note to your mentor...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Learning Goals (Optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _goalController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'What questions or specific topics would you like to cover?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
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
                        : const Text('Confirm & Join'),
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
