import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

import '../models/caja.dart';
import '../models/caja_request.dart';
import '../models/cierre_caja_request.dart';
import '../models/movimiento_caja.dart';
import '../models/movimiento_caja_request.dart';
import '../models/pagina_cajas.dart';
import '../models/pagina_movimientos_caja.dart';

class CajaService {
  final Dio _dio = ApiClient.dio;

  Future<PaginaCajas> obtenerCajas({
    int pagina = 0,
    int tamanio = 20,
    String? estado,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final parametros = <String, dynamic>{
        'pagina': pagina,
        'tamanio': tamanio,
      };

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
        ApiConfig.caja,
        queryParameters: parametros,
      );

      return PaginaCajas.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(_mensajeError(error, 'No fue posible cargar las cajas.'));
    }
  }

  Future<Caja?> obtenerCajaAbierta() async {
    try {
      final response = await _dio.get('${ApiConfig.caja}/abierta');

      return Caja.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      /*
       * Tu backend lanza BusinessException cuando
       * no existe caja abierta.
       *
       * Dependiendo de tu GlobalExceptionHandler,
       * puede regresar 400, 404 u otro código.
       *
       * Por eso comprobamos también el mensaje.
       */
      final mensaje = _mensajeError(error, 'No hay una caja abierta.');

      final texto = mensaje.toLowerCase();

      if (texto.contains('no') &&
          texto.contains('caja') &&
          texto.contains('abierta')) {
        return null;
      }

      throw Exception(mensaje);
    }
  }

  Future<Caja> obtenerPorId(int id) async {
    try {
      final response = await _dio.get('${ApiConfig.caja}/$id');

      return Caja.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(_mensajeError(error, 'No fue posible obtener la caja.'));
    }
  }

  Future<Caja> abrirCaja(CajaRequest request) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.caja}/abrir',
        data: request.toJson(),
      );

      return Caja.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(_mensajeError(error, 'No fue posible abrir la caja.'));
    }
  }

  Future<Caja> cerrarCaja({
    required int cajaId,
    required CierreCajaRequest request,
  }) async {
    try {
      final response = await _dio.patch(
        '${ApiConfig.caja}/$cajaId/cerrar',
        data: request.toJson(),
      );

      return Caja.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(_mensajeError(error, 'No fue posible cerrar la caja.'));
    }
  }

  Future<MovimientoCaja> registrarMovimiento(
    MovimientoCajaRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.caja}/movimientos',
        data: request.toJson(),
      );

      return MovimientoCaja.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible registrar el movimiento de caja.'),
      );
    }
  }

  Future<PaginaMovimientosCaja> obtenerMovimientos({
    int pagina = 0,
    int tamanio = 20,
    int? cajaId,
    String? tipoMovimiento,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final parametros = <String, dynamic>{
        'pagina': pagina,
        'tamanio': tamanio,
      };

      if (cajaId != null) {
        parametros['cajaId'] = cajaId;
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
        '${ApiConfig.caja}/movimientos',
        queryParameters: parametros,
      );

      return PaginaMovimientosCaja.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw Exception(
        _mensajeError(error, 'No fue posible cargar los movimientos de caja.'),
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
