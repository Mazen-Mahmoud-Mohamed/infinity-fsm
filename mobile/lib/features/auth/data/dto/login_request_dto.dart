class LoginRequestDto {
  const LoginRequestDto({
    required this.email,
    required this.password,
    required this.deviceId,
    required this.deviceInfo,
  });

  final String email;
  final String password;
  final String deviceId;
  final Map<String, String> deviceInfo;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'deviceId': deviceId,
      'deviceInfo': deviceInfo,
    };
  }
}
