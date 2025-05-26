class GoogleCheckResponse {
  final bool isRegistered;
  final String? accessToken;
  final String? email;
  final String? name;
  final String? googleId;

  GoogleCheckResponse({
    required this.isRegistered,
    this.accessToken,
    this.email,
    this.name,
    this.googleId,
  });

  factory GoogleCheckResponse.fromJson(Map<String, dynamic> json) {
    return GoogleCheckResponse(
      isRegistered: json['isRegistered'] ?? false,
      accessToken: json['accessToken'],
      email: json['email'],
      name: json['name'],
      googleId: json['googleId'],
    );
  }
}

class AuthResponse {
  final String token;
  final String username;
  final String email;
  final bool isPremium;

  AuthResponse({
    required this.token,
    required this.username,
    required this.email,
    required this.isPremium,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      username: json['username'],
      email: json['email'],
      isPremium: json['isPremium'] ?? false,
    );
  }
}