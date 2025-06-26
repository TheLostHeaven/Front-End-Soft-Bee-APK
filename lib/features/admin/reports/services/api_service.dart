import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sotfbee/features/admin/reports/model/api_models.dart';

class ApiService {
  static const String baseUrl =
      'https://softbee-back-end.onrender.com/api'; // Cambia por tu URL del backend

  // Headers comunes
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Manejo de errores
  static void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Error desconocido');
    }
  }

  // ========== ENDPOINTS DE MONITOREO ==========

  /// Obtiene todos los monitoreos
  static Future<List<Monitoreo>> getAllMonitoreos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/monitoreos'),
        headers: headers,
      );

      _handleError(response);

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Monitoreo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener monitoreos: $e');
    }
  }

  /// Obtiene monitoreos por apiario
  static Future<List<Monitoreo>> getMonitoreosByApiario(int apiarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/apiarios/$apiarioId/monitoreos'),
        headers: headers,
      );

      _handleError(response);

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Monitoreo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener monitoreos del apiario: $e');
    }
  }

  /// Obtiene monitoreos por colmena
  static Future<List<Monitoreo>> getMonitoreosByColmena(int colmenaId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/colmenas/$colmenaId/monitoreos'),
        headers: headers,
      );

      _handleError(response);

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Monitoreo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener monitoreos de la colmena: $e');
    }
  }

  /// Crea un nuevo monitoreo
  static Future<int> createMonitoreo({
    required int idColmena,
    required int idApiario,
    DateTime? fecha,
    List<Map<String, dynamic>>? respuestas,
    Map<String, dynamic>? datosAdicionales,
  }) async {
    try {
      final body = {
        'id_colmena': idColmena,
        'id_apiario': idApiario,
        'fecha': fecha?.toIso8601String(),
        'respuestas': respuestas ?? [],
        'datos_adicionales': datosAdicionales,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/monitoreos'),
        headers: headers,
        body: json.encode(body),
      );

      _handleError(response);

      final data = json.decode(response.body);
      return data['id'];
    } catch (e) {
      throw Exception('Error al crear monitoreo: $e');
    }
  }

  /// Obtiene un monitoreo específico
  static Future<Monitoreo> getMonitoreo(int monitoreoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/monitoreos/$monitoreoId'),
        headers: headers,
      );

      _handleError(response);

      final data = json.decode(response.body);
      return Monitoreo.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener monitoreo: $e');
    }
  }

  /// Obtiene estadísticas del sistema
  static Future<SystemStats> getSystemStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: headers,
      );

      _handleError(response);

      final data = json.decode(response.body);
      return SystemStats.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // ========== ENDPOINTS DE APIARIOS ==========

  /// Obtiene todos los apiarios
  static Future<List<Apiario>> getAllApiarios() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/apiaries'),
        headers: headers,
      );

      _handleError(response);

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Apiario.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener apiarios: $e');
    }
  }

  /// Obtiene apiarios de un usuario
  static Future<List<Apiario>> getUserApiarios(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/apiaries'),
        headers: headers,
      );

      _handleError(response);

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Apiario.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener apiarios del usuario: $e');
    }
  }

  /// Obtiene un apiario específico
  static Future<Apiario> getApiario(int apiarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/apiaries/$apiarioId'),
        headers: headers,
      );

      _handleError(response);

      final data = json.decode(response.body);
      return Apiario.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener apiario: $e');
    }
  }

  /// Crea un nuevo apiario
  static Future<int> createApiario({
    required int userId,
    required String name,
    String? location,
  }) async {
    try {
      final body = {'user_id': userId, 'name': name, 'location': location};

      final response = await http.post(
        Uri.parse('$baseUrl/apiaries'),
        headers: headers,
        body: json.encode(body),
      );

      _handleError(response);

      final data = json.decode(response.body);
      return data['id'];
    } catch (e) {
      throw Exception('Error al crear apiario: $e');
    }
  }

  // ========== ENDPOINTS DE USUARIOS ==========

  /// Obtiene todos los usuarios
  static Future<List<Usuario>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: headers,
      );

      _handleError(response);

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Usuario.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  /// Obtiene un usuario específico
  static Future<Usuario> getUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      _handleError(response);

      final data = json.decode(response.body);
      return Usuario.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  // ========== HEALTH CHECK ==========

  /// Verifica el estado del servidor
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      );

      _handleError(response);

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error en health check: $e');
    }
  }

  // ========== INICIAR MONITOREO POR VOZ ==========

  /// Inicia el monitoreo por voz
  static Future<Map<String, dynamic>> iniciarMonitoreoVoz() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/monitoreo/iniciar'),
        headers: headers,
      );

      _handleError(response);

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error al iniciar monitoreo por voz: $e');
    }
  }
}
