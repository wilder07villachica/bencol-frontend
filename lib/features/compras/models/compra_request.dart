import 'detalle_compra_request.dart';

class CompraRequest {
  final int proveedorId;
  final List<DetalleCompraRequest> detalles;

  const CompraRequest({required this.proveedorId, required this.detalles});

  Map<String, dynamic> toJson() {
    return {
      'proveedorId': proveedorId,
      'detalles': detalles.map((detalle) => detalle.toJson()).toList(),
    };
  }
}
