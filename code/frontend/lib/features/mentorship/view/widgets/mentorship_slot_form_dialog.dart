import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/controller/mentorship_controller.dart';
import 'package:uniconnect/features/mentorship/model/create_slot_request.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_enums.dart';
import 'package:uniconnect/features/mentorship/model/mentorship_slot_summary.dart';
import 'package:uniconnect/features/mentorship/model/update_slot_request.dart';

class MentorshipSlotFormDialog extends StatefulWidget {
  const MentorshipSlotFormDialog({
    required this.controller,
    this.existingSlot,
    super.key,
  });

  final MentorshipController controller;
  final MentorshipSlotSummary? existingSlot;

  bool get isEditing => existingSlot != null;

  static Future<bool?> show(
    BuildContext context, {
    required MentorshipController controller,
    MentorshipSlotSummary? existingSlot,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => MentorshipSlotFormDialog(
        controller: controller,
        existingSlot: existingSlot,
      ),
    );
  }

  @override
  State<MentorshipSlotFormDialog> createState() => _MentorshipSlotFormDialogState();
}

class _MentorshipSlotFormDialogState extends State<MentorshipSlotFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _topicController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _linkController;
  late final TextEditingController _capacityController;

  late ScheduleType _scheduleType;
  late SlotMode _mode;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  String? _formError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final slot = widget.existingSlot;
    _topicController = TextEditingController(text: slot?.topic ?? '');
    _descriptionController = TextEditingController(text: slot?.description ?? '');
    _locationController = TextEditingController(text: slot?.location ?? '');
    _linkController = TextEditingController(text: slot?.meetingLink ?? '');
    _capacityController = TextEditingController(text: slot?.capacity.toString() ?? '5');

    _scheduleType = slot?.scheduleType ?? ScheduleType.weekly;
    _mode = slot?.mode ?? SlotMode.online;
    _startDate = slot != null && slot.startDate.isNotEmpty
        ? DateTime.tryParse(slot.startDate) ?? DateTime.now().add(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 1));
    _startTime = const TimeOfDay(hour: 14, minute: 0);
    _endTime = const TimeOfDay(hour: 15, minute: 30);
  }

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    setState(() => _formError = null);
    final topic = _topicController.text.trim();
    final desc = _descriptionController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

    if (topic.length < 2 || topic.length > 200) {
      setState(() => _formError = 'Topic must be between 2 and 200 characters.');
      return;
    }
    if (desc.length < 5 || desc.length > 2000) {
      setState(() => _formError = 'Description must be between 5 and 2000 characters.');
      return;
    }
    if (capacity < 1 || capacity > 50) {
      setState(() => _formError = 'Capacity must be between 1 and 50 participants.');
      return;
    }
    if (_mode == SlotMode.online && _linkController.text.trim().isEmpty) {
      setState(() => _formError = 'Meeting link is required for online sessions.');
      return;
    }
    if (_mode == SlotMode.inPerson && _locationController.text.trim().isEmpty) {
      setState(() => _formError = 'Location is required for in-person sessions.');
      return;
    }

    setState(() => _submitting = true);
    bool success;
    if (widget.isEditing) {
      final req = UpdateSlotRequest(
        topic: topic,
        description: desc,
        scheduleType: _scheduleType,
        startDate: _formatDate(_startDate),
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        mode: _mode,
        location: _mode == SlotMode.inPerson ? _locationController.text.trim() : null,
        meetingLink: _mode == SlotMode.online ? _linkController.text.trim() : null,
        capacity: capacity,
      );
      success = await widget.controller.updateSlot(widget.existingSlot!.slotId, req);
    } else {
      final req = CreateSlotRequest(
        topic: topic,
        description: desc,
        scheduleType: _scheduleType,
        startDate: _formatDate(_startDate),
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        mode: _mode,
        location: _mode == SlotMode.inPerson ? _locationController.text.trim() : null,
        meetingLink: _mode == SlotMode.online ? _linkController.text.trim() : null,
        capacity: capacity,
      );
      success = await widget.controller.createSlot(req);
    }

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _formError = widget.controller.error ?? 'Failed to save session.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isEditing ? Icons.edit_calendar : Icons.add_circle_outline,
                    color: colors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isEditing ? 'Edit Mentorship Session' : 'Publish Mentorship Session',
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
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formError!,
                          style: TextStyle(color: Colors.red.shade900, fontSize: 13),
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
                        TextFormField(
                          controller: _topicController,
                          decoration: const InputDecoration(
                            labelText: 'Topic / Subject Title',
                            hintText: 'e.g. Graph Algorithms Practice',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Session Description & Goals',
                            hintText: 'Explain what you will teach and discuss with mentees...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<ScheduleType>(
                                initialValue: _scheduleType,
                                decoration: const InputDecoration(
                                  labelText: 'Schedule Type',
                                  border: OutlineInputBorder(),
                                ),
                                items: ScheduleType.values.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type.label),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _scheduleType = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<SlotMode>(
                                initialValue: _mode,
                                decoration: const InputDecoration(
                                  labelText: 'Mode',
                                  border: OutlineInputBorder(),
                                ),
                                items: SlotMode.values.map((mode) {
                                  return DropdownMenuItem(
                                    value: mode,
                                    child: Text(mode.label),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _mode = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setState(() => _startDate = picked);
                                  }
                                },
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text('Date: ${_formatDate(_startDate)}'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _startTime,
                                  );
                                  if (picked != null) {
                                    setState(() => _startTime = picked);
                                  }
                                },
                                icon: const Icon(Icons.access_time, size: 16),
                                label: Text('Start: ${_formatTime(_startTime).substring(0, 5)}'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_mode == SlotMode.online)
                          TextFormField(
                            controller: _linkController,
                            decoration: const InputDecoration(
                              labelText: 'Meeting Link',
                              hintText: 'https://meet.google.com/xxx-yyyy-zzz',
                              border: OutlineInputBorder(),
                            ),
                          )
                        else
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Meeting Location / Room',
                              hintText: 'e.g. Science Complex Lab 3',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _capacityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Capacity (1 to 50 mentees)',
                            border: OutlineInputBorder(),
                          ),
                        ),
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
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
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
                        : Text(widget.isEditing ? 'Save Changes' : 'Publish Session'),
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
