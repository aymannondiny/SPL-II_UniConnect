class CurrentAccount {
  const CurrentAccount({
    required this.fullName,
    required this.email,
    this.platformRole = 'STUDENT',
  });

  final String fullName;
  final String email;
  final String platformRole;

  factory CurrentAccount.fromJson(Map<String, dynamic> json) {
    if (json['accountStatus'] != 'ACTIVE') {
      throw const FormatException('Account is not active');
    }
    return CurrentAccount(
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      platformRole: json['platformRole'] as String,
    );
  }
}
