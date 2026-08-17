import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/compra.dart';
import '../models/compra_request.dart';
import '../models/pagina_compras.dart';

class CompraService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaCompras> obtenerCompras({
    int pagina = 0,
    int tamanio = 20,
    String? codigo,
    int? proveedorId,
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

      if (proveedorId != null) {
        parametros['proveedorId'] = proveedorId;
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
        ApiConfig.compras,
        queryParameters: parametros,
      );

      return PaginaCompras.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible cargar las compras.'),
      );
    }
  }

  Future<Compra> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.compras}/$id');

      return Compra.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible obtener la compra.'),
      );
    }
  }

  Future<Compra> obtenerPorCodigo(String codigo) async {
    try {
      final response = await _dio.get('${ApiConfig.compras}/codigo/$codigo');

      return Compra.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible obtener la compra.'),
      );
    }
  }

  Future<List<Compra>> obtenerPorProveedor(int proveedorId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.compras}/proveedor/$proveedorId',
      );

      final lista = response.data as List<dynamic>;

      return lista
          .map((item) => Compra.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(
          error,
          'No fue posible cargar las compras del proveedor.',
        ),
      );
    }
  }

  Future<Compra> crear(CompraRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.compras,
        data: request.toJson(),
      );

      return Compra.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible registrar la compra.'),
      );
    }
  }

  Future<Compra> anular(int compraId) async {
    try {
      final response = await _dio.patch(
        '${ApiConfig.compras}/$compraId/anular',
      );

      return Compra.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(_mensajeError(error, 'No fue posible anular la compra.'));
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
