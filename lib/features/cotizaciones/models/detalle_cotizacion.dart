class DetalleCotizacion {
  final int id;
  final int productoId;

  final String codigoProducto;
  final String descripcionProducto;
  final String categoriaProducto;

  final double contenidoProducto;
  final String unidadMedidaProducto;
  final int unidadesPorPaquete;

  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  final String? frecuenciaAbastecimiento;
  final String? descripcionAdicional;

  final String? imagenNombre;
  final String? imagenTipo;

  final bool tieneImagen;

  DetalleCotizacion({
    required this.id,
    required this.productoId,
    required this.codigoProducto,
    required this.descripcionProducto,
    required this.categoriaProducto,
    required this.contenidoProducto,
    required this.unidadMedidaProducto,
    required this.unidadesPorPaquete,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.frecuenciaAbastecimiento,
    required this.descripcionAdicional,
    required this.imagenNombre,
    required this.imagenTipo,
    required this.tieneImagen,
  });

  factory DetalleCotizacion.fromJson(Map<String, dynamic> json) {
    return DetalleCotizacion(
      id: json['id'] as int,
      productoId: json['productoId'] as int,
      codigoProducto: json['codigoProducto'] as String,
      descripcionProducto: json['descripcionProducto'] as String,
      categoriaProducto: json['categoriaProducto'] as String,
      contenidoProducto: (json['contenidoProducto'] as num).toDouble(),
      unidadMedidaProducto: json['unidadMedidaProducto'] as String,
      unidadesPorPaquete: json['unidadesPorPaquete'] as int,
      cantidad: json['cantidad'] as int,
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      frecuenciaAbastecimiento: json['frecuenciaAbastecimiento'] as String?,
      descripcionAdicional: json['descripcionAdicional'] as String?,
      imagenNombre: json['imagenNombre'] as String?,
      imagenTipo: json['imagenTipo'] as String?,
      tieneImagen: json['tieneImagen'] as bool? ?? false,
    );
  }
}
