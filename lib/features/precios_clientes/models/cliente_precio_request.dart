class ClientePrecioRequest {
  final int clienteId;
  final int productoId;
  final double precio;

  const ClientePrecioRequest({
    required this.clienteId,
    required this.productoId,
    required this.precio,
  });

  Map<String, dynamic> toJson() {
    return {'clienteId': clienteId, 'productoId': productoId, 'precio': precio};
  }
}
