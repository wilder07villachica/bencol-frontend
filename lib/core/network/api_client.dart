import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = _crearDio();

  static Dio _crearDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor());

    return dio;
  }
}
