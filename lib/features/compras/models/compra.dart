import 'detalle_compra.dart';

class Compra {
  final int id;
  final String codigo;

  final int proveedorId;
  final String razonSocialProveedor;

  final double subtotal;
  final double total;

  final String estado;

  final List<DetalleCompra> detalles;

  final String? creadoPor;
  final String? actualizadoPor;

  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const Compra({
    required this.id,
    required this.codigo,
    required this.proveedorId,
    required this.razonSocialProveedor,
    required this.subtotal,
    required this.total,
    required this.estado,
    required this.detalles,
    required this.creadoPor,
    required this.actualizadoPor,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Compra.fromJson(Map<String, dynamic> json) {
    final detallesJson = json['detalles'] as List<dynamic>? ?? [];

    return Compra(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String? ?? '',
      proveedorId: (json['proveedorId'] as num).toInt(),
      razonSocialProveedor: json['razonSocialProveedor'] as String? ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      estado: json['estado'] as String? ?? '',
      detalles: detallesJson
          .map((item) => DetalleCompra.fromJson(item as Map<String, dynamic>))
          .toList(),
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
