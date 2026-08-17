class ProveedorRequest {
  final String razonSocial;
  final String ruc;
  final String? contacto;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? estado;

  const ProveedorRequest({
    required this.razonSocial,
    required this.ruc,
    this.contacto,
    this.telefono,
    this.email,
    this.direccion,
    this.estado,
  });

  Map<String, dynamic> toJson() {
    return {
      'razonSocial': razonSocial.trim(),
      'ruc': ruc.trim(),
      if (contacto != null && contacto!.trim().isNotEmpty)
        'contacto': contacto!.trim(),
      if (telefono != null && telefono!.trim().isNotEmpty)
        'telefono': telefono!.trim(),
      if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
      if (direccion != null && direccion!.trim().isNotEmpty)
        'direccion': direccion!.trim(),
      if (estado != null) 'estado': estado,
    };
  }
}
