import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/pagina_proveedores.dart';
import '../models/proveedor.dart';
import '../models/proveedor_request.dart';

class ProveedorService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaProveedores> obtenerProveedores({
    int pagina = 0,
    int tamanio = 20,
    String? texto,
    String? estado,
  }) async {
    try {
      final parametros = <String, dynamic>{
        'pagina': pagina,
        'tamanio': tamanio,
      };

      if (texto != null && texto.trim().isNotEmpty) {
        parametros['texto'] = texto.trim();
      }

      if (estado != null && estado.isNotEmpty) {
        parametros['estado'] = estado;
      }

      final response = await _dio.get(
        ApiConfig.proveedores,
        queryParameters: parametros,
      );

      return PaginaProveedores.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible cargar los proveedores.'),
      );
    }
  }

  Future<Proveedor> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.proveedores}/$id');

      return Proveedor.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible obtener el proveedor.'),
      );
    }
  }

  Future<Proveedor> obtenerPorRuc(String ruc) async {
    try {
      final response = await _dio.get('${ApiConfig.proveedores}/ruc/$ruc');

      return Proveedor.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible obtener el proveedor.'),
      );
    }
  }

  Future<Proveedor> crear(ProveedorRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.proveedores,
        data: request.toJson(),
      );

      return Proveedor.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible crear el proveedor.'),
      );
    }
  }

  Future<Proveedor> actualizar({
    required int id,
    required ProveedorRequest request,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.proveedores}/$id',
        data: request.toJson(),
      );

      return Proveedor.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible actualizar el proveedor.'),
      );
    }
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
