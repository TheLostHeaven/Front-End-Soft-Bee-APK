import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:sotfbee/features/auth/data/models/user_model.dart';
import 'package:sotfbee/features/auth/data/datasources/auth_local_datasource.dart';

class UserService {
  static const String _baseUrl = 'https://softbee-back-end.onrender.com/api';
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // Obtener el perfil del usuario actual
  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        developer.log("No se encontró token en el almacenamiento", error: true);
        throw Exception("No autenticado - Token no disponible");
      }

      developer.log("Obteniendo perfil del usuario actual...");

      final response = await http
          .get(Uri.parse('$_baseUrl/users/me'), headers: _buildHeaders(token))
          .timeout(_timeoutDuration);

      developer.log(
        "Respuesta de perfil: ${response.statusCode} - ${response.body}",
      );

      return _handleUserResponse(response);
    } catch (e) {
      developer.log("Error al obtener perfil: $e", error: true);
      rethrow;
    }
  }

  // Obtener todos los usuarios (solo admin)
  static Future<List<UserProfile>> getAllUsers() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null)
        throw Exception("No autenticado - Token no disponible");

      developer.log("Obteniendo todos los usuarios...");

      final response = await http
          .get(Uri.parse('$_baseUrl/users'), headers: _buildHeaders(token))
          .timeout(_timeoutDuration);

      developer.log(
        "Respuesta de usuarios: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        return usersJson.map((json) => UserProfile.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      developer.log("Error al obtener usuarios: $e", error: true);
      rethrow;
    }
  }

  // Crear nuevo usuario
  static Future<Map<String, dynamic>> createUser({
    required String nombre,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null)
        throw Exception("No autenticado - Token no disponible");

      final userData = {
        'nombre': nombre.trim(),
        'username': username.trim().toLowerCase(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password.trim(),
      };

      developer.log("Creando usuario: ${jsonEncode(userData)}");

      final response = await http
          .post(
            Uri.parse('$_baseUrl/users'),
            headers: _buildHeaders(token),
            body: jsonEncode(userData),
          )
          .timeout(_timeoutDuration);

      developer.log(
        "Respuesta de creación: ${response.statusCode} - ${response.body}",
      );

      return _handleStandardResponse(response);
    } catch (e) {
      developer.log("Error al crear usuario: $e", error: true);
      rethrow;
    }
  }

  // Actualizar usuario
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    required String nombre,
    required String email,
    required String phone,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null)
        throw Exception("No autenticado - Token no disponible");

      final userData = {
        'nombre': nombre.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
      };

      developer.log("Actualizando usuario $userId: ${jsonEncode(userData)}");

      final response = await http
          .put(
            Uri.parse('$_baseUrl/users/$userId'),
            headers: _buildHeaders(token),
            body: jsonEncode(userData),
          )
          .timeout(_timeoutDuration);

      developer.log(
        "Respuesta de actualización: ${response.statusCode} - ${response.body}",
      );

      return _handleStandardResponse(response);
    } catch (e) {
      developer.log("Error al actualizar usuario: $e", error: true);
      rethrow;
    }
  }

  // Eliminar usuario
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null)
        throw Exception("No autenticado - Token no disponible");

      developer.log("Eliminando usuario ID: $userId");

      final response = await http
          .delete(
            Uri.parse('$_baseUrl/users/$userId'),
            headers: _buildHeaders(token),
          )
          .timeout(_timeoutDuration);

      developer.log(
        "Respuesta de eliminación: ${response.statusCode} - ${response.body}",
      );

      return _handleStandardResponse(response);
    } catch (e) {
      developer.log("Error al eliminar usuario: $e", error: true);
      rethrow;
    }
  }

  // Métodos auxiliares privados
  static Map<String, String> _buildHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
  }

  static UserProfile? _handleUserResponse(http.Response response) {
    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserProfile.fromJson(responseBody);
    } else if (response.statusCode == 401) {
      developer.log("Token inválido o expirado", error: true);
      throw Exception("Sesión expirada, por favor inicia sesión nuevamente");
    } else {
      throw _handleErrorResponse(response);
    }
  }

  static Map<String, dynamic> _handleStandardResponse(http.Response response) {
    final responseBody = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': responseBody,
        'message': responseBody['message'] ?? 'Operación exitosa',
      };
    } else if (response.statusCode == 401) {
      developer.log("Token inválido o expirado", error: true);
      return {
        'success': false,
        'error': 'Sesión expirada',
        'message': 'Por favor inicia sesión nuevamente',
      };
    } else {
      return {
        'success': false,
        'error': responseBody['error'] ?? 'Error en la operación',
        'message':
            responseBody['message'] ??
            responseBody['detail'] ??
            'Error desconocido (${response.statusCode})',
        'statusCode': response.statusCode,
      };
    }
  }

  static Exception _handleErrorResponse(http.Response response) {
    final responseBody = jsonDecode(response.body);
    final errorMessage =
        responseBody['error'] ??
        responseBody['message'] ??
        'Error desconocido (${response.statusCode})';
    return Exception(errorMessage);
  }
}
