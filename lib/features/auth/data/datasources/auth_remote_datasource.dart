import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:sotfbee/features/auth/data/models/user_model.dart';

void _debugPrint(String message) {
  developer.log(message, name: 'AuthService');
}

class AuthService {
  static const String _baseUrl = 'https://softbee-back-end-1.onrender.com/api';

  static Future<Map<String, dynamic>> login(
    String identifier,
    String password,
  ) async {
    try {
      // Determina si el identificador es email o username
      final String fieldKey = identifier.contains('@') ? 'email' : 'username';
      
      final Map<String, String> loginData = {
        fieldKey: identifier.trim(),
        'password': password.trim(),
      };

      _debugPrint("Enviando credenciales de login: ${jsonEncode(loginData)}");

      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(loginData),
          )
          .timeout(const Duration(seconds: 30));

      _debugPrint("Respuesta de login: ${response.statusCode} - ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': responseBody['token'],
          'user_id': responseBody['user_id'],
          'username': responseBody['username'],
          'email': responseBody['email'],
          'message': 'Inicio de sesión exitoso',
        };
      } else {
        return {
          'success': false,
          'message':
              responseBody['message'] ??
                  responseBody['error'] ??
                  'Error en el inicio de sesión',
        };
      }
    } catch (e) {
      _debugPrint("Error en login: $e");
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>?> verifyToken(String token) async {
    try {
      _debugPrint("Verificando token...");
      final response = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      _debugPrint("Respuesta de verificación: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      _debugPrint("Error al verificar token: $e");
      return null;
    }
  }

  static Future<UserProfile?> getUserProfile(String token) async {
    try {
      _debugPrint("Obteniendo perfil de usuario...");
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      _debugPrint("Respuesta de perfil: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      _debugPrint("Error al obtener perfil: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
    List<Map<String, dynamic>> apiaries,
  ) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final generatedUsername = generateUsername(normalizedEmail);

      final requestBody = {
        'nombre': name.trim(),
        'username': generatedUsername,
        'email': normalizedEmail,
        'phone': phone.trim(),
        'password': password.trim(),
        'apiarios': apiaries,
      };

      _debugPrint("Enviando registro: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      );

      _debugPrint("Respuesta de registro: ${response.statusCode} - ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'token': responseBody['token'],
          'user_id': responseBody['user_id'],
          'message': responseBody['message'] ?? 'Registro exitoso',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['error'] ?? 'Error en el registro',
        };
      }
    } catch (e) {
      _debugPrint("Error en registro: $e");
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static String generateUsername(String email) {
    final username = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    _debugPrint("Username generado: $username");
    return username;
  }

  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      _debugPrint("Solicitando reset de contraseña para: $normalizedEmail");

      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': normalizedEmail,
          'reset_url':
              'https://soffiasanchezz.github.io/SoftBee-Frontend/#/reset-password?token={token]',
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Correo enviado exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['error'] ?? 'Error al enviar correo',
        };
      }
    } catch (e) {
      _debugPrint("Error en solicitud de reset: $e");
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }
  // Resetear contraseña con token
  static Future<Map<String, dynamic>> resetPassword(
    String token,
    String newPassword,
  ) async {
    try {
      _debugPrint("Reseteando contraseña con token: $token");
      
      if (newPassword.length < 8) {
        return {
          'success': false,
          'message': 'La contraseña debe tener al menos 8 caracteres'
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
        }),
      );

      _debugPrint("Respuesta de reset: ${response.statusCode} - ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Contraseña actualizada exitosamente'
        };
      } else {
        return {
          'success': false,
          'message': responseBody['error'] ?? 
                    responseBody['detail'] ?? 
                    'Error al cambiar contraseña'
        };
      }
    } catch (e) {
      _debugPrint("Error al resetear contraseña: $e");
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  // Cambiar contraseña (usuario autenticado)
  static Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
    String token,
  ) async {
    try {
      _debugPrint("Cambiando contraseña...");

      if (newPassword.length < 8) {
        return {
          'success': false,
          'message': 'La nueva contraseña debe tener al menos 8 caracteres',
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'current_password': currentPassword.trim(),
          'new_password': newPassword.trim(),
        }),
      );

      _debugPrint(
        "Respuesta de cambio: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Contraseña cambiada exitosamente'};
      } else {
        final responseBody = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseBody['error'] ?? 'Error cambiando contraseña',
        };
      }
    } catch (e) {
      _debugPrint("Error al cambiar contraseña: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateProfilePicture(
    String token,
    int userId,
    String newImagePath,
  ) async {
    try {
      _debugPrint("Actualizando foto de perfil...");
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/profile_picture'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'profile_picture': newImagePath}),
      );

      _debugPrint("Respuesta de foto: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': 'Error actualizando foto de perfil',
        };
      }
    } catch (e) {
      _debugPrint("Error al actualizar foto: $e");
      return {'success': false, 'message': e.toString()};
    }
  }
}