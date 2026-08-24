import 'pago_proveedor.dart';

class CuentaPagar {
  final int id;
  final int compraId;
  final String codigoCompra;

  final int proveedorId;
  final String razonSocialProveedor;

  final double montoTotal;
  final double montoPagado;
  final double saldoPendiente;

  final String estado;

  final List<PagoProveedor> pagos;

  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const CuentaPagar({
    required this.id,
    required this.compraId,
    required this.codigoCompra,
    required this.proveedorId,
    required this.razonSocialProveedor,
    required this.montoTotal,
    required this.montoPagado,
    required this.saldoPendiente,
    required this.estado,
    required this.pagos,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory CuentaPagar.fromJson(Map<String, dynamic> json) {
    final pagosJson = json['pagos'] as List<dynamic>? ?? [];

    return CuentaPagar(
      id: (json['id'] as num).toInt(),
      compraId: (json['compraId'] as num).toInt(),
      codigoCompra: json['codigoCompra'] as String? ?? '',
      proveedorId: (json['proveedorId'] as num).toInt(),
      razonSocialProveedor: json['razonSocialProveedor'] as String? ?? '',
      montoTotal: (json['montoTotal'] as num?)?.toDouble() ?? 0,
      montoPagado: (json['montoPagado'] as num?)?.toDouble() ?? 0,
      saldoPendiente: (json['saldoPendiente'] as num?)?.toDouble() ?? 0,
      estado: json['estado'] as String? ?? '',
      pagos: pagosJson
          .map((item) => PagoProveedor.fromJson(item as Map<String, dynamic>))
          .toList(),
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'].toString())
          : null,
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.tryParse(json['fechaActualizacion'].toString())
          : null,
    );
  }
}
