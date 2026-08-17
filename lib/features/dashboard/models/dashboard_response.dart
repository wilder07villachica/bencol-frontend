class DashboardResponse {
  final ResumenVentas ventas;
  final ResumenFinanzas finanzas;
  final ResumenCaja caja;
  final ResumenCompras compras;
  final ResumenInventario inventario;

  const DashboardResponse({
    required this.ventas,
    required this.finanzas,
    required this.caja,
    required this.compras,
    required this.inventario,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      ventas: ResumenVentas.fromJson(json['ventas'] as Map<String, dynamic>),
      finanzas: ResumenFinanzas.fromJson(
        json['finanzas'] as Map<String, dynamic>,
      ),
      caja: ResumenCaja.fromJson(json['caja'] as Map<String, dynamic>),
      compras: ResumenCompras.fromJson(json['compras'] as Map<String, dynamic>),
      inventario: ResumenInventario.fromJson(
        json['inventario'] as Map<String, dynamic>,
      ),
    );
  }
}

class ResumenVentas {
  final int cantidadVentas;
  final double ticketPromedio;
  final double totalVendido;

  const ResumenVentas({
    required this.cantidadVentas,
    required this.ticketPromedio,
    required this.totalVendido,
  });

  factory ResumenVentas.fromJson(Map<String, dynamic> json) {
    return ResumenVentas(
      cantidadVentas: (json['cantidadVentas'] as num?)?.toInt() ?? 0,
      ticketPromedio: (json['ticketPromedio'] as num?)?.toDouble() ?? 0,
      totalVendido: (json['totalVendido'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ResumenFinanzas {
  final double totalCobrado;
  final double totalPagadoProveedores;
  final double totalPorCobrar;
  final double totalPorPagar;

  const ResumenFinanzas({
    required this.totalCobrado,
    required this.totalPagadoProveedores,
    required this.totalPorCobrar,
    required this.totalPorPagar,
  });

  factory ResumenFinanzas.fromJson(Map<String, dynamic> json) {
    return ResumenFinanzas(
      totalCobrado: (json['totalCobrado'] as num?)?.toDouble() ?? 0,
      totalPagadoProveedores:
          (json['totalPagadoProveedores'] as num?)?.toDouble() ?? 0,
      totalPorCobrar: (json['totalPorCobrar'] as num?)?.toDouble() ?? 0,
      totalPorPagar: (json['totalPorPagar'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ResumenCaja {
  final int? cajaId;
  final String? estado;

  final double? saldoInicial;
  final double? saldoActual;

  final double? totalIngresos;
  final double? totalEgresos;

  final double ingresosPeriodo;
  final double egresosPeriodo;

  const ResumenCaja({
    required this.cajaId,
    required this.estado,
    required this.saldoInicial,
    required this.saldoActual,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.ingresosPeriodo,
    required this.egresosPeriodo,
  });

  factory ResumenCaja.fromJson(Map<String, dynamic> json) {
    return ResumenCaja(
      cajaId: (json['cajaId'] as num?)?.toInt(),
      estado: json['estado'] as String?,
      saldoInicial: (json['saldoInicial'] as num?)?.toDouble(),
      saldoActual: (json['saldoActual'] as num?)?.toDouble(),
      totalIngresos: (json['totalIngresos'] as num?)?.toDouble(),
      totalEgresos: (json['totalEgresos'] as num?)?.toDouble(),
      ingresosPeriodo: (json['ingresosPeriodo'] as num?)?.toDouble() ?? 0,
      egresosPeriodo: (json['egresosPeriodo'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ResumenCompras {
  final int cantidadCompras;
  final double totalComprado;

  const ResumenCompras({
    required this.cantidadCompras,
    required this.totalComprado,
  });

  factory ResumenCompras.fromJson(Map<String, dynamic> json) {
    return ResumenCompras(
      cantidadCompras: (json['cantidadCompras'] as num?)?.toInt() ?? 0,
      totalComprado: (json['totalComprado'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ResumenInventario {
  final int cantidadProductosInventario;
  final int productosStockBajo;

  const ResumenInventario({
    required this.cantidadProductosInventario,
    required this.productosStockBajo,
  });

  factory ResumenInventario.fromJson(Map<String, dynamic> json) {
    return ResumenInventario(
      cantidadProductosInventario:
          (json['cantidadProductosInventario'] as num?)?.toInt() ?? 0,
      productosStockBajo: (json['productosStockBajo'] as num?)?.toInt() ?? 0,
    );
  }
}
