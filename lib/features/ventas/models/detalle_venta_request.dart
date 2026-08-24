class DetalleVentaRequest {
  final int productoId;
  final int cantidad;
  final int? envasesDevueltos;
  final String? modalidadEnvase;
  final double? precioManual;

  const DetalleVentaRequest({
    required this.productoId,
    required this.cantidad,
    this.envasesDevueltos,
    this.modalidadEnvase,
    this.precioManual,
  });

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'cantidad': cantidad,
      'envasesDevueltos': envasesDevueltos,
      'modalidadEnvase': modalidadEnvase,
      'precioManual': precioManual,
    };
  }
}
