import 'dart:convert';

// Modelo para Apiario
class Apiario {
  final int id;
  final int userId;
  final String name;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  List<Colmena>? colmenas;
  List<Monitoreo>? monitoreos;

  Apiario({
    required this.id,
    required this.userId,
    required this.name,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.colmenas,
    this.monitoreos,
  });

  factory Apiario.fromJson(Map<String, dynamic> json) {
    return Apiario(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      location: json['location'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Modelo para Colmena
class Colmena {
  final int id;
  final int apiarioId;
  final String numeroColmena;
  final String? estado;
  final DateTime? ultimaInspeccion;
  final double? productividad;
  final String? notas;

  Colmena({
    required this.id,
    required this.apiarioId,
    required this.numeroColmena,
    this.estado,
    this.ultimaInspeccion,
    this.productividad,
    this.notas,
  });

  factory Colmena.fromJson(Map<String, dynamic> json) {
    return Colmena(
      id: json['id'],
      apiarioId: json['apiario_id'],
      numeroColmena: json['numero_colmena'],
      estado: json['estado'],
      ultimaInspeccion: json['ultima_inspeccion'] != null
          ? DateTime.parse(json['ultima_inspeccion'])
          : null,
      productividad: json['productividad']?.toDouble(),
      notas: json['notas'],
    );
  }
}

// Modelo para Monitoreo
class Monitoreo {
  final int id;
  final int idColmena;
  final int idApiario;
  final DateTime fecha;
  final List<RespuestaMonitoreo> respuestas;
  final Map<String, dynamic>? datosAdicionales;
  final bool sincronizado;
  final String? apiarioNombre;
  final String? numeroColmena;

  Monitoreo({
    required this.id,
    required this.idColmena,
    required this.idApiario,
    required this.fecha,
    required this.respuestas,
    this.datosAdicionales,
    required this.sincronizado,
    this.apiarioNombre,
    this.numeroColmena,
  });

  factory Monitoreo.fromJson(Map<String, dynamic> json) {
    List<RespuestaMonitoreo> respuestas = [];
    if (json['respuestas'] != null) {
      respuestas = (json['respuestas'] as List)
          .map((r) => RespuestaMonitoreo.fromJson(r))
          .toList();
    }

    return Monitoreo(
      id: json['id'],
      idColmena: json['id_colmena'],
      idApiario: json['id_apiario'],
      fecha: DateTime.parse(json['fecha']),
      respuestas: respuestas,
      datosAdicionales: json['datos_adicionales'],
      sincronizado: json['sincronizado'] == 1,
      apiarioNombre: json['apiario_nombre'],
      numeroColmena: json['numero_colmena'],
    );
  }
}

// Modelo para Respuesta de Monitoreo
class RespuestaMonitoreo {
  final int id;
  final int monitoreoId;
  final String preguntaId;
  final String preguntaTexto;
  final String? respuesta;
  final String tipoRespuesta;

  RespuestaMonitoreo({
    required this.id,
    required this.monitoreoId,
    required this.preguntaId,
    required this.preguntaTexto,
    this.respuesta,
    required this.tipoRespuesta,
  });

  factory RespuestaMonitoreo.fromJson(Map<String, dynamic> json) {
    return RespuestaMonitoreo(
      id: json['id'],
      monitoreoId: json['monitoreo_id'],
      preguntaId: json['pregunta_id'],
      preguntaTexto: json['pregunta_texto'],
      respuesta: json['respuesta'],
      tipoRespuesta: json['tipo_respuesta'],
    );
  }
}

// Modelo para Usuario
class Usuario {
  final int id;
  final String nombre;
  final String username;
  final String email;
  final String phone;
  final String? profilePicture;
  final List<Apiario>? apiarios;

  Usuario({
    required this.id,
    required this.nombre,
    required this.username,
    required this.email,
    required this.phone,
    this.profilePicture,
    this.apiarios,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    List<Apiario>? apiarios;
    if (json['apiaries'] != null) {
      apiarios = (json['apiaries'] as List)
          .map((a) => Apiario.fromJson(a))
          .toList();
    }

    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      profilePicture: json['profile_picture'],
      apiarios: apiarios,
    );
  }
}

// Modelo para Estadísticas del Sistema
class SystemStats {
  final int totalApiarios;
  final int totalColmenas;
  final int totalMonitoreos;
  final int monitoreosUltimoMes;
  final List<MonitoreosPorApiario> monitoreosPorApiario;
  final DateTime timestamp;

  SystemStats({
    required this.totalApiarios,
    required this.totalColmenas,
    required this.totalMonitoreos,
    required this.monitoreosUltimoMes,
    required this.monitoreosPorApiario,
    required this.timestamp,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      totalApiarios: json['total_apiarios'],
      totalColmenas: json['total_colmenas'],
      totalMonitoreos: json['total_monitoreos'],
      monitoreosUltimoMes: json['monitoreos_ultimo_mes'],
      monitoreosPorApiario: (json['monitoreos_por_apiario'] as List)
          .map((m) => MonitoreosPorApiario.fromJson(m))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class MonitoreosPorApiario {
  final String apiario;
  final int total;

  MonitoreosPorApiario({required this.apiario, required this.total});

  factory MonitoreosPorApiario.fromJson(Map<String, dynamic> json) {
    return MonitoreosPorApiario(apiario: json['apiario'], total: json['total']);
  }
}
