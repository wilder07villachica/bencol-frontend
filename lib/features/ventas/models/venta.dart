class DetalleVenta {
  final int id;
  final int productoId;
  final String codigoProducto;
  final String descripcionProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final int? envasesDevueltos;
  final String? modalidadEnvase;

  const DetalleVenta({
    required this.id,
    required this.productoId,
    required this.codigoProducto,
    required this.descripcionProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.envasesDevueltos,
    required this.modalidadEnvase,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      id: (json['id'] as num).toInt(),
      productoId: (json['productoId'] as num).toInt(),
      codigoProducto: json['codigoProducto'] as String? ?? '',
      descripcionProducto: json['descripcionProducto'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      envasesDevueltos: (json['envasesDevueltos'] as num?)?.toInt(),
      modalidadEnvase: json['modalidadEnvase'] as String?,
    );
  }
}

class Venta {
  final int id;
  final String codigo;
  final int clienteId;
  final String nombreCliente;
  final double subtotal;
  final double total;
  final List<DetalleVenta> detalles;
  final String estado;
  final String? creadoPor;
  final String? actualizadoPor;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const Venta({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.nombreCliente,
    required this.subtotal,
    required this.total,
    required this.detalles,
    required this.estado,
    required this.creadoPor,
    required this.actualizadoPor,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    final detallesJson = json['detalles'] as List<dynamic>? ?? [];

    return Venta(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String? ?? '',
      clienteId: (json['clienteId'] as num).toInt(),
      nombreCliente: json['nombreCliente'] as String? ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      detalles: detallesJson
          .map((item) => DetalleVenta.fromJson(item as Map<String, dynamic>))
          .toList(),
      estado: json['estado'] as String? ?? '',
      creadoPor: json['creadoPor'] as String?,
      actualizadoPor: json['actualizadoPor'] as String?,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'].toString())
          : null,
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.tryParse(json['fechaActualizacion'].toString())
          : null,
    );
  }
}
