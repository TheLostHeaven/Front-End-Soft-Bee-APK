import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sotfbee/features/admin/history/models/monitoreo_models.dart';
import 'package:sotfbee/features/admin/history/service/api_service.dart';
import 'package:sotfbee/features/admin/history/service/local_storage_service.dart';

class MonitoreoController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocalStorageService _localStorage = LocalStorageService();

  List<MonitoreoModel> _monitoreos = [];
  Map<String, dynamic> _systemStats = {};
  bool _isLoading = false;
  bool _isOnline = false;
  String? _error;

  // Getters
  List<MonitoreoModel> get monitoreos => _monitoreos;
  Map<String, dynamic> get systemStats => _systemStats;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get error => _error;

  // Timer para sincronización automática
  Timer? _syncTimer;

  MonitoreoController() {
    _initController();
  }

  Future<void> _initController() async {
    await checkConnectivity();
    await loadMonitoreos();
    await loadSystemStats();

    // Configurar sincronización automática cada 5 minutos
    _syncTimer = Timer.periodic(Duration(minutes: 5), (_) {
      syncData();
    });
  }

  // Verificar conectividad
  Future<void> checkConnectivity() async {
    _isOnline = await _apiService.checkConnectivity();
    notifyListeners();
  }

  // Cargar monitoreos
  Future<void> loadMonitoreos() async {
    _setLoading(true);
    _error = null;

    try {
      _monitoreos = await _apiService.getMonitoreos();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error al cargar monitoreos: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar estadísticas del sistema
  Future<void> loadSystemStats() async {
    try {
      _systemStats = await _apiService.getSystemStats();
      notifyListeners();
    } catch (e) {
      print('Error al cargar estadísticas: $e');
    }
  }

  // Crear nuevo monitoreo
  Future<bool> createMonitoreo(MonitoreoModel monitoreo) async {
    _setLoading(true);
    _error = null;

    try {
      final newMonitoreo = await _apiService.createMonitoreo(monitoreo);
      if (newMonitoreo != null) {
        _monitoreos.insert(0, newMonitoreo);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('Error al crear monitoreo: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Obtener monitoreos por apiario
  Future<List<MonitoreoModel>> getMonitoreosByApiario(int apiarioId) async {
    try {
      return await _apiService.getMonitoreosByApiario(apiarioId);
    } catch (e) {
      print('Error al obtener monitoreos por apiario: $e');
      return [];
    }
  }

  // Sincronizar datos
  Future<void> syncData() async {
    if (!_isOnline) {
      await checkConnectivity();
      if (!_isOnline) return;
    }

    try {
      await _apiService.syncPendingData();
      await loadMonitoreos();
      await loadSystemStats();
      await _localStorage.saveLastSync();
    } catch (e) {
      print('Error en sincronización: $e');
    }
  }

  // Generar datos para gráficas basados en respuestas
  Map<String, List<double>> generateChartData(List<MonitoreoModel> monitoreos) {
    Map<String, List<double>> chartData = {
      'produccion': [],
      'salud': [],
      'poblacion': [],
    };

    for (final monitoreo in monitoreos) {
      final data = monitoreo.generateChartData();

      if (data['produccion'].isNotEmpty) {
        chartData['produccion']!.addAll(List<double>.from(data['produccion']));
      }
      if (data['salud'].isNotEmpty) {
        chartData['salud']!.addAll(List<double>.from(data['salud']));
      }
      if (data['poblacion'].isNotEmpty) {
        chartData['poblacion']!.addAll(List<double>.from(data['poblacion']));
      }
    }

    return chartData;
  }

  // Obtener estadísticas resumidas
  Map<String, dynamic> getResumenStats() {
    final totalInspecciones = _monitoreos.length;
    final inspeccionesRecientes = _monitoreos.where((m) {
      final fecha = DateTime.parse(m.fecha);
      final ahora = DateTime.now();
      return ahora.difference(fecha).inDays <= 30;
    }).length;

    // Calcular colmenas saludables basado en respuestas
    int colmenasSaludables = 0;
    int alertasPendientes = 0;

    for (final monitoreo in _monitoreos) {
      bool esSaludable = true;
      for (final respuesta in monitoreo.respuestas) {
        if (respuesta.preguntaId.toLowerCase().contains('salud') ||
            respuesta.preguntaId.toLowerCase().contains('estado')) {
          if (respuesta.tipoRespuesta == 'option' &&
              (respuesta.respuesta.toLowerCase().contains('malo') ||
                  respuesta.respuesta.toLowerCase().contains('alerta'))) {
            esSaludable = false;
            alertasPendientes++;
            break;
          }
        }
      }
      if (esSaludable) colmenasSaludables++;
    }

    return {
      'total_inspecciones': totalInspecciones,
      'colmenas_saludables': colmenasSaludables,
      'alertas_pendientes': alertasPendientes,
      'inspecciones_recientes': inspeccionesRecientes,
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
