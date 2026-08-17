import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/pagina_ventas.dart';
import '../models/venta.dart';

import '../models/venta_request.dart';

class VentaService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaVentas> obtenerVentas({
    int pagina = 0,
    int tamanio = 20,
    String? codigo,
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

      if (codigo != null && codigo.trim().isNotEmpty) {
        parametros['codigo'] = codigo.trim();
      }

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
        ApiConfig.ventas,
        queryParameters: parametros,
      );

      return PaginaVentas.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible cargar las ventas.'),
      );
    }
  }

  Future<Venta> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.ventas}/$id');

      return Venta.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible obtener la venta.'),
      );
    }
  }

  Future<Venta> crear(VentaRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.ventas,
        data: request.toJson(),
      );

      return Venta.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible registrar la venta.'),
      );
    }
  }

  Future<Venta> anular(int id) async {
    try {
      final response = await _dio.patch('${ApiConfig.ventas}/$id/anular');

      return Venta.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible anular la venta.'),
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
