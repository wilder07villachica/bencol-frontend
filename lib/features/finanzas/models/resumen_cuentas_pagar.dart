class ResumenCuentasPagar {
  final double totalComprado;
  final double totalPagado;
  final double totalPorPagar;

  final int cantidadCuentas;
  final int cantidadPendientes;
  final int cantidadParciales;
  final int cantidadPagadas;
  final int cantidadAnuladas;

  const ResumenCuentasPagar({
    required this.totalComprado,
    required this.totalPagado,
    required this.totalPorPagar,
    required this.cantidadCuentas,
    required this.cantidadPendientes,
    required this.cantidadParciales,
    required this.cantidadPagadas,
    required this.cantidadAnuladas,
  });

  factory ResumenCuentasPagar.fromJson(Map<String, dynamic> json) {
    return ResumenCuentasPagar(
      totalComprado: (json['totalComprado'] as num?)?.toDouble() ?? 0,
      totalPagado: (json['totalPagado'] as num?)?.toDouble() ?? 0,
      totalPorPagar: (json['totalPorPagar'] as num?)?.toDouble() ?? 0,
      cantidadCuentas: (json['cantidadCuentas'] as num?)?.toInt() ?? 0,
      cantidadPendientes: (json['cantidadPendientes'] as num?)?.toInt() ?? 0,
      cantidadParciales: (json['cantidadParciales'] as num?)?.toInt() ?? 0,
      cantidadPagadas: (json['cantidadPagadas'] as num?)?.toInt() ?? 0,
      cantidadAnuladas: (json['cantidadAnuladas'] as num?)?.toInt() ?? 0,
    );
  }
}
