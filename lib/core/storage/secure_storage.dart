import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'bencol_access_token';

  static Future<void> guardarToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> obtenerToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> eliminarToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> limpiar() async {
    await _storage.deleteAll();
  }
}
