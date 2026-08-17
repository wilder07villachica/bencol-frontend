class MovimientoEnvaseRequest {
  final int clienteId;
  final int productoId;
  final String tipoMovimiento;
  final int cantidad;
  final String? referencia;

  const MovimientoEnvaseRequest({
    required this.clienteId,
    required this.productoId,
    required this.tipoMovimiento,
    required this.cantidad,
    this.referencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'clienteId': clienteId,
      'productoId': productoId,
      'tipoMovimiento': tipoMovimiento,
      'cantidad': cantidad,
      if (referencia != null && referencia!.trim().isNotEmpty)
        'referencia': referencia!.trim(),
    };
  }
}
