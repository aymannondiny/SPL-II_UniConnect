class CurrentAccount {
  const CurrentAccount({
    required this.userId,
    required this.fullName,
    required this.email,
    this.platformRole = 'STUDENT',
  });

  final int userId;
  final String fullName;
  final String email;
  final String platformRole;

  factory CurrentAccount.fromJson(Map<String, dynamic> json) {
    if (json['accountStatus'] != 'ACTIVE') {
      throw const FormatException('Account is not active');
    }
    return CurrentAccount(
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      platformRole: json['platformRole'] as String,
    );
  }
}
