class MovimientoInventarioRequest {
  final int productoId;
  final String tipoMovimiento;
  final int cantidad;
  final String? referencia;

  const MovimientoInventarioRequest({
    required this.productoId,
    required this.tipoMovimiento,
    required this.cantidad,
    this.referencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'tipoMovimiento': tipoMovimiento,
      'cantidad': cantidad,
      'referencia': referencia,
    };
  }
}
