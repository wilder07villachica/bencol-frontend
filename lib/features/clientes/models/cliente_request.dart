class ClienteRequest {
  final String nombre;
  final String direccion;
  final String telefono;
  final String email;
  final String? categoria;
  final String? estado;

  const ClienteRequest({
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.email,
    this.categoria,
    this.estado,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'categoria': categoria,
      'estado': estado,
    };
  }
}
