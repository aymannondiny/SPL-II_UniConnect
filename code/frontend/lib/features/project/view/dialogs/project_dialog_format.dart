part of '../project_dialogs.dart';

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);
  final value = parts.map((part) => part[0]).join();
  return value.isEmpty ? 'U' : value.toUpperCase();
}

String _humanize(String value) => value
    .toLowerCase()
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _shortDate(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return '';
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _formatDateString(String value) {
  final date = DateTime.tryParse(value);
  return date == null ? value : _formatDate(date);
}
