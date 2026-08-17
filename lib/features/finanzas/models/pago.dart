class Pago {
  final int id;
  final int cuentaCobrarId;
  final double monto;
  final String metodoPago;
  final String? referencia;
  final DateTime? fechaPago;
  final String? registradoPor;

  const Pago({
    required this.id,
    required this.cuentaCobrarId,
    required this.monto,
    required this.metodoPago,
    required this.referencia,
    required this.fechaPago,
    required this.registradoPor,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: (json['id'] as num).toInt(),
      cuentaCobrarId: (json['cuentaCobrarId'] as num).toInt(),
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
