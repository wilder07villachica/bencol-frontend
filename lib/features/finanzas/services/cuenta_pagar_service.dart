import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/cuenta_pagar.dart';
import '../models/pago_proveedor_request.dart';
import '../models/pagina_cuentas_pagar.dart';
import '../models/resumen_cuentas_pagar.dart';

class CuentaPagarService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaCuentasPagar> obtenerCuentas({
    int pagina = 0,
    int tamanio = 20,
    int? proveedorId,
    String? estado,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final parametros = <String, dynamic>{
        'pagina': pagina,
        'tamanio': tamanio,
      };

      if (proveedorId != null) {
        parametros['proveedorId'] = proveedorId;
      }

      if (estado != null && estado.isNotEmpty) {
        parametros['estado'] = estado;
      }

      if (desde != null) {
        parametros['desde'] = _formatearFecha(desde);
      }

      if (hasta != null) {
        parametros['hasta'] = _formatearFecha(hasta);
      }

      final response = await _dio.get(
        ApiConfig.cuentasPagar,
        queryParameters: parametros,
      );

      return PaginaCuentasPagar.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible cargar las cuentas por pagar.'),
      );
    }
  }

  Future<CuentaPagar> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.cuentasPagar}/$id');

      return CuentaPagar.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible obtener la cuenta por pagar.'),
      );
    }
  }

  Future<CuentaPagar> registrarPago(PagoProveedorRequest request) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.cuentasPagar}/pagos',
        data: request.toJson(),
      );

      return CuentaPagar.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible registrar el pago al proveedor.'),
      );
    }
  }

  Future<ResumenCuentasPagar> obtenerResumen() async {
    try {
      final response = await _dio.get('${ApiConfig.cuentasPagar}/resumen');

      return ResumenCuentasPagar.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(
          error,
          'No fue posible cargar el resumen de cuentas por pagar.',
        ),
      );
    }
  }

  String _formatearFecha(DateTime fecha) {
    final anio = fecha.year.toString();
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '$anio-$mes-$dia';
  }

  String _mensajeError(DioException error, String mensajeDefault) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message != null) {
        return message.toString();
      }

      final errors = data['errors'];

      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        return errors.values.first.toString();
      }
    }

    return mensajeDefault;
  }
}
