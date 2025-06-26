import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sotfbee/features/admin/history/models/monitoreo_models.dart';

class LocalStorageService {
  static const String _monitoreos_key = 'monitoreos';
  static const String _questions_key = 'questions';
  static const String _last_sync_key = 'last_sync';

  // Guardar monitoreos
  Future<void> saveMonitoreos(List<MonitoreoModel> monitoreos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = monitoreos.map((m) => m.toJson()).toList();
    await prefs.setString(_monitoreos_key, json.encode(jsonList));
  }

  // Obtener monitoreos
  Future<List<MonitoreoModel>> getMonitoreos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_monitoreos_key);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => MonitoreoModel.fromJson(json)).toList();
  }

  // Agregar monitoreo
  Future<void> addMonitoreo(MonitoreoModel monitoreo) async {
    final monitoreos = await getMonitoreos();
    monitoreos.add(monitoreo);
    await saveMonitoreos(monitoreos);
  }

  // Actualizar monitoreo
  Future<void> updateMonitoreo(MonitoreoModel monitoreo) async {
    final monitoreos = await getMonitoreos();
    final index = monitoreos.indexWhere((m) => m.id == monitoreo.id);

    if (index != -1) {
      monitoreos[index] = monitoreo;
      await saveMonitoreos(monitoreos);
    }
  }

  // Obtener monitoreos pendientes de sincronización
  Future<List<MonitoreoModel>> getPendingSync() async {
    final monitoreos = await getMonitoreos();
    return monitoreos.where((m) => !m.sincronizado).toList();
  }

  // Guardar preguntas por apiario
  Future<void> saveQuestions(
    int apiarioId,
    List<QuestionModel> questions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = questions
        .map(
          (q) => {
            'id': q.id,
            'apiary_id': q.apiaryId,
            'question_text': q.questionText,
            'question_type': q.questionType,
            'is_required': q.isRequired,
            'display_order': q.displayOrder,
            'min_value': q.minValue,
            'max_value': q.maxValue,
            'options': q.options,
            'depends_on': q.dependsOn,
            'is_active': q.isActive,
          },
        )
        .toList();

    await prefs.setString(
      '${_questions_key}_$apiarioId',
      json.encode(jsonList),
    );
  }

  // Obtener preguntas por apiario
  Future<List<QuestionModel>> getQuestions(int apiarioId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('${_questions_key}_$apiarioId');

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => QuestionModel.fromJson(json)).toList();
  }

  // Guardar timestamp de última sincronización
  Future<void> saveLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_last_sync_key, DateTime.now().toIso8601String());
  }

  // Obtener timestamp de última sincronización
  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_last_sync_key);

    if (timestamp == null) return null;

    return DateTime.parse(timestamp);
  }

  // Limpiar todos los datos locales
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
