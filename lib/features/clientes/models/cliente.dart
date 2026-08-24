class Cliente {
  final int id;
  final String nombre;
  final String direccion;
  final String telefono;
  final String email;
  final String? categoria;
  final String? estado;

  const Cliente({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.email,
    required this.categoria,
    required this.estado,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      email: json['email'] as String? ?? '',
      categoria: json['categoria'] as String?,
      estado: json['estado'] as String?,
    );
  }
}
