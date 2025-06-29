import 'dart:convert';

class Opcion {
  String valor;
  String? descripcion;
  int? orden;

  Opcion({required this.valor, this.descripcion, this.orden});

  Map<String, dynamic> toJson() {
    return {'valor': valor, 'descripcion': descripcion, 'orden': orden};
  }

  factory Opcion.fromJson(Map<String, dynamic> json) {
    return Opcion(
      valor: json['valor'] ?? json['value'] ?? '',
      descripcion: json['descripcion'] ?? json['description'],
      orden: json['orden'] ?? json['order'],
    );
  }

  Opcion copyWith({String? valor, String? descripcion, int? orden}) {
    return Opcion(
      valor: valor ?? this.valor,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
    );
  }
}

class Pregunta {
  String id;
  String texto;
  bool seleccionada;
  List<Opcion>? opciones;
  String? tipoRespuesta;
  String? respuestaSeleccionada;
  bool obligatoria;
  int? min;
  int? max;
  String? dependeDe;
  int orden;
  bool activa;
  int? apiarioId;
  DateTime? fechaCreacion;
  DateTime? fechaActualizacion;

  Pregunta({
    required this.id,
    required this.texto,
    required this.seleccionada,
    this.tipoRespuesta = "texto",
    this.opciones,
    this.respuestaSeleccionada,
    this.obligatoria = false,
    this.min,
    this.max,
    this.dependeDe,
    this.orden = 0,
    this.activa = true,
    this.apiarioId,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory Pregunta.fromJson(Map<String, dynamic> json) {
    return Pregunta(
      id: json['id'] ?? json['question_id'] ?? '',
      texto: json['pregunta'] ?? json['question_text'] ?? json['texto'] ?? '',
      seleccionada: json['seleccionada'] ?? false,
      tipoRespuesta:
          json['tipo'] ??
          json['question_type'] ??
          json['tipoRespuesta'] ??
          'texto',
      obligatoria: json['obligatoria'] ?? json['is_required'] ?? false,
      opciones: json['opciones'] != null || json['options'] != null
          ? ((json['opciones'] ?? json['options']) as List?)
                ?.map(
                  (o) => o is String ? Opcion(valor: o) : Opcion.fromJson(o),
                )
                .toList()
          : null,
      min: json['min'] ?? json['min_value'],
      max: json['max'] ?? json['max_value'],
      dependeDe: json['depende_de'] ?? json['depends_on'] ?? json['dependeDe'],
      orden: json['orden'] ?? json['display_order'] ?? 0,
      activa: json['activa'] ?? json['is_active'] ?? true,
      apiarioId: json['apiario_id'] ?? json['apiary_id'],
      fechaCreacion: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      fechaActualizacion: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': texto,
      'question_type': tipoRespuesta,
      'is_required': obligatoria,
      'options': opciones?.map((o) => o.toJson()).toList(),
      'min_value': min,
      'max_value': max,
      'depends_on': dependeDe,
      'seleccionada': seleccionada,
      'display_order': orden,
      'is_active': activa,
      'apiary_id': apiarioId,
    };
  }

  Pregunta copyWith({
    String? id,
    String? texto,
    bool? seleccionada,
    List<Opcion>? opciones,
    String? tipoRespuesta,
    String? respuestaSeleccionada,
    bool? obligatoria,
    int? min,
    int? max,
    String? dependeDe,
    int? orden,
    bool? activa,
    int? apiarioId,
  }) {
    return Pregunta(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      seleccionada: seleccionada ?? this.seleccionada,
      opciones: opciones ?? this.opciones,
      tipoRespuesta: tipoRespuesta ?? this.tipoRespuesta,
      respuestaSeleccionada:
          respuestaSeleccionada ?? this.respuestaSeleccionada,
      obligatoria: obligatoria ?? this.obligatoria,
      min: min ?? this.min,
      max: max ?? this.max,
      dependeDe: dependeDe ?? this.dependeDe,
      orden: orden ?? this.orden,
      activa: activa ?? this.activa,
      apiarioId: apiarioId ?? this.apiarioId,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: DateTime.now(),
    );
  }
}

class Apiario {
  final int id;
  final String nombre;
  final String ubicacion;
  final int? userId;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final List<Colmena>? colmenas;
  final List<Pregunta>? preguntas;
  final Map<String, dynamic>? metadatos;

  Apiario({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    this.userId,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.colmenas,
    this.preguntas,
    this.metadatos,
  });

  factory Apiario.fromJson(Map<String, dynamic> json) {
    return Apiario(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? json['name'] ?? '',
      ubicacion: json['ubicacion'] ?? json['location'] ?? '',
      userId: json['user_id'],
      fechaCreacion: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      fechaActualizacion: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      colmenas: json['colmenas'] != null
          ? (json['colmenas'] as List).map((c) => Colmena.fromJson(c)).toList()
          : null,
      preguntas: json['preguntas'] != null
          ? (json['preguntas'] as List)
                .map((p) => Pregunta.fromJson(p))
                .toList()
          : null,
      metadatos: json['metadatos'] ?? json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nombre,
      'location': ubicacion,
      'user_id': userId,
      'metadata': metadatos,
    };
  }

  Apiario copyWith({
    int? id,
    String? nombre,
    String? ubicacion,
    int? userId,
    List<Colmena>? colmenas,
    List<Pregunta>? preguntas,
    Map<String, dynamic>? metadatos,
  }) {
    return Apiario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      userId: userId ?? this.userId,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: DateTime.now(),
      colmenas: colmenas ?? this.colmenas,
      preguntas: preguntas ?? this.preguntas,
      metadatos: metadatos ?? this.metadatos,
    );
  }
}

class Colmena {
  final int id;
  final int numeroColmena;
  final int idApiario;
  final Map<String, dynamic>? metadatos;
  final DateTime? fechaCreacion;

