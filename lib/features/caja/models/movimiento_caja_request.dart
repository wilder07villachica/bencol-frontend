class MovimientoCajaRequest {
  final int cajaId;
  final String tipoMovimiento;
  final double monto;
  final String concepto;
  final String? referencia;

  const MovimientoCajaRequest({
    required this.cajaId,
    required this.tipoMovimiento,
    required this.monto,
    required this.concepto,
    this.referencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'cajaId': cajaId,
      'tipoMovimiento': tipoMovimiento,
      'monto': monto,
      'concepto': concepto,
      if (referencia != null && referencia!.trim().isNotEmpty)
        'referencia': referencia!.trim(),
    };
  }
}
