import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/dashboard_charts_response.dart';
import '../models/dashboard_rankings_response.dart';
import '../models/dashboard_response.dart';

class DashboardService {
  final Dio _dio = ApiClient.dio;

  Future<DashboardResponse> obtenerDashboard({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.dashboard,
        queryParameters: {
          'desde': _formatearFecha(desde),
          'hasta': _formatearFecha(hasta),
        },
      );

      return DashboardResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible cargar el dashboard.'),
      );
    }
  }

  Future<List<VentaPorDia>> obtenerVentasPorDia({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.ventasPorDia,
        queryParameters: {
          'desde': _formatearFecha(desde),
          'hasta': _formatearFecha(hasta),
        },
      );

      final data = response.data as List<dynamic>;

      return data
          .map((item) => VentaPorDia.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible cargar las ventas por día.',
        ),
      );
    }
  }

  Future<List<FlujoNetoPorMes>> obtenerFlujoNetoPorMes({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.flujoNetoPorMes,
        queryParameters: {
          'desde': _formatearFecha(desde),
          'hasta': _formatearFecha(hasta),
        },
      );

      final data = response.data as List<dynamic>;

      return data
          .map((item) => FlujoNetoPorMes.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible cargar el flujo mensual.'),
      );
    }
  }

  Future<List<ProductoMasVendido>> obtenerProductosMasVendidos({
    required DateTime desde,
    required DateTime hasta,
    int limite = 5,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.productosMasVendidos,
        queryParameters: {
          'desde': _formatearFecha(desde),
          'hasta': _formatearFecha(hasta),
          'limite': limite,
        },
      );

      final data = response.data as List<dynamic>;

      return data
          .map(
            (item) => ProductoMasVendido.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible cargar los productos más vendidos.',
        ),
      );
    }
  }

  Future<List<ClienteMayorDeuda>> obtenerClientesMayorDeuda({
    int limite = 5,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.clientesMayorDeuda,
        queryParameters: {'limite': limite},
      );

      final data = response.data as List<dynamic>;

      return data
          .map(
            (item) => ClienteMayorDeuda.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible cargar los clientes con mayor deuda.',
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

  String _obtenerMensajeError(DioException error, String mensajeDefault) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message != null) {
        return message.toString();
      }
    }

    return mensajeDefault;
  }
}
