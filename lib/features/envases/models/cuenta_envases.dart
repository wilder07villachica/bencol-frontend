class CuentaEnvases {
  final int id;
  final int clienteId;
  final String nombreCliente;
  final int productoId;
  final String codigoProducto;
  final String descripcionProducto;
  final int cantidadPropios;
  final int cantidadPrestados;
  final int cantidadTotal;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const CuentaEnvases({
    required this.id,
    required this.clienteId,
    required this.nombreCliente,
    required this.productoId,
    required this.codigoProducto,
    required this.descripcionProducto,
    required this.cantidadPropios,
    required this.cantidadPrestados,
    required this.cantidadTotal,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory CuentaEnvases.fromJson(Map<String, dynamic> json) {
    return CuentaEnvases(
      id: (json['id'] as num).toInt(),
      clienteId: (json['clienteId'] as num).toInt(),
      nombreCliente: json['nombreCliente'] as String? ?? '',
      productoId: (json['productoId'] as num).toInt(),
      codigoProducto: json['codigoProducto'] as String? ?? '',
      descripcionProducto: json['descripcionProducto'] as String? ?? '',
      cantidadPropios: (json['cantidadPropios'] as num?)?.toInt() ?? 0,
      cantidadPrestados: (json['cantidadPrestados'] as num?)?.toInt() ?? 0,
      cantidadTotal: (json['cantidadTotal'] as num?)?.toInt() ?? 0,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'].toString())
          : null,
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.tryParse(json['fechaActualizacion'].toString())
          : null,
    );
  }
}
