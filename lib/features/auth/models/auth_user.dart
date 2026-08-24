class AuthUser {
  final int usuarioId;
  final String username;
  final String email;
  final String rol;

  const AuthUser({
    required this.usuarioId,
    required this.username,
    required this.email,
    required this.rol,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      usuarioId: (json['usuarioId'] as num).toInt(),
      username: json['username'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
    );
  }
}
