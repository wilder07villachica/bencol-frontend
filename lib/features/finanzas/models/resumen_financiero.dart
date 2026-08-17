class ResumenFinanciero {
  final double totalVendido;
  final double totalCobrado;
  final double totalPorCobrar;

  final int cantidadCuentas;
  final int cantidadPendientes;
  final int cantidadParciales;
  final int cantidadPagadas;
  final int cantidadAnuladas;

  const ResumenFinanciero({
    required this.totalVendido,
    required this.totalCobrado,
    required this.totalPorCobrar,
    required this.cantidadCuentas,
    required this.cantidadPendientes,
    required this.cantidadParciales,
    required this.cantidadPagadas,
    required this.cantidadAnuladas,
  });

  factory ResumenFinanciero.fromJson(Map<String, dynamic> json) {
    return ResumenFinanciero(
      totalVendido: (json['totalVendido'] as num?)?.toDouble() ?? 0,
      totalCobrado: (json['totalCobrado'] as num?)?.toDouble() ?? 0,
      totalPorCobrar: (json['totalPorCobrar'] as num?)?.toDouble() ?? 0,
      cantidadCuentas: (json['cantidadCuentas'] as num?)?.toInt() ?? 0,
      cantidadPendientes: (json['cantidadPendientes'] as num?)?.toInt() ?? 0,
      cantidadParciales: (json['cantidadParciales'] as num?)?.toInt() ?? 0,
      cantidadPagadas: (json['cantidadPagadas'] as num?)?.toInt() ?? 0,
      cantidadAnuladas: (json['cantidadAnuladas'] as num?)?.toInt() ?? 0,
    );
  }
}
