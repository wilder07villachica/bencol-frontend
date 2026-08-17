class MovimientoInventario {
  final int id;
  final int productoId;
  final String codigoProducto;
  final String descripcionProducto;
  final String tipoMovimiento;
  final int cantidad;
  final int stockAnterior;
  final int stockNuevo;
  final String? referencia;
  final String? registradoPor;
  final DateTime? fechaCreacion;

  const MovimientoInventario({
    required this.id,
    required this.productoId,
    required this.codigoProducto,
    required this.descripcionProducto,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockNuevo,
    required this.referencia,
    required this.registradoPor,
    required this.fechaCreacion,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) {
    return MovimientoInventario(
      id: (json['id'] as num).toInt(),
      productoId: (json['productoId'] as num).toInt(),
      codigoProducto: json['codigoProducto'] as String? ?? '',
      descripcionProducto: json['descripcionProducto'] as String? ?? '',
      tipoMovimiento: json['tipoMovimiento'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      stockAnterior: (json['stockAnterior'] as num?)?.toInt() ?? 0,
      stockNuevo: (json['stockNuevo'] as num?)?.toInt() ?? 0,
      referencia: json['referencia'] as String?,
      registradoPor: json['registradoPor'] as String?,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'].toString())
          : null,
    );
  }
}
