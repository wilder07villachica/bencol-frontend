class InventarioRequest {
  final int productoId;
  final int stockActual;
  final int stockMinimo;
  final int? stockMaximo;

  const InventarioRequest({
    required this.productoId,
    required this.stockActual,
    required this.stockMinimo,
    this.stockMaximo,
  });

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'stockActual': stockActual,
      'stockMinimo': stockMinimo,
      'stockMaximo': stockMaximo,
    };
  }
}
