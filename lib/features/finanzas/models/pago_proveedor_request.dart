class PagoProveedorRequest {
  final int cuentaPagarId;
  final double monto;
  final String metodoPago;
  final String? referencia;

  const PagoProveedorRequest({
    required this.cuentaPagarId,
    required this.monto,
    required this.metodoPago,
    this.referencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'cuentaPagarId': cuentaPagarId,
      'monto': monto,
      'metodoPago': metodoPago,
      if (referencia != null && referencia!.trim().isNotEmpty)
        'referencia': referencia!.trim(),
    };
  }
}
