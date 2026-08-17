import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/cliente_precio.dart';
import '../models/cliente_precio_request.dart';
import '../models/pagina_precios_clientes.dart';

class ClientePrecioService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaPreciosClientes> obtenerPrecios({
    int pagina = 0,
    int tamanio = 20,
    int? clienteId,
    int? productoId,
  }) async {
    try {
      final parametros = <String, dynamic>{
        'pagina': pagina,
        'tamanio': tamanio,
      };

      if (clienteId != null) {
        parametros['clienteId'] = clienteId;
      }

      if (productoId != null) {
        parametros['productoId'] = productoId;
      }

      final response = await _dio.get(
        ApiConfig.preciosClientes,
        queryParameters: parametros,
      );

      return PaginaPreciosClientes.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible cargar los precios especiales.',
        ),
      );
    }
  }

  Future<ClientePrecio> crear(ClientePrecioRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.preciosClientes,
        data: request.toJson(),
      );

      return ClientePrecio.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible registrar el precio especial.',
        ),
      );
    }
  }

  Future<ClientePrecio> actualizar(int id, ClientePrecioRequest request) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.preciosClientes}/$id',
        data: request.toJson(),
      );

      return ClientePrecio.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible actualizar el precio especial.',
        ),
      );
    }
  }

  Future<void> eliminar(int id) async {
    try {
      await _dio.delete('${ApiConfig.preciosClientes}/$id');
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(
          error,
          'No fue posible eliminar el precio especial.',
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
