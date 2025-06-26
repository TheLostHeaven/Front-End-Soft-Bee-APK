import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:sotfbee/features/auth/data/models/user_model.dart';
import 'package:sotfbee/features/auth/data/datasources/auth_local_datasource.dart';

void _debugPrint(String message) {
  developer.log(message, name: 'UserService');
}

class UserService {
  static const String _baseUrl = 'https://softbee-back-end.onrender.com/api';

  // Obtener todos los usuarios
  static Future<List<UserProfile>> getAllUsers() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) throw Exception('No autenticado');

      _debugPrint("Obteniendo todos los usuarios...");
      final response = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      _debugPrint(
        "Respuesta usuarios: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        return usersJson.map((json) => UserProfile.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      _debugPrint("Error al obtener usuarios: $e");
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener usuario por ID
  static Future<UserProfile?> getUserById(int userId) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) throw Exception('No autenticado');

      _debugPrint("Obteniendo usuario ID: $userId");
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      _debugPrint(
        "Respuesta usuario: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener usuario: ${response.statusCode}');
      }
    } catch (e) {
      _debugPrint("Error al obtener usuario: $e");
      throw Exception('Error de conexión: $e');
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
      if (token == null) throw Exception('No autenticado');

      final userData = {
        'nombre': nombre.trim(),
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password.trim(),
      };

      _debugPrint("Creando usuario: ${jsonEncode(userData)}");

      final response = await http.post(
        Uri.parse('$_baseUrl/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(userData),
      );

      _debugPrint(
        "Respuesta crear usuario: ${response.statusCode} - ${response.body}",
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'id': responseBody['id'],
          'message': 'Usuario creado exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['error'] ?? 'Error al crear usuario',
        };
      }
    } catch (e) {
      _debugPrint("Error al crear usuario: $e");
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar usuario
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? nombre,
    String? email,
    String? phone,
    String? password,
  }) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) throw Exception('No autenticado');

      final updateData = <String, dynamic>{};
      if (nombre != null) updateData['nombre'] = nombre.trim();
      if (email != null) updateData['email'] = email.trim().toLowerCase();
      if (phone != null) updateData['phone'] = phone.trim();
      if (password != null) updateData['password'] = password.trim();

      if (updateData.isEmpty) {
        return {'success': false, 'message': 'No hay datos para actualizar'};
      }

      _debugPrint("Actualizando usuario $userId: ${jsonEncode(updateData)}");

      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(updateData),
      );

      _debugPrint(
        "Respuesta actualizar: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario actualizado exitosamente'};
      } else {
        final responseBody = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseBody['error'] ?? 'Error al actualizar usuario',
        };
      }
    } catch (e) {
      _debugPrint("Error al actualizar usuario: $e");
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar usuario
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) throw Exception('No autenticado');

      _debugPrint("Eliminando usuario ID: $userId");

      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      _debugPrint(
        "Respuesta eliminar: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario eliminado exitosamente'};
      } else {
        final responseBody = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseBody['error'] ?? 'Error al eliminar usuario',
        };
      }
    } catch (e) {
      _debugPrint("Error al eliminar usuario: $e");
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
