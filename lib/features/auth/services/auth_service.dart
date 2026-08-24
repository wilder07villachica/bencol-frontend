import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/auth_user.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(ApiConfig.login, data: request.toJson());

      final loginResponse = LoginResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      await SecureStorage.guardarToken(loginResponse.token);

      return loginResponse;
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message'];

        if (message != null) {
          throw Exception(message.toString());
        }
      }

      throw Exception('No fue posible iniciar sesión.');
    }
  }

  Future<AuthUser> obtenerUsuarioActual() async {
    try {
      final response = await _dio.get(ApiConfig.me);

      return AuthUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message'];

        if (message != null) {
          throw Exception(message.toString());
        }
      }

      throw Exception('No fue posible obtener el usuario autenticado.');
    }
  }

  Future<bool> haySesion() async {
    final token = await SecureStorage.obtenerToken();

    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await SecureStorage.eliminarToken();
  }
}
