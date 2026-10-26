import 'dart:convert';

/// Local heuristic, not a breached-password lookup or an entropy guarantee.
abstract final class PasswordPolicy {
  static String? validate(String? value) {
    final password = value ?? '';
    if (password.length < 8 ||
        password.length > 72 ||
        utf8.encode(password).length > 72) {
      return 'Use 8–72 characters and at most 72 UTF-8 bytes.';
    }
    if (isPredictable(password)) {
      return 'Avoid common words, sequences, repeated patterns and numbers only.';
    }
    return null;
  }

  static bool isPredictable(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't')
        .replaceAll('@', 'a')
        .replaceAll(r'$', 's');
    if (value.trim().isEmpty || RegExp(r'^\d+$').hasMatch(value)) return true;
    for (final word in [
      'password',
      'qwerty',
      'letmein',
      'welcome',
      'admin',
      'iloveyou',
      'uniconnect',
      'abcde',
    ]) {
      if (normalized.contains(word)) return true;
    }
    if (RegExp(r'(.)\1{3,}').hasMatch(value)) return true;
    for (var length = 1; length <= value.length ~/ 2; length++) {
      if (value.substring(0, length) * (value.length ~/ length) == value) {
        return true;
      }
    }
    const sequences = [
      'abcdefghijklmnopqrstuvwxyz',
      '0123456789',
      'qwertyuiop',
      'asdfghjkl',
      'zxcvbnm',
    ];
    final lower = value.toLowerCase();
    for (final sequence in sequences) {
      final reversed = sequence.split('').reversed.join();
      for (var index = 0; index + 4 <= lower.length; index++) {
        final part = lower.substring(index, index + 4);
        if (sequence.contains(part) || reversed.contains(part)) return true;
      }
    }
    return false;
  }

  static int strength(String value) {
    if (value.isEmpty) return 0;
    if (validate(value) != null) return 1;
    final categories = [
      RegExp(r'[a-z]'),
      RegExp(r'[A-Z]'),
      RegExp(r'[0-9]'),
      RegExp(r'[^a-zA-Z0-9\s]'),
    ].where((pattern) => pattern.hasMatch(value)).length;
    final words = value.trim().toLowerCase().split(RegExp(r'\s+')).toSet();
    final passphrase =
        words.length >= 4 &&
        value.trim().length >= 20 &&
        words.every((word) => RegExp(r'^[a-z]{3,}$').hasMatch(word));
    if (passphrase || (value.trim().length >= 12 && categories >= 3)) return 4;
    if (value.trim().length >= 12 || categories >= 3) return 3;
    return 2;
  }
}
