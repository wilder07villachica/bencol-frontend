import 'detalle_cotizacion.dart';

class Cotizacion {
  final int id;

  final String codigo;

  final int empresaId;
  final String rucEmpresa;
  final String razonSocialEmpresa;
  final String? nombreComercialEmpresa;

  final int clienteId;
  final String nombreCliente;

  final double subtotal;
  final double porcentajeImpuesto;
  final double montoImpuesto;
  final double total;

  final String tipoPrecio;
  final String estado;

  final DateTime? fechaVencimiento;

  final String? condicionesPago;
  final String? plazoEntrega;
  final String? observacion;

  final String? creadoPor;
  final String? actualizadoPor;

  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  final List<DetalleCotizacion> detalles;

  Cotizacion({
    required this.id,
    required this.codigo,
    required this.empresaId,
    required this.rucEmpresa,
    required this.razonSocialEmpresa,
    required this.nombreComercialEmpresa,
    required this.clienteId,
    required this.nombreCliente,
    required this.subtotal,
    required this.porcentajeImpuesto,
    required this.montoImpuesto,
    required this.total,
    required this.tipoPrecio,
    required this.estado,
    required this.fechaVencimiento,
    required this.condicionesPago,
    required this.plazoEntrega,
    required this.observacion,
    required this.creadoPor,
    required this.actualizadoPor,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.detalles,
  });

  factory Cotizacion.fromJson(Map<String, dynamic> json) {
    return Cotizacion(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      empresaId: json['empresaId'] as int,
      rucEmpresa: json['rucEmpresa'] as String,
      razonSocialEmpresa: json['razonSocialEmpresa'] as String,
      nombreComercialEmpresa: json['nombreComercialEmpresa'] as String?,
      clienteId: json['clienteId'] as int,
      nombreCliente: json['nombreCliente'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      porcentajeImpuesto: (json['porcentajeImpuesto'] as num).toDouble(),
      montoImpuesto: (json['montoImpuesto'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      tipoPrecio: json['tipoPrecio'] as String,
      estado: json['estado'] as String,
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'])
          : null,
      condicionesPago: json['condicionesPago'] as String?,
      plazoEntrega: json['plazoEntrega'] as String?,
      observacion: json['observacion'] as String?,
      creadoPor: json['creadoPor'] as String?,
      actualizadoPor: json['actualizadoPor'] as String?,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : null,
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'])
          : null,
      detalles: (json['detalles'] as List<dynamic>? ?? [])
          .map(
            (item) => DetalleCotizacion.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
