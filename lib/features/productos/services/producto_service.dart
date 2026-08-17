import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/pagina_productos.dart';
import '../models/producto.dart';
import '../models/producto_request.dart';

class ProductoService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaProductos> obtenerProductos({
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
        ApiConfig.productos,
        queryParameters: parametros,
      );

      return PaginaProductos.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible cargar los productos.'),
      );
    }
  }

  Future<Producto> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.productos}/$id');

      return Producto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible obtener el producto.'),
      );
    }
  }

  Future<Producto> crear(ProductoRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.productos,
        data: request.toJson(),
      );

      return Producto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible registrar el producto.'),
      );
    }
  }

  Future<Producto> actualizar(int id, ProductoRequest request) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.productos}/$id',
        data: request.toJson(),
      );

      return Producto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _obtenerMensajeError(error, 'No fue posible actualizar el producto.'),
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
