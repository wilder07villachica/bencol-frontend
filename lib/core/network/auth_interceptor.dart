import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;

    if (path == ApiConfig.login) {
      handler.next(options);
      return;
    }

    final token = await SecureStorage.obtenerToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (statusCode == 401 && path == ApiConfig.me) {
      await SecureStorage.eliminarToken();
    }

    handler.next(err);
  }
}
