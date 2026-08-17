class DetalleCompraRequest {
  final int productoId;
  final int cantidad;
  final double costoUnitario;

  const DetalleCompraRequest({
    required this.productoId,
    required this.cantidad,
    required this.costoUnitario,
  });

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'cantidad': cantidad,
      'costoUnitario': costoUnitario,
    };
  }
}
