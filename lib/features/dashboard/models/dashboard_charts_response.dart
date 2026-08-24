class VentaPorDia {
  final DateTime fecha;
  final int cantidadVentas;
  final double totalVendido;

  const VentaPorDia({
    required this.fecha,
    required this.cantidadVentas,
    required this.totalVendido,
  });

  factory VentaPorDia.fromJson(Map<String, dynamic> json) {
    return VentaPorDia(
      fecha: DateTime.parse(json['fecha'] as String),
      cantidadVentas: (json['cantidadVentas'] as num?)?.toInt() ?? 0,
      totalVendido: (json['totalVendido'] as num?)?.toDouble() ?? 0,
    );
  }
}

class FlujoNetoPorMes {
  final int anio;
  final int mes;
  final double totalIngresos;
  final double totalEgresos;
  final double flujoNeto;

  const FlujoNetoPorMes({
    required this.anio,
    required this.mes,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.flujoNeto,
  });

  factory FlujoNetoPorMes.fromJson(Map<String, dynamic> json) {
    return FlujoNetoPorMes(
      anio: (json['anio'] as num).toInt(),
      mes: (json['mes'] as num).toInt(),
      totalIngresos: (json['totalIngresos'] as num?)?.toDouble() ?? 0,
      totalEgresos: (json['totalEgresos'] as num?)?.toDouble() ?? 0,
      flujoNeto: (json['flujoNeto'] as num?)?.toDouble() ?? 0,
    );
  }
}
