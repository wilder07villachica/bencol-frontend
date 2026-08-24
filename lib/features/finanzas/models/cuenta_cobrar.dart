import 'pago.dart';

class CuentaCobrar {
  final int id;
  final int ventaId;
  final String codigoVenta;

  final int clienteId;
  final String nombreCliente;

  final double montoTotal;
  final double montoPagado;
  final double saldoPendiente;

  final String estado;

  final List<Pago> pagos;

  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const CuentaCobrar({
    required this.id,
    required this.ventaId,
    required this.codigoVenta,
    required this.clienteId,
    required this.nombreCliente,
    required this.montoTotal,
    required this.montoPagado,
    required this.saldoPendiente,
    required this.estado,
    required this.pagos,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory CuentaCobrar.fromJson(Map<String, dynamic> json) {
    final pagosJson = json['pagos'] as List<dynamic>? ?? [];

    return CuentaCobrar(
      id: (json['id'] as num).toInt(),
      ventaId: (json['ventaId'] as num).toInt(),
      codigoVenta: json['codigoVenta'] as String? ?? '',
      clienteId: (json['clienteId'] as num).toInt(),
      nombreCliente: json['nombreCliente'] as String? ?? '',
      montoTotal: (json['montoTotal'] as num?)?.toDouble() ?? 0,
      montoPagado: (json['montoPagado'] as num?)?.toDouble() ?? 0,
      saldoPendiente: (json['saldoPendiente'] as num?)?.toDouble() ?? 0,
      estado: json['estado'] as String? ?? '',
      pagos: pagosJson
          .map((item) => Pago.fromJson(item as Map<String, dynamic>))
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
