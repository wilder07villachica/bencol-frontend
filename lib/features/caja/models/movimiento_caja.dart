class MovimientoCaja {
  final int id;
  final int cajaId;
  final String tipoMovimiento;
  final double monto;
  final String concepto;
  final String? referencia;
  final String? registradoPor;
  final DateTime? fechaMovimiento;

  const MovimientoCaja({
    required this.id,
    required this.cajaId,
    required this.tipoMovimiento,
    required this.monto,
    required this.concepto,
    required this.referencia,
    required this.registradoPor,
    required this.fechaMovimiento,
  });

  factory MovimientoCaja.fromJson(Map<String, dynamic> json) {
    return MovimientoCaja(
      id: (json['id'] as num).toInt(),
      cajaId: (json['cajaId'] as num).toInt(),
      tipoMovimiento: json['tipoMovimiento'] as String? ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      concepto: json['concepto'] as String? ?? '',
      referencia: json['referencia'] as String?,
      registradoPor: json['registradoPor'] as String?,
      fechaMovimiento: json['fechaMovimiento'] != null
          ? DateTime.tryParse(json['fechaMovimiento'].toString())
          : null,
    );
  }
}
