class LoginResponse {
  final int usuarioId;
  final String username;
  final String email;
  final String rol;
  final String tipoToken;
  final String token;

  const LoginResponse({
    required this.usuarioId,
    required this.username,
    required this.email,
    required this.rol,
    required this.tipoToken,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      usuarioId: json['usuarioId'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
      tipoToken: json['tipoToken'] as String,
      token: json['token'] as String,
    );
  }
}
