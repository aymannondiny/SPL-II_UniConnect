String chatShortTime(DateTime time) {
  final now = DateTime.now();
  if (now.difference(time).inDays == 0 && now.day == time.day) {
    return chatClockTime(time);
  }
  if (now.difference(time).inDays < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[time.weekday - 1];
  }
  return '${time.month}/${time.day}';
}

String chatClockTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
}
