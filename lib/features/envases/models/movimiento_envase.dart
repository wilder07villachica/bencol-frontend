class MovimientoEnvase {
  final int id;
  final int cuentaEnvaseId;
  final int clienteId;
  final String nombreCliente;
  final int productoId;
  final String codigoProducto;
  final String descripcionProducto;
  final String tipoMovimiento;
  final int cantidad;
  final String? referencia;
  final DateTime? fechaMovimiento;
  final String? registradoPor;

  const MovimientoEnvase({
    required this.id,
    required this.cuentaEnvaseId,
    required this.clienteId,
    required this.nombreCliente,
    required this.productoId,
    required this.codigoProducto,
    required this.descripcionProducto,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.referencia,
    required this.fechaMovimiento,
    required this.registradoPor,
  });

  factory MovimientoEnvase.fromJson(Map<String, dynamic> json) {
    return MovimientoEnvase(
      id: (json['id'] as num).toInt(),
      cuentaEnvaseId: (json['cuentaEnvaseId'] as num).toInt(),
      clienteId: (json['clienteId'] as num).toInt(),
      nombreCliente: json['nombreCliente'] as String? ?? '',
      productoId: (json['productoId'] as num).toInt(),
      codigoProducto: json['codigoProducto'] as String? ?? '',
      descripcionProducto: json['descripcionProducto'] as String? ?? '',
      tipoMovimiento: json['tipoMovimiento'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      referencia: json['referencia'] as String?,
      fechaMovimiento: json['fechaMovimiento'] != null
          ? DateTime.tryParse(json['fechaMovimiento'].toString())
          : null,
      registradoPor: json['registradoPor'] as String?,
    );
  }
}
