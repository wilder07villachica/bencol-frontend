class EgresoRequest {
  final String categoria;
  final String concepto;
  final double monto;
  final String? referencia;

  const EgresoRequest({
    required this.categoria,
    required this.concepto,
    required this.monto,
    this.referencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoria': categoria,
      'concepto': concepto.trim(),
      'monto': monto,
      if (referencia != null && referencia!.trim().isNotEmpty)
        'referencia': referencia!.trim(),
    };
  }
}
