class LoginResponse {
  final bool status;
  final String message;
  final LoginData data;

  LoginResponse({required this.status, required this.message, required this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'],
      message: json['message'],
      data: LoginData.fromJson(json['data']),
    );
  }
}

class LoginData {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String outletId;
  final String namaOutlet;
  final String token;

  LoginData({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.outletId,
    required this.namaOutlet,
    required this.token,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      outletId: json['outlet_id'],
      namaOutlet: json['nama_outlet'],
      token: json['token'],
    );
  }
}
