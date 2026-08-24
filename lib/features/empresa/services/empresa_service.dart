import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/empresa.dart';
import '../models/empresa_request.dart';

class EmpresaService {
  final Dio _dio = ApiClient.dio;

  Future<Empresa?> obtenerActiva() async {
    try {
      final response = await _dio.get('${ApiConfig.empresa}/activa');

      return Empresa.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible obtener los datos de la empresa.',
        ),
      );
    }
  }

  Future<Empresa> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.empresa}/$id');

      return Empresa.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible obtener la empresa.'),
      );
    }
  }

  Future<Empresa> crear(EmpresaRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.empresa,
        data: request.toJson(),
      );

      return Empresa.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible registrar la empresa.'),
      );
    }
  }

  Future<Empresa> actualizar({
    required int id,
    required EmpresaRequest request,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.empresa}/$id',
        data: request.toJson(),
      );

      return Empresa.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible actualizar los datos de la empresa.',
        ),
      );
    }
  }

  Future<Empresa> subirLogo({
    required int empresaId,
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'archivo': MultipartFile.fromBytes(bytes, filename: nombreArchivo),
      });

      final response = await _dio.post(
        '${ApiConfig.empresa}/$empresaId/logo',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return Empresa.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible guardar el logo de la empresa.',
        ),
      );
    }
  }

  Future<Uint8List> obtenerLogo(int empresaId) async {
    try {
      final response = await _dio.get<List<int>>(
        '${ApiConfig.empresa}/$empresaId/logo',
        options: Options(responseType: ResponseType.bytes),
      );

      return Uint8List.fromList(response.data ?? const <int>[]);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible obtener el logo de la empresa.',
        ),
      );
    }
  }

  Future<Empresa> eliminarLogo(int empresaId) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.empresa}/$empresaId/logo',
      );

      return Empresa.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible eliminar el logo de la empresa.',
        ),
      );
    }
  }

  String _obtenerMensajeError(DioException error, String mensajeDefault) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final mensaje = data['message'] ?? data['mensaje'] ?? data['error'];

      if (mensaje != null) {
        return mensaje.toString();
      }
    }

    return mensajeDefault;
  }
}
