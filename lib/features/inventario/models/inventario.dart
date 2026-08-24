class Inventario {
  final int id;
  final int productoId;
  final String codigoProducto;
  final String descripcionProducto;
  final int stockActual;
  final int? stockMinimo;
  final int? stockMaximo;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const Inventario({
    required this.id,
    required this.productoId,
    required this.codigoProducto,
    required this.descripcionProducto,
    required this.stockActual,
    required this.stockMinimo,
    required this.stockMaximo,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Inventario.fromJson(Map<String, dynamic> json) {
    return Inventario(
      id: (json['id'] as num).toInt(),
      productoId: (json['productoId'] as num).toInt(),
      codigoProducto: json['codigoProducto'] as String? ?? '',
      descripcionProducto: json['descripcionProducto'] as String? ?? '',
      stockActual: (json['stockActual'] as num?)?.toInt() ?? 0,
      stockMinimo: (json['stockMinimo'] as num?)?.toInt(),
      stockMaximo: (json['stockMaximo'] as num?)?.toInt(),
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'].toString())
          : null,
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.tryParse(json['fechaActualizacion'].toString())
          : null,
    );
  }
}
