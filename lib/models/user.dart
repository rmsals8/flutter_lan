class User {
  final int id;
  final String username;
  final String email;
  final bool isPremium;
  final int dailyUsageCount;
  final String? subscriptionStatus;
  final String? subscriptionEndDate;
  final int? loginType;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.isPremium,
    required this.dailyUsageCount,
    this.subscriptionStatus,
    this.subscriptionEndDate,
    this.loginType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      isPremium: json['isPremium'] ?? false,
      dailyUsageCount: json['dailyUsageCount'] ?? 0,
      subscriptionStatus: json['subscriptionStatus'],
      subscriptionEndDate: json['subscriptionEndDate'],
      loginType: json['loginType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'isPremium': isPremium,
      'dailyUsageCount': dailyUsageCount,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionEndDate': subscriptionEndDate,
      'loginType': loginType,
    };
  }

  // 소셜 로그인 사용자인지 확인
  bool get isSocialUser => loginType == 1;
}