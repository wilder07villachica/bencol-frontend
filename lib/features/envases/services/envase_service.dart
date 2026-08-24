import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/cuenta_envases.dart';
import '../models/movimiento_envase.dart';
import '../models/movimiento_envase_request.dart';
import '../models/saldo_inicial_envase_request.dart';

class EnvaseService {
  final Dio _dio = ApiClient.dio;

  Future<List<CuentaEnvases>> obtenerCuentas() async {
    try {
      final response = await _dio.get(ApiConfig.envases);

      final lista = response.data as List<dynamic>;

      return lista
          .map((item) => CuentaEnvases.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible cargar las cuentas de envases.',
        ),
      );
    }
  }

  Future<List<CuentaEnvases>> obtenerPorCliente(int clienteId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.envases}/cliente/$clienteId',
      );

      final lista = response.data as List<dynamic>;

      return lista
          .map((item) => CuentaEnvases.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible cargar los envases del cliente.',
        ),
      );
    }
  }

  Future<CuentaEnvases?> obtenerCuenta({
    required int clienteId,
    required int productoId,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.envases}/cliente/'
        '$clienteId/producto/$productoId',
      );

      return CuentaEnvases.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible consultar la cuenta de envases.',
        ),
      );
    }
  }

  Future<List<MovimientoEnvase>> obtenerMovimientosPorCuenta(
    int cuentaId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.envases}/$cuentaId/movimientos',
      );

      final lista = response.data as List<dynamic>;

      return lista
          .map(
            (item) => MovimientoEnvase.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible cargar el historial de envases.',
        ),
      );
    }
  }

  Future<CuentaEnvases> registrarMovimiento(
    MovimientoEnvaseRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.envases}/movimientos',
        data: request.toJson(),
      );

      return CuentaEnvases.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible registrar el movimiento de envases.',
        ),
      );
    }
  }

  Future<CuentaEnvases> registrarSaldoInicial(
    SaldoInicialEnvaseRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.envases}/saldo-inicial',
        data: request.toJson(),
      );

      return CuentaEnvases.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible registrar el saldo inicial.',
        ),
      );
    }
  }

  String _obtenerMensajeError(DioException error, String mensajeDefault) {
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
