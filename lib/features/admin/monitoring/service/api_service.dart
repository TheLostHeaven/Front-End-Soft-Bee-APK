import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sotfbee/features/admin/monitoring/models/model.dart';

class ApiService {
  static const String _baseUrl = 'https://softbee-back-end.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 30);
  static String? _authToken;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ==================== AUTH ====================
  static void setAuthToken(String token) {
    _authToken = token;
  }

  static void clearAuthToken() {
    _authToken = null;
  }

  // ==================== USUARIOS ====================
  static Future<Usuario?> obtenerPerfil() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/users/me'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Usuario.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        clearAuthToken();
        return null;
      } else {
        throw Exception('Error al obtener perfil: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<String> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: _headers,
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final token = result['token'] ?? result['access_token'];
        if (token != null) {
          setAuthToken(token);
          return token;
        } else {
          throw Exception('Token no recibido');
        }
      } else {
        throw Exception('Credenciales inválidas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== APIARIOS ====================
static Future<List<Apiario>> obtenerApiarios({int? userId}) async {
  try {
    final String url = userId != null 
      ? '$_baseUrl/users/$userId/apiaries' 
      : '$_baseUrl/apiaries';

    debugPrint('Obteniendo apiarios desde: $url');

    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(_timeout);

    debugPrint('Respuesta obtener apiarios: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Apiario.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return []; // Retorna lista vacía si no hay apiarios
    } else if (response.statusCode == 401) {
      clearAuthToken();
      throw Exception('Sesión expirada');
    } else {
      throw Exception('Error al obtener apiarios: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error en obtenerApiarios: $e');
    throw Exception('Error de conexión: $e');
  }
}

 static Future<int> crearApiario(Map<String, dynamic> data) async {
  try {
    // Obtener user_id del token JWT o de la sesión
    final user = await obtenerPerfil();
    if (user == null) throw Exception('Usuario no autenticado');
    
    if (data['name'] == null) {
      throw Exception('Nombre es requerido');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/apiaries'),
      headers: _headers,
      body: json.encode({
        'name': data['name'],
        'user_id': user.id,  // Asegurar que se envía el user_id
        'location': data['location'],
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body)['id'];
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    debugPrint('Error en crearApiario: $e');
    throw Exception('Error al crear apiario');
  }
}

  static Future<Apiario?> obtenerApiario(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/apiaries/$id'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Apiario.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener apiario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> actualizarApiario(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/apiaries/$id'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar apiario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> eliminarApiario(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/apiaries/$id'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar apiario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== COLMENAS ====================
  static Future<List<Colmena>> obtenerColmenas(int apiarioId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/apiaries/$apiarioId/hives'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Colmena.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener colmenas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<int> crearColmena(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/hives'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        return result['id'] ?? -1;
      } else {
        throw Exception('Error al crear colmena: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== PREGUNTAS ====================
  static Future<List<Pregunta>> obtenerPreguntasApiario(
    int apiarioId, {
    bool soloActivas = true,
  }) async {
    try {
      String url = '$_baseUrl/apiaries/$apiarioId/questions';
      if (soloActivas) {
        url += '?active_only=true';
      }

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Pregunta.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener preguntas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<String> crearPregunta(Pregunta pregunta) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/questions'),
            headers: _headers,
            body: json.encode(pregunta.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        return result['id'] ?? '';
      } else {
        throw Exception('Error al crear pregunta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> actualizarPregunta(
    String preguntaId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/questions/$preguntaId'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar pregunta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> eliminarPregunta(String preguntaId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/questions/$preguntaId'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar pregunta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> reordenarPreguntas(
    int apiarioId,
    List<String> orden,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/apiaries/$apiarioId/questions/reorder'),
            headers: _headers,
            body: json.encode({'order': orden}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Error al reordenar preguntas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== NOTIFICACIONES REINA ====================
  static Future<List<NotificacionReina>> obtenerNotificacionesReina({
    int? apiarioId,
    bool soloNoLeidas = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      String url = '$_baseUrl/queen-notifications';
      List<String> params = [];

      if (apiarioId != null) params.add('apiario_id=$apiarioId');
      if (soloNoLeidas) params.add('unread_only=true');
      params.add('limit=$limit');
      params.add('offset=$offset');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NotificacionReina.fromJson(json)).toList();
      } else {
        throw Exception(
          'Error al obtener notificaciones: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<int> crearNotificacionReina(
    NotificacionReina notificacion,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/queen-notifications'),
            headers: _headers,
            body: json.encode(notificacion.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        return result['id'] ?? -1;
      } else {
        throw Exception('Error al crear notificación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> marcarNotificacionComoLeida(int notificacionId) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/queen-notifications/$notificacionId/read'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Error al marcar notificación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> marcarVariasNotificacionesComoLeidas(
    List<int> notificacionIds,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/queen-notifications/bulk-read'),
            headers: _headers,
            body: json.encode({'notification_ids': notificacionIds}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Error al marcar notificaciones: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== MONITOREO ====================
  static Future<int> crearMonitoreo(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/monitoreos'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        return result['id'] ?? -1;
      } else {
        throw Exception('Error al crear monitoreo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<Monitoreo>> obtenerMonitoreos({
    int? apiarioId,
    int? colmenaId,
  }) async {
    try {
      String url = '$_baseUrl/monitoreos';
      List<String> params = [];

      if (apiarioId != null) params.add('apiario_id=$apiarioId');
      if (colmenaId != null) params.add('colmena_id=$colmenaId');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Monitoreo.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener monitoreos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== UTILIDADES ====================
  static Future<bool> verificarConexion() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'), headers: _headers)
          .timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> obtenerEstadisticas({
    int? apiarioId,
  }) async {
    try {
      String url = '$_baseUrl/stats';
      if (apiarioId != null) {
        url += '?apiario_id=$apiarioId';
      }

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Error al obtener estadísticas: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
