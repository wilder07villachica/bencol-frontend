class EmpresaRequest {
  final String ruc;
  final String razonSocial;
  final String? nombreComercial;
  final String? direccion;
  final String? telefono;
  final String? email;

  const EmpresaRequest({
    required this.ruc,
    required this.razonSocial,
    this.nombreComercial,
    this.direccion,
    this.telefono,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'ruc': ruc,
      'razonSocial': razonSocial,
      'nombreComercial': nombreComercial,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
    };
  }
}
