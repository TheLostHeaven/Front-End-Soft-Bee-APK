import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sotfbee/features/admin/history/models/monitoreo_models.dart';
import 'package:sotfbee/features/admin/history/service/local_storage_service.dart';
import 'package:sotfbee/features/auth/data/datasources/auth_local_datasource.dart'; // Add this import

class ApiService {
  static const String baseUrl =
      'https://softbee-back-end.onrender.com/api'; // Reemplaza con tu URL de Apiary
  static const String flaskBaseUrl =
      'https://softbee-back-end.onrender.com/api'; // URL de tu backend Flask

  final LocalStorageService _localStorage = LocalStorageService();

  // Headers para Apiary
  Future<Map<String, String>> get _headers async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Obtener todos los monitoreos
  Future<List<MonitoreoModel>> getMonitoreos() async {
    try {
      // Intentar obtener datos del servidor
      final response = await http
          .get(Uri.parse('$baseUrl/monitoreos'), headers: await _headers)
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final monitoreos = data
            .map((json) => MonitoreoModel.fromJson(json))
            .toList();

        // Guardar en almacenamiento local
        await _localStorage.saveMonitoreos(monitoreos);

        return monitoreos;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener monitoreos: $e');
      // Retornar lista vacía en caso de error
      return [];
    }
  }

  // Obtener monitoreos por apiario
  Future<List<MonitoreoModel>> getMonitoreosByApiario(int apiarioId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/apiarios/$apiarioId/monitoreos'),
            headers: await _headers,
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => MonitoreoModel.fromJson(json)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener monitoreos por apiario: $e');
      // Retornar lista vacía en caso de error
      return [];
    }
  }

  // Crear nuevo monitoreo
  Future<MonitoreoModel?> createMonitoreo(MonitoreoModel monitoreo) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/monitoreos'),
            headers: await _headers,
            body: json.encode(monitoreo.toJson()),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final newMonitoreo = MonitoreoModel.fromJson(data);

        // Actualizar almacenamiento local
        await _localStorage.addMonitoreo(newMonitoreo);

        return newMonitoreo;
      } else {
        throw Exception('Error al crear monitoreo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al crear monitoreo: $e');
      // Guardar localmente para sincronizar después
      final localMonitoreo = MonitoreoModel(
        id: DateTime.now().millisecondsSinceEpoch, // ID temporal
        idColmena: monitoreo.idColmena,
        idApiario: monitoreo.idApiario,
        fecha: monitoreo.fecha,
        respuestas: monitoreo.respuestas,
        datosAdicionales: monitoreo.datosAdicionales,
        sincronizado: false,
      );

      await _localStorage.addMonitoreo(localMonitoreo);
      return localMonitoreo;
    }
  }

  // Obtener preguntas por apiario
  Future<List<QuestionModel>> getQuestionsByApiario(int apiarioId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/apiarios/$apiarioId/questions'),
            headers: await _headers,
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final questions = data
            .map((json) => QuestionModel.fromJson(json))
            .toList();

        // Guardar en almacenamiento local
        await _localStorage.saveQuestions(apiarioId, questions);

        return questions;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener preguntas: $e');
      // Obtener preguntas locales
      return await _localStorage.getQuestions(apiarioId);
    }
  }

  // Sincronizar datos pendientes
  Future<void> syncPendingData() async {
    try {
      final pendingMonitoreos = await _localStorage.getPendingSync();

      for (final monitoreo in pendingMonitoreos) {
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/monitoreos'),
            headers: await _headers,
            body: json.encode(monitoreo.toJson()),
          );

          if (response.statusCode == 201) {
            // Marcar como sincronizado
            final syncedMonitoreo = MonitoreoModel(
              id: monitoreo.id,
              idColmena: monitoreo.idColmena,
              idApiario: monitoreo.idApiario,
              fecha: monitoreo.fecha,
              respuestas: monitoreo.respuestas,
              datosAdicionales: monitoreo.datosAdicionales,
              sincronizado: true,
            );

            await _localStorage.updateMonitoreo(syncedMonitoreo);
          }
        } catch (e) {
          print('Error al sincronizar monitoreo ${monitoreo.id}: $e');
        }
      }
    } catch (e) {
      print('Error en sincronización: $e');
    }
  }

  // Verificar conectividad
  Future<bool> checkConnectivity() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'), headers: await _headers)
          .timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Obtener estadísticas del sistema
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/stats'), headers: await _headers)
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      // Retornar estadísticas locales básicas
      final monitoreos = await _localStorage.getMonitoreos();
      return {
        'total_monitoreos': monitoreos.length,
        'monitoreos_ultimo_mes': monitoreos.where((m) {
          final fecha = DateTime.parse(m.fecha);
          final ahora = DateTime.now();
          return ahora.difference(fecha).inDays <= 30;
        }).length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
