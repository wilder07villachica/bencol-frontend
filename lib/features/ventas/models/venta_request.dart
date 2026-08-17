import 'detalle_venta_request.dart';

class VentaRequest {
  final int clienteId;
  final List<DetalleVentaRequest> detalles;

  const VentaRequest({required this.clienteId, required this.detalles});

  Map<String, dynamic> toJson() {
    return {
      'clienteId': clienteId,
      'detalles': detalles.map((detalle) => detalle.toJson()).toList(),
    };
  }
}
