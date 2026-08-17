class Egreso {
  final int id;
  final String categoria;
  final String concepto;
  final double monto;
  final String? referencia;
  final String? registradoPor;
  final DateTime? fechaEgreso;

  const Egreso({
    required this.id,
    required this.categoria,
    required this.concepto,
    required this.monto,
    required this.referencia,
    required this.registradoPor,
    required this.fechaEgreso,
  });

  factory Egreso.fromJson(Map<String, dynamic> json) {
    return Egreso(
      id: (json['id'] as num).toInt(),
      categoria: json['categoria'] as String? ?? '',
      concepto: json['concepto'] as String? ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      referencia: json['referencia'] as String?,
      registradoPor: json['registradoPor'] as String?,
      fechaEgreso: json['fechaEgreso'] != null
          ? DateTime.tryParse(json['fechaEgreso'].toString())
          : null,
    );
  }
}
