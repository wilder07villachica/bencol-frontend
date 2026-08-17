class Proveedor {
  final int id;
  final String razonSocial;
  final String ruc;
  final String? contacto;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String estado;

  const Proveedor({
    required this.id,
    required this.razonSocial,
    required this.ruc,
    required this.contacto,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.estado,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: (json['id'] as num).toInt(),
      razonSocial: json['razonSocial'] as String? ?? '',
      ruc: json['ruc'] as String? ?? '',
      contacto: json['contacto'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
      estado: json['estado'] as String? ?? '',
    );
  }
}
