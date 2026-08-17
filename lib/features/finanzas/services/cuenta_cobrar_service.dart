import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/cuenta_cobrar.dart';
import '../models/pago_request.dart';
import '../models/pagina_cuentas_cobrar.dart';
import '../models/resumen_financiero.dart';

class CuentaCobrarService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaCuentasCobrar> obtenerCuentas({
    int pagina = 0,
    int tamanio = 20,
    int? clienteId,
    String? estado,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final parametros = <String, dynamic>{
        'pagina': pagina,
        'tamanio': tamanio,
      };

      if (clienteId != null) {
        parametros['clienteId'] = clienteId;
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
        ApiConfig.cuentasCobrar,
        queryParameters: parametros,
      );

      return PaginaCuentasCobrar.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible cargar las cuentas por cobrar.'),
      );
    }
  }

  Future<CuentaCobrar> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.cuentasCobrar}/$id');

      return CuentaCobrar.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible obtener la cuenta.'),
      );
    }
  }

  Future<CuentaCobrar> registrarPago(PagoRequest request) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.cuentasCobrar}/pagos',
        data: request.toJson(),
      );

      return CuentaCobrar.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible registrar el pago.'),
      );
    }
  }

  Future<ResumenFinanciero> obtenerResumen() async {
    try {
      final response = await _dio.get('${ApiConfig.cuentasCobrar}/resumen');

      return ResumenFinanciero.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible cargar el resumen financiero.'),
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
