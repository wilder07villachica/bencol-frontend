class DetalleCompra {
  final int id;
  final int productoId;
  final String codigoProducto;
  final String descripcionProducto;
  final int cantidad;
  final double costoUnitario;
  final double subtotal;

  const DetalleCompra({
    required this.id,
    required this.productoId,
    required this.codigoProducto,
    required this.descripcionProducto,
    required this.cantidad,
    required this.costoUnitario,
    required this.subtotal,
  });

  factory DetalleCompra.fromJson(Map<String, dynamic> json) {
    return DetalleCompra(
      id: (json['id'] as num).toInt(),
      productoId: (json['productoId'] as num).toInt(),
      codigoProducto: json['codigoProducto'] as String? ?? '',
      descripcionProducto: json['descripcionProducto'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      costoUnitario: (json['costoUnitario'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}
