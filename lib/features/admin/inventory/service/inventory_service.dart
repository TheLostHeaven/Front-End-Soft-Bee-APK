import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/inventory_item.dart';
import 'api_config.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  // Obtener todos los items del inventario por apiario
  Future<List<InventoryItem>> getInventoryItems({int? apiaryId}) async {
    try {
      final int targetApiaryId = apiaryId ?? ApiConfig.defaultApiaryId;
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/apiaries/$targetApiaryId/inventory',
            ),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => InventoryItem.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener inventario: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } on HttpException {
      throw Exception('Error HTTP. El servidor no está disponible.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Crear un nuevo item en un apiario
  Future<int> createInventoryItem(InventoryItem item) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/apiaries/${item.apiaryId}/inventory'),
            headers: ApiConfig.headers,
            body: json.encode(item.toCreateJson()),
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['id'];
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear item');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } catch (e) {
      throw Exception('Error al crear item: $e');
    }
  }

  // Actualizar un item existente
  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/inventory/${item.id}'),
            headers: ApiConfig.headers,
            body: json.encode(item.toUpdateJson()),
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al actualizar item');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } catch (e) {
      throw Exception('Error al actualizar item: $e');
    }
  }

  // Eliminar un item
  Future<void> deleteInventoryItem(int itemId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/inventory/$itemId'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar item');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } catch (e) {
      throw Exception('Error al eliminar item: $e');
    }
  }

  // Ajustar cantidad de un item
  Future<void> adjustInventoryQuantity(int itemId, int amount) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/inventory/$itemId/adjust'),
            headers: ApiConfig.headers,
            body: json.encode({'amount': amount}),
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error al ajustar cantidad');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } catch (e) {
      throw Exception('Error al ajustar cantidad: $e');
    }
  }

  // Buscar items por nombre
  Future<List<InventoryItem>> searchInventoryItems(
    String query, {
    int? apiaryId,
  }) async {
    try {
      final int targetApiaryId = apiaryId ?? ApiConfig.defaultApiaryId;
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/inventory/search?query=${Uri.encodeComponent(query)}',
            ),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => InventoryItem.fromJson(json)).toList();
      } else {
        throw Exception('Error en búsqueda: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } catch (e) {
      throw Exception('Error en búsqueda: $e');
    }
  }

  // Obtener un item específico por ID
  Future<InventoryItem?> getInventoryItem(int itemId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/inventory/$itemId'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        return InventoryItem.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener item: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu conexión a internet.');
    } catch (e) {
      throw Exception('Error al obtener item: $e');
    }
  }

  // Registrar salida de inventario
  Future<void> recordInventoryExit({
    required int itemId,
    required int quantity,
    required String person,
  }) async {
    try {
      // Primero ajustamos la cantidad en el inventario
      await adjustInventoryQuantity(itemId, -quantity);

      // Aquí podrías agregar lógica adicional para registrar la salida
      // en una tabla separada si tu backend lo soporta
    } catch (e) {
      throw Exception('Error al registrar salida: $e');
    }
  }
}
