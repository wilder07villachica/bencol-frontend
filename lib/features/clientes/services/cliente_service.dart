import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/cliente.dart';
import '../models/cliente_request.dart';
import '../models/pagina_clientes.dart';

class ClienteService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaClientes> obtenerClientes({
    int pagina = 0,
    int tamanio = 20,
    String? texto,
    String? estado,
    String? categoria,
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

      if (categoria != null && categoria.isNotEmpty) {
        parametros['categoria'] = categoria;
      }

      final response = await _dio.get(
        ApiConfig.clientes,
        queryParameters: parametros,
      );

      return PaginaClientes.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible cargar los clientes.'),
      );
    }
  }

  Future<Cliente> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.clientes}/$id');

      return Cliente.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible obtener el cliente.'),
      );
    }
  }

  Future<Cliente> crear(ClienteRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.clientes,
        data: request.toJson(),
      );

      return Cliente.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible registrar el cliente.'),
      );
    }
  }

  Future<Cliente> actualizar(int id, ClienteRequest request) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.clientes}/$id',
        data: request.toJson(),
      );

      return Cliente.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible actualizar el cliente.'),
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
