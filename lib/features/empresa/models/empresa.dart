class Empresa {
  final int id;
  final String ruc;
  final String razonSocial;
  final String? nombreComercial;
  final String? direccion;
  final String? telefono;
  final String? email;
  final String? logoNombre;
  final String? logoTipo;
  final bool tieneLogo;
  final String? estado;

  const Empresa({
    required this.id,
    required this.ruc,
    required this.razonSocial,
    this.nombreComercial,
    this.direccion,
    this.telefono,
    this.email,
    this.logoNombre,
    this.logoTipo,
    required this.tieneLogo,
    this.estado,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: (json['id'] as num).toInt(),
      ruc: json['ruc'] as String,
      razonSocial: json['razonSocial'] as String,
      nombreComercial: json['nombreComercial'] as String?,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      logoNombre: json['logoNombre'] as String?,
      logoTipo: json['logoTipo'] as String?,
      tieneLogo: json['tieneLogo'] == true,
      estado: json['estado'] as String?,
    );
  }
}
