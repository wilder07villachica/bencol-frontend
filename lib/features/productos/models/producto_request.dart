class ProductoRequest {
  final String codigo;
  final String descripcion;
  final String categoria;
  final double contenido;
  final String unidadMedida;
  final int unidadesPorPaquete;
  final double precioBase;
  final String? estado;

  const ProductoRequest({
    required this.codigo,
    required this.descripcion,
    required this.categoria,
    required this.contenido,
    required this.unidadMedida,
    required this.unidadesPorPaquete,
    required this.precioBase,
    this.estado,
  });

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'descripcion': descripcion,
      'categoria': categoria,
      'contenido': contenido,
      'unidadMedida': unidadMedida,
      'unidadesPorPaquete': unidadesPorPaquete,
      'precioBase': precioBase,
      'estado': estado,
    };
  }
}
