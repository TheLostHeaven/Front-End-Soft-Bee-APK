class ApiConfig {
  // Cambia esta URL por la de tu servidor Flask
  static const String baseUrl =
    'https://softbee-back-end.onrender.com/api';
      // 'https://softbee-back-end.onrender.com/api'; // Para desarrollo local
  // static const String baseUrl = 'http://10.0.2.2:5000'; // Para emulador Android
  // static const String baseUrl = 'https://tu-servidor.com'; // Para producción

  static const int defaultApiaryId = 1; // ID del apiario por defecto

  // Headers comunes
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
