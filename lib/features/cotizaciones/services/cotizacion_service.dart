import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/cotizacion.dart';
import '../models/pagina_cotizaciones.dart';

class CotizacionService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaCotizaciones> obtenerCotizaciones({
    int pagina = 0,
    int tamanio = 20,
    String? codigo,
    int? clienteId,
    String? estado,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'pagina': pagina,
        'tamanio': tamanio,
      };

      if (codigo != null && codigo.trim().isNotEmpty) {
        queryParameters['codigo'] = codigo.trim();
      }

      if (clienteId != null) {
        queryParameters['clienteId'] = clienteId;
      }

      if (estado != null && estado.isNotEmpty) {
        queryParameters['estado'] = estado;
      }

      if (desde != null) {
        queryParameters['desde'] = _fecha(desde);
      }

      if (hasta != null) {
        queryParameters['hasta'] = _fecha(hasta);
      }

      final response = await _dio.get(
        ApiConfig.cotizaciones,
        queryParameters: queryParameters,
      );

      return PaginaCotizaciones.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible obtener las cotizaciones.'),
      );
    }
  }

  Future<Cotizacion> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.cotizaciones}/$id');

      return Cotizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible obtener la cotización.'),
      );
    }
  }

  Future<Cotizacion> crear(Map<String, dynamic> request) async {
    try {
      final response = await _dio.post(ApiConfig.cotizaciones, data: request);

      return Cotizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible registrar la cotización.'),
      );
    }
  }

  Future<Cotizacion> actualizar(int id, Map<String, dynamic> request) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.cotizaciones}/$id',
        data: request,
      );

      return Cotizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible actualizar la cotización.'),
      );
    }
  }

  Future<Cotizacion> emitir(int id) async {
    try {
      final response = await _dio.patch('${ApiConfig.cotizaciones}/$id/emitir');

      return Cotizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible emitir la cotización.'),
      );
    }
  }

  Future<Cotizacion> anular(int id) async {
    try {
      final response = await _dio.patch('${ApiConfig.cotizaciones}/$id/anular');

      return Cotizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible anular la cotización.'),
      );
    }
  }

  Future<Cotizacion> subirImagenDetalle({
    required int cotizacionId,
    required int detalleId,
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'archivo': MultipartFile.fromBytes(bytes, filename: nombreArchivo),
      });

      final response = await _dio.post(
        '${ApiConfig.cotizaciones}/'
        '$cotizacionId/detalles/$detalleId/imagen',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return Cotizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible subir la imagen del producto.',
        ),
      );
    }
  }

  Future<Cotizacion> eliminarImagenDetalle({
    required int cotizacionId,
    required int detalleId,
  }) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.cotizaciones}/'
        '$cotizacionId/detalles/$detalleId/imagen',
      );

      return Cotizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible eliminar la imagen del producto.',
        ),
      );
    }
  }

  Future<Uint8List> obtenerImagenDetalle({
    required int cotizacionId,
    required int detalleId,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        '${ApiConfig.cotizaciones}/'
        '$cotizacionId/detalles/$detalleId/imagen',
        options: Options(responseType: ResponseType.bytes),
      );

      return Uint8List.fromList(response.data ?? const <int>[]);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible obtener la imagen del producto.',
        ),
      );
    }
  }

  Future<Uint8List> obtenerPdf(int cotizacionId) async {
    try {
      final response = await _dio.get<List<int>>(
        '${ApiConfig.cotizaciones}/$cotizacionId/pdf',
        options: Options(responseType: ResponseType.bytes),
      );

      return Uint8List.fromList(response.data ?? const <int>[]);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible obtener el PDF de la cotización.',
        ),
      );
    }
  }

  String _fecha(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '$anio-$mes-$dia';
  }

  String _obtenerMensajeError(DioException error, String mensajeDefault) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['mensaje'] ?? data['error'];

      if (message != null) {
        return message.toString();
      }
    }

    return mensajeDefault;
  }
}
