class ModeratedAccount {
  ModeratedAccount.fromJson(Map<String, dynamic> json)
    : id = (json['userId'] as num).toInt(),
      name = json['fullName'] as String,
      email = json['email'] as String,
      role = json['platformRole'] as String,
      status = json['accountStatus'] as String;

  final int id;
  final String name;
  final String email;
  final String role;
  final String status;

  bool get canSuspend => role != 'SYSTEM_ADMIN' && status == 'ACTIVE';
  bool get canRestore => role != 'SYSTEM_ADMIN' && status == 'SUSPENDED';
}
