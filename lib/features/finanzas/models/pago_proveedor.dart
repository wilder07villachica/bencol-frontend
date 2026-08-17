class PagoProveedor {
  final int id;
  final int cuentaPagarId;
  final double monto;
  final String metodoPago;
  final String? referencia;
  final DateTime? fechaPago;
  final String? registradoPor;

  const PagoProveedor({
    required this.id,
    required this.cuentaPagarId,
    required this.monto,
    required this.metodoPago,
    required this.referencia,
    required this.fechaPago,
    required this.registradoPor,
  });

  factory PagoProveedor.fromJson(Map<String, dynamic> json) {
    return PagoProveedor(
      id: (json['id'] as num).toInt(),
      cuentaPagarId: (json['cuentaPagarId'] as num).toInt(),
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      metodoPago: json['metodoPago'] as String? ?? '',
      referencia: json['referencia'] as String?,
      fechaPago: json['fechaPago'] != null
          ? DateTime.tryParse(json['fechaPago'].toString())
          : null,
      registradoPor: json['registradoPor'] as String?,
    );
  }
}
