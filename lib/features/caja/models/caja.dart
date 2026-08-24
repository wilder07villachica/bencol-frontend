import 'movimiento_caja.dart';

class Caja {
  final int id;

  final double saldoInicial;
  final double totalIngresos;
  final double totalEgresos;
  final double saldoActual;

  final double? saldoEsperado;
  final double? saldoReal;
  final double? diferencia;

  final String estado;

  final List<MovimientoCaja> movimientos;

  final String? abiertaPor;
  final String? cerradaPor;

  final DateTime? fechaApertura;
  final DateTime? fechaCierre;

  const Caja({
    required this.id,
    required this.saldoInicial,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldoActual,
    required this.saldoEsperado,
    required this.saldoReal,
    required this.diferencia,
    required this.estado,
    required this.movimientos,
    required this.abiertaPor,
    required this.cerradaPor,
    required this.fechaApertura,
    required this.fechaCierre,
  });

  factory Caja.fromJson(Map<String, dynamic> json) {
    final movimientosJson = json['movimientos'] as List<dynamic>? ?? [];

    return Caja(
      id: (json['id'] as num).toInt(),

      saldoInicial: (json['saldoInicial'] as num?)?.toDouble() ?? 0,

      totalIngresos: (json['totalIngresos'] as num?)?.toDouble() ?? 0,

      totalEgresos: (json['totalEgresos'] as num?)?.toDouble() ?? 0,

      saldoActual: (json['saldoActual'] as num?)?.toDouble() ?? 0,

      saldoEsperado: (json['saldoEsperado'] as num?)?.toDouble(),

      saldoReal: (json['saldoReal'] as num?)?.toDouble(),

      diferencia: (json['diferencia'] as num?)?.toDouble(),

      estado: json['estado'] as String? ?? '',

      movimientos: movimientosJson
          .map((item) => MovimientoCaja.fromJson(item as Map<String, dynamic>))
          .toList(),

      abiertaPor: json['abiertaPor'] as String?,

      cerradaPor: json['cerradaPor'] as String?,

      fechaApertura: json['fechaApertura'] != null
          ? DateTime.tryParse(json['fechaApertura'].toString())
          : null,

      fechaCierre: json['fechaCierre'] != null
          ? DateTime.tryParse(json['fechaCierre'].toString())
          : null,
    );
  }
}
