import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sotfbee/features/admin/monitoring/models/model.dart';
import 'package:sotfbee/features/auth/data/models/user_model.dart';
import 'package:sotfbee/features/admin/inventory/models/inventory_item.dart';
import 'package:sotfbee/core/network/connectivity_service.dart';
import 'package:sotfbee/features/admin/monitoring/services/local_db_service.dart';

class ApiService {
  static final ConnectivityService _connectivityService = ConnectivityService();
  static final LocalDBService _localDBService = LocalDBService();
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
  static Future<UserProfile?> obtenerPerfil() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/users/me'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(response.body));
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
            Uri.parse('$_baseUrl/login'),
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
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
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
            final List<Apiario> apiarios = data.map((json) => Apiario.fromJson(json)).toList();
            // Guardar en la base de datos local
            for (var apiario in apiarios) {
              await _localDBService.insertApiario(apiario.copyWith(sincronizado: true));
            }
            return apiarios;
          } else if (response.statusCode == 404) {
            return []; // Retorna lista vacía si no hay apiarios
          } else if (response.statusCode == 401) {
            clearAuthToken();
            throw Exception('Sesión expirada');
          } else {
            throw Exception('Error al obtener apiarios: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error de red al obtener apiarios, intentando desde la base de datos local: $e');
          // Fallback a la base de datos local si hay un error de red
          return await _localDBService.getApiarios();
        }
      } else {
        debugPrint('Sin conexión, obteniendo apiarios desde la base de datos local.');
        return await _localDBService.getApiarios();
      }
    } catch (e) {
      debugPrint('Error en obtenerApiarios (general): $e');
      throw Exception('Error al obtener apiarios: $e');
    }
  }

 static Future<int> crearApiario(Map<String, dynamic> data) async {
    try {
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
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
              'user_id': user.id, // Asegurar que se envía el user_id
              'location': data['location'],
            }),
          );

          if (response.statusCode == 201) {
            final int apiarioId = json.decode(response.body)['id'];
            final Apiario apiario = Apiario(
              id: apiarioId,
              nombre: data['name'],
              ubicacion: data['location'],
              userId: user.id,
              fechaCreacion: DateTime.now(),
              fechaActualizacion: DateTime.now(),
              sincronizado: true,
            );
            await _localDBService.insertApiario(apiario);
            return apiarioId;
          } else {
            throw Exception('Error: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          debugPrint('Error de red al crear apiario, guardando localmente: $e');
          // Guardar localmente si hay un error de red
          final Apiario apiario = Apiario(
            id: DateTime.now().millisecondsSinceEpoch, // ID temporal
            nombre: data['name'],
            ubicacion: data['location'],
            userId: (await obtenerPerfil())?.id, // Puede ser null si no hay perfil
            fechaCreacion: DateTime.now(),
            fechaActualizacion: DateTime.now(),
            sincronizado: false,
          );
          return await _localDBService.insertApiario(apiario);
        }
      } else {
        debugPrint('Sin conexión, guardando apiario localmente.');
        final Apiario apiario = Apiario(
          id: DateTime.now().millisecondsSinceEpoch, // ID temporal
          nombre: data['name'],
          ubicacion: data['location'],
          userId: (await obtenerPerfil())?.id, // Puede ser null si no hay perfil
          fechaCreacion: DateTime.now(),
          fechaActualizacion: DateTime.now(),
          sincronizado: false,
        );
        return await _localDBService.insertApiario(apiario);
      }
    } catch (e) {
      debugPrint('Error en crearApiario (general): $e');
      throw Exception('Error al crear apiario: $e');
    }
  }

  static Future<Apiario?> obtenerApiario(int id) async {
    try {
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
        try {
          final response = await http
              .get(Uri.parse('$_baseUrl/apiaries/$id'), headers: _headers)
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final Apiario apiario = Apiario.fromJson(json.decode(response.body));
            await _localDBService.insertApiario(apiario.copyWith(sincronizado: true));
            return apiario;
          } else if (response.statusCode == 404) {
            return null;
          } else {
            throw Exception('Error al obtener apiario: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error de red al obtener apiario, intentando desde la base de datos local: $e');
          return await _localDBService.getApiarioById(id);
        }
      } else {
        debugPrint('Sin conexión, obteniendo apiario desde la base de datos local.');
        return await _localDBService.getApiarioById(id);
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
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
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
          // Actualizar en la base de datos local
          final Apiario apiario = Apiario.fromJson({
            'id': id,
            'nombre': data['name'],
            'ubicacion': data['location'],
            'sincronizado': true,
          });
          await _localDBService.updateApiario(apiario);
        } catch (e) {
          debugPrint('Error de red al actualizar apiario, guardando localmente: $e');
          // Guardar localmente si hay un error de red
          final Apiario apiario = Apiario.fromJson({
            'id': id,
            'name': data['name'],
            'location': data['location'],
            'sincronizado': false,
          });
          await _localDBService.updateApiario(apiario);
        }
      } else {
        debugPrint('Sin conexión, guardando actualización de apiario localmente.');
        final Apiario apiario = Apiario.fromJson({
          'id': id,
          'name': data['name'],
          'location': data['location'],
          'sincronizado': false,
        });
        await _localDBService.updateApiario(apiario);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> eliminarApiario(int id) async {
    try {
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
        try {
          final response = await http
              .delete(Uri.parse('$_baseUrl/apiaries/$id'), headers: _headers)
              .timeout(_timeout);

          if (response.statusCode != 200) {
            throw Exception('Error al eliminar apiario: ${response.statusCode}');
          }
          // Eliminar de la base de datos local
          await _localDBService.deleteApiario(id);
        } catch (e) {
          debugPrint('Error de red al eliminar apiario, marcando para eliminación local: $e');
          // Marcar para eliminación local si hay un error de red
          // En este caso, no hay un campo 'eliminado' en Apiario, así que simplemente lo eliminamos localmente
          // y asumimos que se sincronizará en el próximo intento.
          await _localDBService.deleteApiario(id);
        }
      } else {
        debugPrint('Sin conexión, eliminando apiario localmente.');
        await _localDBService.deleteApiario(id);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== COLMENAS ====================
  static Future<List<Colmena>> obtenerColmenas(int apiarioId) async {
    try {
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
        try {
          final response = await http
              .get(
                Uri.parse('$_baseUrl/apiaries/$apiarioId/hives'),
                headers: _headers,
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            final List<Colmena> colmenas = data.map((json) => Colmena.fromJson(json)).toList();
            // Guardar en la base de datos local
            for (var colmena in colmenas) {
              await _localDBService.insertColmena(colmena.copyWith(sincronizado: true));
            }
            return colmenas;
          } else {
            throw Exception('Error al obtener colmenas: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error de red al obtener colmenas, intentando desde la base de datos local: $e');
          // Fallback a la base de datos local si hay un error de red
          return await _localDBService.getColmenasByApiario(apiarioId);
        }
      } else {
        debugPrint('Sin conexión, obteniendo colmenas desde la base de datos local.');
        return await _localDBService.getColmenasByApiario(apiarioId);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<int> crearColmena(int apiarioId, Map<String, dynamic> data) async {
    try {
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
        try {
          final response = await http
              .post(
                Uri.parse('$_baseUrl/apiaries/$apiarioId/hives'),
                headers: _headers,
                body: json.encode(data),
              )
              .timeout(_timeout);

          if (response.statusCode == 201) {
            final result = json.decode(response.body);
            final int colmenaId = result['id'] ?? -1;
            final Colmena colmena = Colmena(
              id: colmenaId,
              numeroColmena: data['numero_colmena'],
              idApiario: apiarioId,
              activa: data['activa'] ?? true,
              fechaCreacion: DateTime.now(),
              fechaUltimaInspeccion: DateTime.now(),
              estadoReina: data['estado_reina'],
              sincronizado: true,
            );
            await _localDBService.insertColmena(colmena);
            return colmenaId;
          } else {
            throw Exception('Error al crear colmena: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error de red al crear colmena, guardando localmente: $e');
          // Guardar localmente si hay un error de red
          final Colmena colmena = Colmena(
            id: DateTime.now().millisecondsSinceEpoch, // ID temporal
            numeroColmena: data['numero_colmena'],
            idApiario: apiarioId,
            activa: data['activa'] ?? true,
            fechaCreacion: DateTime.now(),
            fechaUltimaInspeccion: DateTime.now(),
            estadoReina: data['estado_reina'],
            sincronizado: false,
          );
          return await _localDBService.insertColmena(colmena);
        }
      } else {
        debugPrint('Sin conexión, guardando colmena localmente.');
        final Colmena colmena = Colmena(
          id: DateTime.now().millisecondsSinceEpoch, // ID temporal
          numeroColmena: data['numero_colmena'],
          idApiario: apiarioId,
          activa: data['activa'] ?? true,
          fechaCreacion: DateTime.now(),
          fechaUltimaInspeccion: DateTime.now(),
          estadoReina: data['estado_reina'],
          sincronizado: false,
        );
        return await _localDBService.insertColmena(colmena);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==================== SINCRONIZACION ====================
  static Future<void> syncPendingItems() async {
    debugPrint('Iniciando sincronización de elementos pendientes...');
    final bool isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      debugPrint('No hay conexión a internet, omitiendo sincronización.');
      return;
    }

    // Sincronizar apiarios pendientes
    final List<Apiario> pendingApiarios = await _localDBService.getPendingApiarios();
    for (var apiario in pendingApiarios) {
      try {
        if (apiario.id == null || apiario.id == 0) { // Nuevo apiario
          final response = await http.post(
            Uri.parse('$_baseUrl/apiaries'),
            headers: _headers,
            body: json.encode({
              'name': apiario.nombre,
              'user_id': apiario.userId,
              'location': apiario.ubicacion,
            }),
          ).timeout(_timeout);

          if (response.statusCode == 201) {
            final newId = json.decode(response.body)['id'];
            await _localDBService.updateApiario(apiario.copyWith(id: newId, sincronizado: true));
            debugPrint('Apiario ${apiario.nombre} sincronizado y actualizado con nuevo ID: $newId');
          } else {
            debugPrint('Error al sincronizar apiario ${apiario.nombre}: ${response.statusCode} - ${response.body}');
          }
        } else { // Apiario existente (actualización)
          final response = await http.put(
            Uri.parse('$_baseUrl/apiaries/${apiario.id}'),
            headers: _headers,
            body: json.encode({
              'name': apiario.nombre,
              'location': apiario.ubicacion,
            }),
          ).timeout(_timeout);

          if (response.statusCode == 200) {
            await _localDBService.updateApiario(apiario.copyWith(sincronizado: true));
            debugPrint('Apiario ${apiario.nombre} actualizado y sincronizado.');
          } else {
            debugPrint('Error al sincronizar actualización de apiario ${apiario.nombre}: ${response.statusCode} - ${response.body}');
          }
        }
      } catch (e) {
        debugPrint('Excepción al sincronizar apiario ${apiario.nombre}: $e');
      }
    }

    // Sincronizar colmenas pendientes
    final List<Colmena> pendingColmenas = await _localDBService.getPendingColmenas();
    for (var colmena in pendingColmenas) {
      try {
        if (colmena.id == null || colmena.id == 0) { // Nueva colmena
          final response = await http.post(
            Uri.parse('$_baseUrl/apiaries/${colmena.idApiario}/hives'),
            headers: _headers,
            body: json.encode({
              'numero_colmena': colmena.numeroColmena,
              'estado_reina': colmena.estadoReina,
              'activa': colmena.activa,
            }),
          ).timeout(_timeout);

          if (response.statusCode == 201) {
            final newId = json.decode(response.body)['id'];
            await _localDBService.updateColmena(colmena.copyWith(id: newId, sincronizado: true));
            debugPrint('Colmena ${colmena.numeroColmena} sincronizada y actualizada con nuevo ID: $newId');
          } else {
            debugPrint('Error al sincronizar colmena ${colmena.numeroColmena}: ${response.statusCode} - ${response.body}');
          }
        } else { // Colmena existente (actualización)
          // No hay un endpoint PUT para colmenas en el backend, se asume que se actualiza a través de la creación
          // o que las actualizaciones se manejan de otra forma. Por ahora, solo se marca como sincronizada.
          await _localDBService.updateColmena(colmena.copyWith(sincronizado: true));
          debugPrint('Colmena ${colmena.numeroColmena} marcada como sincronizada (no hay endpoint PUT).');
        }
      } catch (e) {
        debugPrint('Excepción al sincronizar colmena ${colmena.numeroColmena}: $e');
      }
    }

    // Sincronizar monitoreos pendientes
    final List<Map<String, dynamic>> pendingMonitoreos = await _localDBService.getMonitoreosPendientes();
    for (var monitoreo in pendingMonitoreos) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/monitoreos'),
          headers: _headers,
          body: json.encode({
            'colmena_id': monitoreo['colmena_id'],
            'apiario_id': monitoreo['apiario_id'],
            'fecha': monitoreo['fecha'],
            'respuestas': monitoreo['respuestas'],
          }),
        ).timeout(_timeout);

        if (response.statusCode == 201) {
          await _localDBService.markMonitoreoSincronizado(monitoreo['id']);
          debugPrint('Monitoreo ${monitoreo['id']} sincronizado.');
        } else {
          debugPrint('Error al sincronizar monitoreo ${monitoreo['id']}: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        debugPrint('Excepción al sincronizar monitoreo ${monitoreo['id']}: $e');
      }
    }

    // Sincronizar inventario pendiente
    final List<InventoryItem> pendingInventoryItems = await _localDBService.getPendingInventoryItems();
    for (var item in pendingInventoryItems) {
      try {
        if (item.id == null || item.id == 0) { // Nuevo item
          final response = await http.post(
            Uri.parse('$_baseUrl/inventory'),
            headers: _headers,
            body: json.encode(item.toCreateJson()),
          ).timeout(_timeout);

          if (response.statusCode == 201) {
            final newId = json.decode(response.body)['id'];
            await _localDBService.markInventoryItemAsSynced(item.id); // Marcar el item original como sincronizado
            // Opcional: insertar el item con el nuevo ID si es necesario para futuras operaciones
            // await _localDBService.insertInventoryItem(item.copyWith(id: newId, sincronizado: true));
            debugPrint('Item de inventario ${item.itemName} sincronizado y actualizado con nuevo ID: $newId');
          } else {
            debugPrint('Error al sincronizar item de inventario ${item.itemName}: ${response.statusCode} - ${response.body}');
          }
        } else { // Item existente (actualización)
          final response = await http.put(
            Uri.parse('$_baseUrl/inventory/${item.id}'),
            headers: _headers,
            body: json.encode(item.toUpdateJson()),
          ).timeout(_timeout);

          if (response.statusCode == 200) {
            await _localDBService.markInventoryItemAsSynced(item.id);
            debugPrint('Item de inventario ${item.itemName} actualizado y sincronizado.');
          } else {
            debugPrint('Error al sincronizar actualización de item de inventario ${item.itemName}: ${response.statusCode} - ${response.body}');
          }
        }
      } catch (e) {
        debugPrint('Excepción al sincronizar item de inventario ${item.itemName}: $e');
      }
    }

    debugPrint('Sincronización de elementos pendientes finalizada.');
  }

  // ==================== PREGUNTAS ====================
  static Future<List<Pregunta>> obtenerPreguntasApiario(
    int apiarioId, {
    bool soloActivas = true,
  }) async {
    try {
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
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
            final List<Pregunta> preguntas = data.map((json) => Pregunta.fromJson(json)).toList();
            // Guardar en la base de datos local
            for (var pregunta in preguntas) {
              await _localDBService.savePregunta(pregunta.copyWith(sincronizado: true));
            }
            return preguntas;
          } else {
            throw Exception('Error al obtener preguntas: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error de red al obtener preguntas, intentando desde la base de datos local: $e');
          // Fallback a la base de datos local si hay un error de red
          return await _localDBService.getPreguntasByApiario(apiarioId);
        }
      } else {
        debugPrint('Sin conexión, obteniendo preguntas desde la base de datos local.');
        return await _localDBService.getPreguntasByApiario(apiarioId);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<String> crearPregunta(Pregunta pregunta) async {
    try {
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
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
            final String preguntaId = result['id'] ?? '';
            await _localDBService.savePregunta(pregunta.copyWith(id: preguntaId, sincronizado: true));
            return preguntaId;
          } else {
            throw Exception('Error al crear pregunta: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error de red al crear pregunta, guardando localmente: $e');
          // Guardar localmente si hay un error de red
          final String tempId = DateTime.now().millisecondsSinceEpoch.toString();
          await _localDBService.savePregunta(pregunta.copyWith(id: tempId, sincronizado: false));
          return tempId;
        }
      } else {
        debugPrint('Sin conexión, guardando pregunta localmente.');
        final String tempId = DateTime.now().millisecondsSinceEpoch.toString();
        await _localDBService.savePregunta(pregunta.copyWith(id: tempId, sincronizado: false));
        return tempId;
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
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
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
          // Actualizar en la base de datos local
          final Pregunta pregunta = Pregunta.fromJson({
            'id': preguntaId,
            'texto': data['texto'],
            'tipo_respuesta': data['tipo_respuesta'],
            'seleccionada': data['seleccionada'],
            'orden': data['orden'],
            'activa': data['activa'],
            'obligatoria': data['obligatoria'],
            'apiario_id': data['apiario_id'],
            'fecha_creacion': data['fecha_creacion'],
            'sincronizado': true,
          });
          await _localDBService.savePregunta(pregunta);
        } catch (e) {
          debugPrint('Error de red al actualizar pregunta, guardando localmente: $e');
          // Guardar localmente si hay un error de red
          final Pregunta pregunta = Pregunta.fromJson({
            'id': preguntaId,
            'texto': data['texto'],
            'tipo_respuesta': data['tipo_respuesta'],
            'seleccionada': data['seleccionada'],
            'orden': data['orden'],
            'activa': data['activa'],
            'obligatoria': data['obligatoria'],
            'apiario_id': data['apiario_id'],
            'fecha_creacion': data['fecha_creacion'],
            'sincronizado': false,
          });
          await _localDBService.savePregunta(pregunta);
        }
      } else {
        debugPrint('Sin conexión, guardando actualización de pregunta localmente.');
        final Pregunta pregunta = Pregunta.fromJson({
          'id': preguntaId,
          'texto': data['texto'],
          'tipo_respuesta': data['tipo_respuesta'],
          'seleccionada': data['seleccionada'],
          'orden': data['orden'],
          'activa': data['activa'],
          'obligatoria': data['obligatoria'],
          'apiario_id': data['apiario_id'],
          'fecha_creacion': data['fecha_creacion'],
          'sincronizado': false,
        });
        await _localDBService.savePregunta(pregunta);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> eliminarPregunta(String preguntaId) async {
    try {
      final bool isConnected = await _connectivityService.isConnected();
      if (isConnected) {
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
          // Eliminar de la base de datos local
          await _localDBService.deletePregunta(preguntaId);
        } catch (e) {
          debugPrint('Error de red al eliminar pregunta, eliminando localmente: $e');
          // Eliminar localmente si hay un error de red
          await _localDBService.deletePregunta(preguntaId);
        }
      } else {
        debugPrint('Sin conexión, eliminando pregunta localmente.');
        await _localDBService.deletePregunta(preguntaId);
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
  /*
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
  */

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
