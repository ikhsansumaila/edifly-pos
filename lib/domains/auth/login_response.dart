class LoginResponse {
  final bool status;
  final LoginData data;

  LoginResponse({required this.status, required this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(status: json['status'], data: LoginData.fromJson(json['data']));
  }
}

class LoginData {
  final int userId;
  final String role;
  final int outletId;
  final String token;

  LoginData({
    required this.userId,
    required this.role,
    required this.outletId,
    required this.token,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      userId: json['user_id'],
      role: json['role'],
      outletId: json['outlet_id'],
      token: json['token'],
    );
  }
}
