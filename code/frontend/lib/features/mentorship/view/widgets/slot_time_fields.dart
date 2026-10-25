import 'package:flutter/material.dart';

/// Campus-local date and time inputs shared by new and existing series.
class SlotTimeFields extends StatelessWidget {
  const SlotTimeFields({
    required this.date,
    required this.start,
    required this.end,
    required this.onDateChanged,
    required this.onStartChanged,
    required this.onEndChanged,
    super.key,
  });

  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;

  String _time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> changed,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (context.mounted && picked != null) changed(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('All meeting dates and times use Asia/Dhaka (UTC+06:00).'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final today = DateUtils.dateOnly(
                  DateTime.now().toUtc().add(const Duration(hours: 6)),
                );
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: date.isBefore(today) ? date : today,
                  lastDate: today.add(const Duration(days: 730)),
                );
                if (context.mounted && picked != null) onDateChanged(picked);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('Date: ${date.toIso8601String().substring(0, 10)}'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickTime(context, start, onStartChanged),
              icon: const Icon(Icons.access_time, size: 16),
              label: Text('Start: ${_time(start)}'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickTime(context, end, onEndChanged),
              icon: const Icon(Icons.access_time, size: 16),
              label: Text('End: ${_time(end)}'),
            ),
          ],
        ),
      ],
    );
  }
}
