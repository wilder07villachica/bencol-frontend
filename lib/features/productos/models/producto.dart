class Producto {
  final int id;
  final String codigo;
  final String descripcion;
  final String categoria;
  final double contenido;
  final String unidadMedida;
  final int unidadesPorPaquete;
  final double precioBase;
  final String? estado;

  const Producto({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.categoria,
    required this.contenido,
    required this.unidadMedida,
    required this.unidadesPorPaquete,
    required this.precioBase,
    required this.estado,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      contenido: (json['contenido'] as num?)?.toDouble() ?? 0,
      unidadMedida: json['unidadMedida'] as String? ?? '',
      unidadesPorPaquete: (json['unidadesPorPaquete'] as num?)?.toInt() ?? 1,
      precioBase: (json['precioBase'] as num?)?.toDouble() ?? 0,
      estado: json['estado'] as String?,
    );
  }
}
