class ProductoMasVendido {
  final int productoId;
  final String codigoProducto;
  final String descripcionProducto;
  final int cantidadVendida;
  final int unidadesFisicasVendidas;
  final double totalVendido;

  const ProductoMasVendido({
    required this.productoId,
    required this.codigoProducto,
    required this.descripcionProducto,
    required this.cantidadVendida,
    required this.unidadesFisicasVendidas,
    required this.totalVendido,
  });

  factory ProductoMasVendido.fromJson(Map<String, dynamic> json) {
    return ProductoMasVendido(
      productoId: (json['productoId'] as num).toInt(),
      codigoProducto: json['codigoProducto'] as String,
      descripcionProducto: json['descripcionProducto'] as String,
      cantidadVendida: (json['cantidadVendida'] as num?)?.toInt() ?? 0,
      unidadesFisicasVendidas:
          (json['unidadesFisicasVendidas'] as num?)?.toInt() ?? 0,
      totalVendido: (json['totalVendido'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ClienteMayorDeuda {
  final int clienteId;
  final String nombreCliente;
  final double deudaTotal;
  final int cantidadCuentasPendientes;

  const ClienteMayorDeuda({
    required this.clienteId,
    required this.nombreCliente,
    required this.deudaTotal,
    required this.cantidadCuentasPendientes,
  });

  factory ClienteMayorDeuda.fromJson(Map<String, dynamic> json) {
    return ClienteMayorDeuda(
      clienteId: (json['clienteId'] as num).toInt(),
      nombreCliente: json['nombreCliente'] as String,
      deudaTotal: (json['deudaTotal'] as num?)?.toDouble() ?? 0,
      cantidadCuentasPendientes:
          (json['cantidadCuentasPendientes'] as num?)?.toInt() ?? 0,
    );
  }
}
