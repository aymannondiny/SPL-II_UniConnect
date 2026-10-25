/// Formats campus wall-clock times without converting them to the device zone.
/// The API's schedule timestamps are local to Asia/Dhaka.
String mentorshipScheduleLabel({
  required String schedule,
  required String startDate,
  required String startTime,
  DateTime? ongoing,
  DateTime? next,
}) {
  final occurrence = ongoing ?? next;
  if (occurrence != null) {
    final date = occurrence.toIso8601String().substring(0, 10);
    final time = occurrence.toIso8601String().substring(11, 16);
    return '${ongoing != null ? 'Ongoing' : 'Next'}: $date at $time · Asia/Dhaka';
  }
  final time = startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
  return '$schedule · Starts $startDate at $time · Asia/Dhaka';
}
