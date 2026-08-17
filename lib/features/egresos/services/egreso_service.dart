import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/egreso.dart';
import '../models/egreso_request.dart';
import '../models/pagina_egresos.dart';

class EgresoService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaEgresos> obtenerEgresos({
    int pagina = 0,
    int tamanio = 20,
    String? categoria,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final parametros = <String, dynamic>{
        'pagina': pagina,
        'tamanio': tamanio,
      };

      if (categoria != null && categoria.isNotEmpty) {
        parametros['categoria'] = categoria;
      }

      if (desde != null) {
        parametros['desde'] = _formatearFecha(desde);
      }

      if (hasta != null) {
        parametros['hasta'] = _formatearFecha(hasta);
      }

      final response = await _dio.get(
        ApiConfig.egresos,
        queryParameters: parametros,
      );

      return PaginaEgresos.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible cargar los egresos.'),
      );
    }
  }

  Future<Egreso> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.egresos}/$id');

      return Egreso.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible obtener el egreso.'),
      );
    }
  }

  Future<List<Egreso>> obtenerPorCategoria(String categoria) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.egresos}/categoria/$categoria',
      );

      final lista = response.data as List<dynamic>;

      return lista
          .map((item) => Egreso.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible cargar los egresos.'),
      );
    }
  }

  Future<Egreso> crear(EgresoRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.egresos,
        data: request.toJson(),
      );

      return Egreso.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible registrar el egreso.'),
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
