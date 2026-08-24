class PagoRequest {
  final int cuentaCobrarId;
  final double monto;
  final String metodoPago;
  final String? referencia;

  const PagoRequest({
    required this.cuentaCobrarId,
    required this.monto,
    required this.metodoPago,
    this.referencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'cuentaCobrarId': cuentaCobrarId,
      'monto': monto,
      'metodoPago': metodoPago,
      if (referencia != null && referencia!.trim().isNotEmpty)
        'referencia': referencia!.trim(),
    };
  }
}
