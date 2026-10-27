import 'package:flutter/material.dart';
import 'package:uniconnect/features/mentorship/view/widgets/slot_time_fields.dart';
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
      barrierDismissible: false,
      builder: (_) => MentorshipSlotFormDialog(
        controller: controller,
        existingSlot: existingSlot,
      ),
    );
  }

  @override
  State<MentorshipSlotFormDialog> createState() =>
      _MentorshipSlotFormDialogState();
}

class _MentorshipSlotFormDialogState extends State<MentorshipSlotFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _topicController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _linkController;
  late final TextEditingController _capacityController;
  late final TextEditingController _meetingCountController;
  String? _recurrenceEndDate;

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
    _descriptionController = TextEditingController(
      text: slot?.description ?? '',
    );
    _locationController = TextEditingController(text: slot?.location ?? '');
    _linkController = TextEditingController(text: slot?.meetingLink ?? '');
    _capacityController = TextEditingController(
      text: slot?.capacity.toString() ?? '5',
    );

    _meetingCountController = TextEditingController(
      text: (slot?.meetingCount ?? 12).toString(),
    );
    _recurrenceEndDate = slot?.recurrenceEndDate;
    _scheduleType = slot?.scheduleType ?? ScheduleType.weekly;
    _mode = slot?.mode ?? SlotMode.online;
    _startDate = slot != null && slot.startDate.isNotEmpty
        ? DateTime.tryParse(slot.startDate) ??
              DateTime.now().add(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 1));
    _startTime = _parseTime(
      slot?.startTime,
      const TimeOfDay(hour: 14, minute: 0),
    );
    _endTime = _parseTime(slot?.endTime, const TimeOfDay(hour: 15, minute: 30));
  }

  TimeOfDay _parseTime(String? value, TimeOfDay fallback) {
    final parts = value?.split(':');
    if (parts == null || parts.length < 2) return fallback;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    _capacityController.dispose();
    _meetingCountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    if (_submitting || widget.controller.loading) return;
    final request = CreateSlotRequest(
      topic: _topicController.text,
      description: _descriptionController.text,
      scheduleType: _scheduleType,
      startDate: _formatDate(_startDate),
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      recurrenceEndDate: _scheduleType == ScheduleType.oneTime
          ? null
          : _recurrenceEndDate,
      meetingCount: _scheduleType == ScheduleType.oneTime
          ? 1
          : _recurrenceEndDate != null
          ? null
          : int.tryParse(_meetingCountController.text) ?? 0,
      mode: _mode,
      location: _mode == SlotMode.inPerson ? _locationController.text : null,
      meetingLink: _mode == SlotMode.online ? _linkController.text : null,
      capacity: int.tryParse(_capacityController.text) ?? 0,
    );
    final validation = request.validate();
    setState(() => _formError = validation);
    if (validation != null) return;
    setState(() => _submitting = true);
    final success = widget.isEditing
        ? await widget.controller.updateSlot(
            widget.existingSlot!.slotId,
            UpdateSlotRequest.fromCreate(request),
          )
        : await widget.controller.createSlot(request);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(
        () => _formError = widget.controller.error ?? 'Failed to save session.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PopScope(
      canPop: !_submitting,
      child: Dialog(
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
                      widget.isEditing
                          ? Icons.edit_calendar
                          : Icons.add_circle_outline,
                      color: colors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditing
                            ? 'Edit Mentorship Session'
                            : 'Publish Mentorship Session',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
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
                        Icon(
                          Icons.error_outline,
                          color: colors.error,
                          size: 20,
                        ),
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
                    child: AbsorbPointer(
                      absorbing: _submitting,
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
                                    isExpanded: true,
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
                                      if (val != null) {
                                        setState(() => _scheduleType = val);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<SlotMode>(
                                    initialValue: _mode,
                                    isExpanded: true,
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
                                      if (val != null) {
                                        setState(() => _mode = val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SlotTimeFields(
                              date: _startDate,
                              start: _startTime,
                              end: _endTime,
                              onDateChanged: (value) =>
                                  setState(() => _startDate = value),
                              onStartChanged: (value) =>
                                  setState(() => _startTime = value),
                              onEndChanged: (value) =>
                                  setState(() => _endTime = value),
                            ),
                            if (_scheduleType != ScheduleType.oneTime) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _meetingCountController,
                                enabled: _recurrenceEndDate == null,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Number of meetings (1–52)',
                                  helperText: _recurrenceEndDate == null
                                      ? 'A finite series. Joining covers remaining unstarted meetings.'
                                      : 'Series ends by $_recurrenceEndDate.',
                                  helperMaxLines: 3,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              if (_recurrenceEndDate != null)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _recurrenceEndDate = null),
                                  child: const Text('Use meeting count only'),
                                ),
                            ],
                            const SizedBox(height: 14),
                            if (_mode == SlotMode.online)
                              TextFormField(
                                controller: _linkController,
                                decoration: const InputDecoration(
                                  labelText: 'Meeting Link',
                                  hintText:
                                      'https://meet.google.com/xxx-yyyy-zzz',
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
                ),
                const Divider(),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
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
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Save Changes'
                                  : 'Publish Session',
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
