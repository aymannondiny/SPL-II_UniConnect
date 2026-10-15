enum RegistrationRole {
  student('STUDENT', 'Student'),
  alumni('ALUMNI', 'Alumni');

  const RegistrationRole(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class RegistrationRequest {
  const RegistrationRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  final String fullName;
  final String email;
  final String password;
  final RegistrationRole role;

  Map<String, Object> toJson() => {
    'fullName': fullName.trim(),
    'email': email.trim().toLowerCase(),
    'password': password,
    'platformRole': role.apiValue,
  };
}

class RegistrationResult {
  const RegistrationResult({required this.email, required this.accountStatus});

  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    return RegistrationResult(
      email: json['email'] as String,
      accountStatus: json['accountStatus'] as String,
    );
  }

  final String email;
  final String accountStatus;
}

class RegistrationFailure implements Exception {
  const RegistrationFailure(this.message, {this.fieldErrors = const {}});

  final String message;
  final Map<String, String> fieldErrors;
}