  Colmena({
    required this.id,
    required this.numeroColmena,
    required this.idApiario,
    this.metadatos,
    this.fechaCreacion,
  });

  factory Colmena.fromJson(Map<String, dynamic> json) {
    return Colmena(
      id: json['id'] ?? 0,
      numeroColmena: json['numero_colmena'] ?? json['hive_number'] ?? 0,
      idApiario: json['id_apiario'] ?? json['apiary_id'] ?? 0,
      metadatos: json['metadatos'] ?? json['metadata'],
      fechaCreacion: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hive_number': numeroColmena,
      'apiary_id': idApiario,
      'metadata': metadatos,
    };
  }
}

class NotificacionReina {
  final int id;
  final int apiarioId;
  final int? colmenaId;
  final String tipo;
  final String titulo;
  final String mensaje;
  final String prioridad;
  final bool leida;
  final DateTime fechaCreacion;
  final DateTime? fechaVencimiento;
  final Map<String, dynamic>? metadatos;

  NotificacionReina({
    required this.id,
    required this.apiarioId,
    this.colmenaId,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.prioridad = 'media',
    this.leida = false,
    required this.fechaCreacion,
    this.fechaVencimiento,
    this.metadatos,
  });

  factory NotificacionReina.fromJson(Map<String, dynamic> json) {
    return NotificacionReina(
      id: json['id'] ?? 0,
      apiarioId: json['apiario_id'] ?? json['apiary_id'] ?? 0,
      colmenaId: json['colmena_id'] ?? json['hive_id'],
      tipo: json['tipo'] ?? json['type'] ?? '',
      titulo: json['titulo'] ?? json['title'] ?? '',
      mensaje: json['mensaje'] ?? json['message'] ?? '',
      prioridad: json['prioridad'] ?? json['priority'] ?? 'media',
      leida: json['leida'] ?? json['read'] ?? false,
      fechaCreacion: DateTime.parse(
        json['fecha_creacion'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
      fechaVencimiento:
          json['fecha_vencimiento'] != null || json['expires_at'] != null
          ? DateTime.tryParse(json['fecha_vencimiento'] ?? json['expires_at'])
          : null,
      metadatos: json['metadatos'] ?? json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apiario_id': apiarioId,
      'colmena_id': colmenaId,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'prioridad': prioridad,
      'leida': leida,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
      'metadatos': metadatos,
    };
  }
}

class Usuario {
  final int id;
  final String nombre;
  final String username;
  final String email;
  final String phone;
  final String? profilePicture;
  final DateTime? fechaCreacion;

  Usuario({
    required this.id,
    required this.nombre,
    required this.username,
    required this.email,
    required this.phone,
    this.profilePicture,
    this.fechaCreacion,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profilePicture: json['profile_picture'] ?? json['profile_picture_url'],
      fechaCreacion: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'username': username,
      'email': email,
      'phone': phone,
      'profile_picture': profilePicture,
    };
  }
}

class MonitoreoRespuesta {
  final String preguntaId;
  final String preguntaTexto;
  final dynamic respuesta;
  final String? tipoRespuesta;
  final DateTime? fechaRespuesta;

  MonitoreoRespuesta({
    required this.preguntaId,
    required this.preguntaTexto,
    required this.respuesta,
    this.tipoRespuesta,
    this.fechaRespuesta,
  });

  Map<String, dynamic> toJson() {
    return {
      'pregunta_id': preguntaId,
      'pregunta_texto': preguntaTexto,
      'respuesta': respuesta,
      'tipo_respuesta': tipoRespuesta,
      'fecha_respuesta': fechaRespuesta?.toIso8601String(),
    };
  }

  factory MonitoreoRespuesta.fromJson(Map<String, dynamic> json) {
    return MonitoreoRespuesta(
      preguntaId: json['pregunta_id'] ?? '',
      preguntaTexto: json['pregunta_texto'] ?? '',
      respuesta: json['respuesta'],
      tipoRespuesta: json['tipo_respuesta'],
      fechaRespuesta: json['fecha_respuesta'] != null
          ? DateTime.tryParse(json['fecha_respuesta'])
          : null,
    );
  }
}
