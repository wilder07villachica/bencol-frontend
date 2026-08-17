class ClientePrecio {
  final int id;
  final int clienteId;
  final String nombreCliente;
  final int productoId;
  final String descripcionProducto;
  final double precio;
  final DateTime? fechaCreacion;

  const ClientePrecio({
    required this.id,
    required this.clienteId,
    required this.nombreCliente,
    required this.productoId,
    required this.descripcionProducto,
    required this.precio,
    required this.fechaCreacion,
  });

  factory ClientePrecio.fromJson(Map<String, dynamic> json) {
    return ClientePrecio(
      id: (json['id'] as num).toInt(),
      clienteId: (json['clienteId'] as num).toInt(),
      nombreCliente: json['nombreCliente'] as String? ?? '',
      productoId: (json['productoId'] as num).toInt(),
      descripcionProducto: json['descripcionProducto'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'].toString())
          : null,
    );
  }
}
