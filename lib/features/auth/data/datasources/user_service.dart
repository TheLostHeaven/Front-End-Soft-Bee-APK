import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:sotfbee/features/auth/data/models/user_model.dart';
import 'package:sotfbee/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class UserService {
  static const String _baseUrl = 'https://softbee-back-end-1.onrender.com/api';
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // Obtener el perfil del usuario actual
  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) throw Exception("Token no disponible");

      final response = await http
          .get(Uri.parse('$_baseUrl/users/me'), headers: _buildHeaders(token))
          .timeout(_timeoutDuration);

      developer.log("Perfil: ${response.statusCode} ${response.body}");
      return _handleUserResponse(response);
    } catch (e) {
      developer.log("Error perfil: $e", error: true);
      rethrow;
    }
  }

  // Obtener todos los usuarios
  static Future<List<UserProfile>> getAllUsers() async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Token no disponible");

    final response = await http
        .get(Uri.parse('$_baseUrl/users'), headers: _buildHeaders(token))
        .timeout(_timeoutDuration);

    if (response.statusCode == 200) {
      final List<dynamic> usersJson = jsonDecode(response.body);
      return usersJson.map((json) => UserProfile.fromJson(json)).toList();
    } else {
      throw _handleErrorResponse(response);
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
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Token no disponible");

    final userData = {
      'nombre': nombre.trim(),
      'username': username.trim().toLowerCase(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'password': password.trim(),
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/users'),
          headers: _buildHeaders(token),
          body: jsonEncode(userData),
        )
        .timeout(_timeoutDuration);

    return _handleStandardResponse(response);
  }

  // Actualizar datos del usuario
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    required String nombre,
    required String username,
    required String email,
    required String phone,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Token no disponible");

    final userData = {
      'nombre': nombre.trim(),
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
    };

    final response = await http
        .put(
          Uri.parse('$_baseUrl/users/$userId'),
          headers: _buildHeaders(token),
          body: jsonEncode(userData),
        )
        .timeout(_timeoutDuration);

    return _handleStandardResponse(response);
  }

  // 🔧 Subir foto de perfil corregido
  static Future<Map<String, dynamic>> updateProfilePicture({
    required int userId,
    required XFile file,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Token no disponible");

    final uri = Uri.parse('$_baseUrl/users/$userId/profile-picture');
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file', // ✅ CORREGIDO: debe ser "file"
        bytes,
        filename: file.name,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // ✅ CORREGIDO: debe ser "file"
          file.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Imagen actualizada correctamente'};
    } else {
      final responseBody = jsonDecode(response.body);
      return {
        'success': false,
        'message': responseBody['message'] ?? 'Error al subir imagen',
      };
    }
  }

  // Eliminar usuario
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Token no disponible");

    final response = await http
        .delete(
          Uri.parse('$_baseUrl/users/$userId'),
          headers: _buildHeaders(token),
        )
        .timeout(_timeoutDuration);

    return _handleStandardResponse(response);
  }

  // Headers comunes
  static Map<String, String> _buildHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
  }

  // Manejo de respuestas
  static UserProfile? _handleUserResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserProfile.fromJson(body);
    } else {
      throw _handleErrorResponse(response);
    }
  }

  static Map<String, dynamic> _handleStandardResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': body,
        'message': body['message'] ?? 'Operación exitosa',
      };
    } else {
      return {
        'success': false,
        'error': body['error'] ?? 'Error desconocido',
        'message': body['message'] ?? body['detail'] ?? '',
      };
    }
  }

  static Exception _handleErrorResponse(http.Response response) {
    final body = jsonDecode(response.body);
    final msg = body['error'] ?? body['message'] ?? 'Error inesperado';
    return Exception(msg);
  }
}