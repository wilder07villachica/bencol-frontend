import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/inventario.dart';
import '../models/inventario_request.dart';
import '../models/movimiento_inventario.dart';
import '../models/movimiento_inventario_request.dart';
import '../models/pagina_movimientos_inventario.dart';
import '../models/pagina_inventarios.dart';

class InventarioService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaInventarios> obtenerInventarios({
    int pagina = 0,
    int tamanio = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.inventarios,
        queryParameters: {'pagina': pagina, 'tamanio': tamanio},
      );

      return PaginaInventarios.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible cargar el inventario.'),
      );
    }
  }

  Future<Inventario?> obtenerPorProducto(int productoId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.inventarios}/producto/$productoId',
      );

      return Inventario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw Exception(
        _obtenerMensajeError(error, 'No fue posible consultar el inventario.'),
      );
    }
  }

  Future<Inventario> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.inventarios}/$id');

      return Inventario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible obtener el inventario.'),
      );
    }
  }

  Future<Inventario> crear(InventarioRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.inventarios,
        data: request.toJson(),
      );

      return Inventario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible crear el inventario.'),
      );
    }
  }

  Future<MovimientoInventario> registrarMovimiento(
    MovimientoInventarioRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.inventarios}/movimientos',
        data: request.toJson(),
      );

      return MovimientoInventario.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible registrar el movimiento.'),
      );
    }
  }

  Future<PaginaMovimientosInventario> obtenerMovimientos({
    int pagina = 0,
    int tamanio = 20,
    int? productoId,
    String? tipoMovimiento,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final parametros = <String, dynamic>{
        'pagina': pagina,
        'tamanio': tamanio,
      };

      if (productoId != null) {
        parametros['productoId'] = productoId;
      }

      if (tipoMovimiento != null && tipoMovimiento.isNotEmpty) {
        parametros['tipoMovimiento'] = tipoMovimiento;
      }

      if (desde != null) {
        parametros['desde'] = _formatearFecha(desde);
      }

      if (hasta != null) {
        parametros['hasta'] = _formatearFecha(hasta);
      }

      final response = await _dio.get(
        '${ApiConfig.inventarios}/movimientos',
        queryParameters: parametros,
      );

      return PaginaMovimientosInventario.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible cargar los movimientos de inventario.',
        ),
      );
    }
  }

  Future<List<MovimientoInventario>> obtenerMovimientosPorProducto(
    int productoId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.inventarios}/producto/'
        '$productoId/movimientos',
      );

      final lista = response.data as List<dynamic>;

      return lista
          .map(
            (item) =>
                MovimientoInventario.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible cargar el historial del producto.',
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

      final errors = data['errors'];

      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        return errors.values.first.toString();
      }
    }

    return mensajeDefault;
  }
}
