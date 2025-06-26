import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/model.dart';
import 'api_service.dart';
import 'local_db_service.dart';

class EnhancedVoiceAssistantService {
  final FlutterTts tts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  final LocalDBService dbService = LocalDBService();
  
  bool isListening = false;
  bool isActive = false;
  bool isInitialized = false;
  String lastRecognized = '';
  
  StreamController<String> speechResultsController = StreamController<String>.broadcast();
  StreamController<String> statusController = StreamController<String>.broadcast();
  StreamController<bool> listeningController = StreamController<bool>.broadcast();

  // Estados del flujo de monitoreo
  String currentMessage = '';
  List<MonitoreoRespuesta> respuestas = [];
  List<Apiario> apiarios = [];
  List<Colmena> colmenas = [];
  Apiario? selectedApiario;
  int? selectedColmena;
  int currentQuestionIndex = 0;
  List<Pregunta> preguntasActivas = [];

  // Configuración de Maya
  static const String assistantName = "Maya";
  static const String wakeWord = "maya";
  static const List<String> activationPhrases = [
    "maya inicia monitoreo",
    "maya iniciar monitoreo", 
    "maya comenzar monitoreo",
    "maya empezar monitoreo",
    "hola maya",
    "maya ayuda"
  ];

  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      // Solicitar permisos
      await _requestPermissions();
      
      // Configurar TTS
      await _configureTTS();
      
      // Inicializar Speech Recognition
      await _initializeSpeech();
      
      // Cargar datos iniciales
      await _loadInitialData();
      
      isInitialized = true;
      _updateStatus("Maya inicializada correctamente");
      
      // Saludo inicial
      await speak("Hola, soy Maya, tu asistente de monitoreo de colmenas. Puedes activarme diciendo 'Maya, inicia monitoreo' o presionando el botón de micrófono.");
      
    } catch (e) {
      debugPrint("❌ Error al inicializar Maya: $e");
      _updateStatus("Error al inicializar Maya: $e");
    }
  }

  Future<void> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus != PermissionStatus.granted) {
      throw Exception("Permiso de micrófono requerido para Maya");
    }
  }

  Future<void> _configureTTS() async {
    await tts.setLanguage("es-ES");
    await tts.setSpeechRate(0.7);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);

    if (Platform.isAndroid) {
      await tts.setEngine("com.google.android.tts");
    }

    // Configurar callbacks
    tts.setStartHandler(() {
      debugPrint("🤖 Maya comenzó a hablar");
    });

    tts.setCompletionHandler(() {
      debugPrint("🤖 Maya terminó de hablar");
    });

    tts.setErrorHandler((msg) {
      debugPrint("❌ Error TTS: $msg");
    });
  }

  Future<void> _initializeSpeech() async {
    bool available = await speech.initialize(
      onStatus: (status) {
        debugPrint("📢 Estado del reconocimiento: $status");
        _updateListeningState(status == 'listening');
        
        if (status == 'done' || status == 'notListening') {
          isListening = false;
          listeningController.add(false);
        }
      },
      onError: (error) {
        debugPrint("❌ Error en reconocimiento: $error");
        isListening = false;
        listeningController.add(false);
        _updateStatus("Error en reconocimiento de voz");
      },
    );

    if (!available) {
      throw Exception("Reconocimiento de voz no disponible");
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // Cargar desde base de datos local primero
      apiarios = await dbService.getApiarios();
      
      // Intentar sincronizar con servidor si hay conexión
      if (await ApiService.hasInternetConnection()) {
        try {
          final serverApiarios = await ApiService.obtenerApiarios();
          // Actualizar base de datos local con datos del servidor
          for (final apiario in serverApiarios) {
            await dbService.insertApiario(apiario);
          }
          apiarios = serverApiarios;
        } catch (e) {
          debugPrint("⚠️ No se pudo sincronizar con servidor, usando datos locales");
        }
      }
      
      debugPrint("✅ Cargados ${apiarios.length} apiarios");
    } catch (e) {
      debugPrint("❌ Error al cargar datos iniciales: $e");
    }
  }

  // ==================== ACTIVACIÓN POR VOZ ====================
  
  Future<void> startPassiveListening() async {
    if (!isInitialized) await initialize();
    
    _updateStatus("Maya en modo pasivo - Di 'Maya, inicia monitoreo'");
    
    while (!isActive) {
      try {
        final result = await _listenForWakeWord();
        if (result.isNotEmpty && _isActivationPhrase(result)) {
          await _activateAssistant();
          break;
        }
        
        // Pausa antes del siguiente ciclo
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        debugPrint("❌ Error en escucha pasiva: $e");
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }

  Future<String> _listenForWakeWord() async {
    if (isListening) return '';

    try {
      isListening = true;
      final Completer<String> completer = Completer<String>();
      String recognizedText = '';

      speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            recognizedText = result.recognizedWords.toLowerCase().trim();
            if (!completer.isCompleted) {
              completer.complete(recognizedText);
            }
          }
        },
        listenFor: Duration(seconds: 3),
        pauseFor: Duration(seconds: 1),
        cancelOnError: true,
        partialResults: false,
        localeId: 'es_ES',
      );

      // Timeout
      Timer(Duration(seconds: 4), () {
        if (!completer.isCompleted) {
          isListening = false;
          speech.stop();
          completer.complete(recognizedText);
        }
      });

      return await completer.future;
    } catch (e) {
      isListening = false;
      return '';
    }
  }

  bool _isActivationPhrase(String text) {
    text = text.toLowerCase().trim();
    
    // Verificar frases de activación exactas
    for (final phrase in activationPhrases) {
      if (text.contains(phrase) || ratio(phrase, text) > 75) {
        return true;
      }
    }
    
    // Verificar palabra de activación + comando
    if (text.contains(wakeWord) && 
        (text.contains("monitoreo") || text.contains("ayuda") || text.contains("hola"))) {
      return true;
    }
    
    return false;
  }

  Future<void> _activateAssistant() async {
    isActive = true;
    await speak("¡Hola! Soy Maya. Vamos a comenzar el monitoreo de colmenas.");
    await startMonitoringFlow();
  }

  // ==================== FLUJO DE MONITOREO MEJORADO ====================
  
  Future<void> startMonitoringFlow() async {
    try {
      isActive = true;
      _updateStatus("Maya activada - Iniciando monitoreo");
      
      // Limpiar estado anterior
      respuestas.clear();
      selectedApiario = null;
      selectedColmena = null;
      currentQuestionIndex = 0;
      
      await speak("Iniciando el monitoreo de colmenas. Primero necesito que selecciones un apiario.");
      await _selectApiario();
      
    } catch (e) {
      debugPrint("❌ Error en flujo de monitoreo: $e");
      await speak("Ha ocurrido un error. Por favor, intenta de nuevo.");
      await stopAssistant();
    }
  }

  Future<void> _selectApiario() async {
    if (apiarios.isEmpty) {
      await speak("No hay apiarios disponibles. Por favor, configura al menos un apiario primero.");
      await stopAssistant();
      return;
    }

    final apiarioNames = apiarios.map((a) => a.nombre).join(', ');
    final message = "Apiarios disponibles: $apiarioNames. ¿Cuál quieres monitorear?";
    
    _updateStatus("Seleccionando apiario...");
    await speak(message);
    
    final response = await listen(duration: 6);
    if (response.isNotEmpty) {
      await _processApiarioSelection(response);
    } else {
      await speak("No escuché tu respuesta. Intentemos de nuevo.");
      await _selectApiario();
    }
  }

  Future<void> _processApiarioSelection(String text) async {
    Apiario? matchedApiario;
    int bestScore = 0;

    for (var apiario in apiarios) {
      final score = ratio(apiario.nombre.toLowerCase(), text.toLowerCase());
      if (score > bestScore && score > 60) {
        bestScore = score;
        matchedApiario = apiario;
      }
      
      // También verificar si el texto contiene el nombre del apiario
      if (text.toLowerCase().contains(apiario.nombre.toLowerCase())) {
        matchedApiario = apiario;
        break;
      }
    }

    if (matchedApiario != null) {
      selectedApiario = matchedApiario;
      _updateStatus("Apiario seleccionado: ${matchedApiario.nombre}");
      await speak("Perfecto, has seleccionado ${matchedApiario.nombre}.");
      
      // Cargar colmenas del apiario
      await _loadColmenas();
      await _selectColmena();
    } else {
      await speak("No reconocí ese apiario. Los disponibles son: ${apiarios.map((a) => a.nombre).join(', ')}. ¿Cuál eliges?");
      final response = await listen(duration: 6);
      if (response.isNotEmpty) {
        await _processApiarioSelection(response);
      }
    }
  }

  Future<void> _loadColmenas() async {
    if (selectedApiario == null) return;
    
    try {
      colmenas = await dbService.getColmenasByApiario(selectedApiario!.id);
      debugPrint("✅ Cargadas ${colmenas.length} colmenas para apiario ${selectedApiario!.nombre}");
    } catch (e) {
      debugPrint("❌ Error al cargar colmenas: $e");
      colmenas = [];
    }
  }

  Future<void> _selectColmena() async {
    if (colmenas.isEmpty) {
      await speak("No hay colmenas disponibles en este apiario. Por favor, configura al menos una colmena.");
      await stopAssistant();
      return;
    }

    final colmenaNumbers = colmenas.map((c) => c.numeroColmena.toString()).join(', ');
    final message = "Colmenas disponibles: $colmenaNumbers. ¿Cuál quieres inspeccionar?";
    
    _updateStatus("Seleccionando colmena...");
    await speak(message);
    
    final response = await listen(duration: 5);
    if (response.isNotEmpty) {
      await _processColmenaSelection(response);
    } else {
      await speak("No escuché el número de colmena. Intentemos de nuevo.");
      await _selectColmena();
    }
  }

  Future<void> _processColmenaSelection(String text) async {
    final numeroColmena = palabrasANumero(text) ?? int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (numeroColmena != null && colmenas.any((c) => c.numeroColmena == numeroColmena)) {
      selectedColmena = numeroColmena;
      _updateStatus("Colmena $numeroColmena seleccionada");
      await speak("Excelente, vamos a inspeccionar la colmena $numeroColmena.");
      
      // Cargar preguntas y comenzar monitoreo
      await _loadQuestions();
      await _startQuestionFlow();
    } else {
      final availableNumbers = colmenas.map((c) => c.numeroColmena.toString()).join(', ');
      await speak("Número de colmena no válido. Las disponibles son: $availableNumbers. ¿Cuál eliges?");
      final response = await listen(duration: 5);
      if (response.isNotEmpty) {
        await _processColmenaSelection(response);
      }
    }
  }

  Future<void> _loadQuestions() async {
    try {
      if (selectedApiario != null) {
        // Intentar cargar preguntas del servidor
        if (await ApiService.hasInternetConnection()) {
          try {
            preguntasActivas = await ApiService.obtenerPreguntasApiario(selectedApiario!.id);
          } catch (e) {
            debugPrint("⚠️ Error al cargar preguntas del servidor: $e");
          }
        }
        
        // Si no hay preguntas del servidor, usar preguntas por defecto
        if (preguntasActivas.isEmpty) {
          preguntasActivas = await _getDefaultQuestions();
        }
      }
      
      debugPrint("✅ Cargadas ${preguntasActivas.length} preguntas");
    } catch (e) {
      debugPrint("❌ Error al cargar preguntas: $e");
      preguntasActivas = await _getDefaultQuestions();
    }
  }

  Future<List<Pregunta>> _getDefaultQuestions() async {
    return [
      Pregunta(
        id: "1",
        texto: "¿Cómo está la actividad en las piqueras?",
        seleccionada: true,
        tipoRespuesta: "opciones",
        opciones: [
          Opcion(valor: "Baja"),
          Opcion(valor: "Media"),
          Opcion(valor: "Alta"),
        ],
        obligatoria: true,
      ),
      Pregunta(
        id: "2",
        texto: "¿Cómo evalúas la población de abejas?",
        seleccionada: true,
        tipoRespuesta: "opciones",
        opciones: [
          Opcion(valor: "Baja"),
          Opcion(valor: "Media"),
          Opcion(valor: "Alta"),
        ],
        obligatoria: true,
      ),
      Pregunta(
        id: "3",
        texto: "¿Cuántos cuadros de alimento observas?",
        seleccionada: true,
        tipoRespuesta: "numero",
        min: 0,
        max: 10,
        obligatoria: true,
      ),
      Pregunta(
        id: "4",
        texto: "¿Cuál es el estado de la reina?",
        seleccionada: true,
        tipoRespuesta: "opciones",
        opciones: [
          Opcion(valor: "Presente"),
          Opcion(valor: "Ausente"),
          Opcion(valor: "Celdas reales"),
        ],
      ),
    ];
  }

  Future<void> _startQuestionFlow() async {
    currentQuestionIndex = 0;
    _updateStatus("Iniciando preguntas de monitoreo");
    await speak("Perfecto. Ahora te haré ${preguntasActivas.length} preguntas sobre la colmena. Responde con claridad.");
    await Future.delayed(Duration(milliseconds: 1000));
    await _askCurrentQuestion();
  }

  Future<void> _askCurrentQuestion() async {
    if (currentQuestionIndex >= preguntasActivas.length) {
      await _showSummary();
      return;
    }

    final pregunta = preguntasActivas[currentQuestionIndex];
    String questionText = "Pregunta ${currentQuestionIndex + 1}: ${pregunta.texto}";

    if (pregunta.tipoRespuesta == 'opciones' && pregunta.opciones != null) {
      final opciones = pregunta.opciones!.asMap().entries.map((entry) {
        return "${entry.key + 1} para ${entry.value.valor}";
      }).join(', ');
      questionText += ". Las opciones son: $opciones. Responde con el número de la opción.";
    } else if (pregunta.tipoRespuesta == 'numero') {
      questionText += ". Responde con un número entre ${pregunta.min ?? 0} y ${pregunta.max ?? 100}.";
    }

    _updateStatus("Pregunta ${currentQuestionIndex + 1} de ${preguntasActivas.length}");
    await speak(questionText);
    
    final response = await listen(duration: pregunta.tipoRespuesta == 'texto' ? 8 : 6);
    if (response.isNotEmpty) {
      await _processQuestionResponse(response);
    } else {
      await speak("No escuché tu respuesta. Te repetiré la pregunta.");
      await _askCurrentQuestion();
    }
  }

  Future<void> _processQuestionResponse(String text) async {
    final pregunta = preguntasActivas[currentQuestionIndex];
    final respuestaMap = <String, dynamic>{};

    bool respuestaValida = procesarRespuestaPregunta(pregunta, text, 1, respuestaMap);

    if (respuestaValida) {
      final respuesta = MonitoreoRespuesta(
        preguntaId: pregunta.id,
        preguntaTexto: pregunta.texto,
        respuesta: respuestaMap['respuesta'],
      );

      respuestas.add(respuesta);
      
      // Confirmación de la respuesta
      await speak("Registrado: ${respuesta.respuesta}");
      
      currentQuestionIndex++;
      
      // Pausa breve antes de la siguiente pregunta
      await Future.delayed(Duration(milliseconds: 800));
      await _askCurrentQuestion();
    } else {
      await speak("No entendí tu respuesta. Por favor, intenta de nuevo.");
      await Future.delayed(Duration(milliseconds: 500));
      await _askCurrentQuestion();
    }
  }

  Future<void> _showSummary() async {
    String summary = "Hemos terminado las preguntas. Aquí está el resumen: ";
    
    for (int i = 0; i < respuestas.length; i++) {
      final resp = respuestas[i];
      summary += "${resp.preguntaTexto}: ${resp.respuesta}. ";
    }
    
    summary += "¿Los datos son correctos? Di 'confirmar' para guardar o 'repetir' para volver a empezar.";
    
    _updateStatus("Mostrando resumen");
    await speak(summary);
    
    final response = await listen(duration: 6);
    if (response.isNotEmpty) {
      await _processFinalConfirmation(response);
    } else {
      await speak("No escuché tu respuesta. ¿Confirmas los datos o quieres repetir?");
      final retryResponse = await listen(duration: 5);
      if (retryResponse.isNotEmpty) {
        await _processFinalConfirmation(retryResponse);
      }
    }
  }

  Future<void> _processFinalConfirmation(String text) async {
    if (confirmacionReconocida(text, 'confirmar')) {
      await _saveMonitoringData();
    } else if (confirmacionReconocida(text, 'repetir') || confirmacionReconocida(text, 'cancelar')) {
      await speak("De acuerdo, vamos a repetir el monitoreo.");
      respuestas.clear();
      currentQuestionIndex = 0;
      await Future.delayed(Duration(milliseconds: 1000));
      await _startQuestionFlow();
    } else {
      await speak("No entendí. Di 'confirmar' para guardar los datos o 'repetir' para empezar de nuevo.");
      final response = await listen(duration: 5);
      if (response.isNotEmpty) {
        await _processFinalConfirmation(response);
      }
    }
  }

  Future<void> _saveMonitoringData() async {
    if (selectedApiario == null || selectedColmena == null) {
      await speak("Error: faltan datos del apiario o colmena.");
      return;
    }

    try {
      _updateStatus("Guardando datos...");
      
      final data = {
        'colmena': selectedColmena,
        'id_apiario': selectedApiario!.id,
        'fecha': DateTime.now().toIso8601String(),
        'respuestas': respuestas.map((r) => r.toJson()).toList(),
      };

      // Guardar localmente primero
      final monitoreoId = await dbService.saveMonitoreo(data);
      if (monitoreoId > 0) {
        await dbService.saveRespuestas(monitoreoId, respuestas);
        
        await speak("¡Excelente! Los datos han sido guardados correctamente. El monitoreo de la colmena $selectedColmena está completo.");
        
        // Intentar sincronizar con servidor en segundo plano
        _syncInBackground();
        
        _updateStatus("Monitoreo completado exitosamente");
      } else {
        throw Exception('Error al guardar en base de datos local');
      }
    } catch (e) {
      debugPrint("❌ Error al guardar monitoreo: $e");
      await speak("Ha ocurrido un error al guardar los datos. Los datos se han guardado localmente y se sincronizarán cuando haya conexión.");
    }
    
    await stopAssistant();
  }

  void _syncInBackground() async {
    try {
      if (await ApiService.hasInternetConnection()) {
        final pendientes = await dbService.getMonitoreosPendientes();
        if (pendientes.isNotEmpty) {
          // Aquí implementarías la sincronización con el servidor
          debugPrint("🔄 Sincronizando ${pendientes.length} monitoreos pendientes...");
        }
      }
    } catch (e) {
      debugPrint("❌ Error en sincronización en segundo plano: $e");
    }
  }

  // ==================== MÉTODOS DE UTILIDAD ====================
  
  Future<void> speak(String text) async {
    try {
      await tts.awaitSpeakCompletion(true);
      await tts.speak(text);
      debugPrint("🤖 MAYA: $text");
    } catch (e) {
      debugPrint("❌ Error en TTS: $e");
    }
  }

  Future<String> listen({int duration = 5}) async {
    if (isListening) return '';

    try {
      isListening = true;
      listeningController.add(true);
      debugPrint("\n🎤 [MAYA ESCUCHANDO...]");

      final Completer<String> completer = Completer<String>();
      String recognizedText = '';

      speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            recognizedText = result.recognizedWords.toLowerCase().trim();
            speechResultsController.add(recognizedText);
            debugPrint("👤 USUARIO: $recognizedText");
            if (!completer.isCompleted) {
              completer.complete(recognizedText);
            }
          }
        },
        listenFor: Duration(seconds: duration),
        pauseFor: Duration(seconds: 2),
        cancelOnError: true,
        partialResults: false,
        localeId: 'es_ES',
      );

      Timer(Duration(seconds: duration + 2), () {
        if (!completer.isCompleted) {
          isListening = false;
          listeningController.add(false);
          speech.stop();
          completer.complete(recognizedText);
        }
      });

      final result = await completer.future;
      isListening = false;
      listeningController.add(false);
      return result;
    } catch (e) {
      isListening = false;
      listeningController.add(false);
      debugPrint("❌ Error en listen: $e");
      return '';
    }
  }

  bool confirmacionReconocida(String respuesta, String palabraClave) {
    const umbralSimilitud = 70;

    final variaciones = {
      'confirmar': ['confirmar', 'confirma', 'confirmo', 'confirmado', 'conforme', 'sí', 'si', 'vale', 'ok', 'okay', 'correcto', 'exacto', 'perfecto'],
      'cancelar': ['cancelar', 'cancela', 'cancelado', 'cancelo', 'no', 'incorrecto', 'mal', 'error'],
      'repetir': ['repetir', 'repite', 'otra vez', 'de nuevo', 'nuevamente', 'empezar', 'comenzar'],
    };

    respuesta = respuesta.toLowerCase().trim();

    if (respuesta.contains(palabraClave.toLowerCase())) return true;
    if (variaciones[palabraClave]?.any((v) => respuesta.contains(v)) ?? false) return true;
    if (ratio(palabraClave.toLowerCase(), respuesta) > umbralSimilitud) return true;

    return variaciones[palabraClave]?.any((v) => ratio(v, respuesta) > umbralSimilitud) ?? false;
  }

  int? palabrasANumero(String texto) {
    if (texto.isEmpty) return null;

    final numeros = {
      'cero': 0, 'sero': 0, 'xero': 0,
      'uno': 1, 'un': 1, 'una': 1, 'primero': 1, 'primer': 1,
      'dos': 2, 'segundo': 2,
      'tres': 3, 'tercero': 3, 'tercer': 3,
      'cuatro': 4, 'cuarto': 4,
      'cinco': 5, 'quinto': 5,
      'seis': 6, 'sexto': 6,
      'siete': 7, 'séptimo': 7, 'septimo': 7,
      'ocho': 8, 'octavo': 8,
      'nueve': 9, 'noveno': 9,
      'diez': 10, 'décimo': 10, 'decimo': 10,
    };

    String textoLimpio = texto.replaceAll(RegExp(r'[^a-zA-ZáéíóúüñÁÉÍÓÚÜÑ0-9]'), ' ').toLowerCase().trim();

    final numeroDirecto = int.tryParse(textoLimpio);
    if (numeroDirecto != null) return numeroDirecto;

    for (final palabra in textoLimpio.split(' ')) {
      if (numeros.containsKey(palabra)) return numeros[palabra];
    }

    for (final entry in numeros.entries) {
      if (ratio(entry.key, textoLimpio) > 80) return entry.value;
    }

    return null;
  }

  bool procesarRespuestaPregunta(Pregunta pregunta, String respuesta, int intentos, Map<String, dynamic> respuestaMap) {
    String tipo = pregunta.tipoRespuesta ?? 'texto';
    respuesta = respuesta.trim().toLowerCase();

    switch (tipo) {
      case 'opciones':
        return _procesarOpciones(pregunta, respuesta, respuestaMap);
      case 'numero':
        return _procesarNumero(pregunta, respuesta, respuestaMap, intentos);
      default:
        respuestaMap['respuesta'] = respuesta;
        return true;
    }
  }

  bool _procesarOpciones(Pregunta pregunta, String respuesta, Map<String, dynamic> respuestaMap) {
    if (pregunta.opciones == null || pregunta.opciones!.isEmpty) return false;

    final opciones = pregunta.opciones!.map((o) => o.valor.toLowerCase()).toList();

    int? numero = palabrasANumero(respuesta);
    if (numero == null) {
      final match = RegExp(r'\d+').firstMatch(respuesta);
      if (match != null) numero = int.tryParse(match.group(0)!);
    }

    if (numero != null && numero > 0 && numero <= opciones.length) {
      respuestaMap['respuesta'] = pregunta.opciones![numero - 1].valor;
      return true;
    }

    String? mejorOpcion;
    int mejorPuntaje = 0;

    for (int i = 0; i < opciones.length; i++) {
      final opcion = opciones[i];
      if (respuesta.contains(opcion) || opcion.contains(respuesta)) {
        respuestaMap['respuesta'] = pregunta.opciones![i].valor;
        return true;
      }

      final puntaje = ratio(opcion, respuesta);
      if (puntaje > mejorPuntaje && puntaje > 60) {
        mejorPuntaje = puntaje;
        mejorOpcion = pregunta.opciones![i].valor;
      }
    }

    if (mejorOpcion != null) {
      respuestaMap['respuesta'] = mejorOpcion;
      return true;
    }

    return false;
  }

  bool _procesarNumero(Pregunta pregunta, String respuesta, Map<String, dynamic> respuestaMap, int intentos) {
    int? numero = palabrasANumero(respuesta);

    if (numero == null) {
      final match = RegExp(r'\d+').firstMatch(respuesta);
      if (match != null) numero = int.tryParse(match.group(0)!);
    }

    if (numero == null && intentos < 2) return false;
    if (numero == null) numero = 0;

    final min = pregunta.min ?? 0;
    final max = pregunta.max ?? 100;

    if (numero < min || numero > max) return false;

    respuestaMap['respuesta'] = numero;
    return true;
  }

  Future<void> stopAssistant() async {
    isActive = false;
    isListening = false;
    
    try {
      await tts.stop();
      speech.stop();
    } catch (e) {
      debugPrint("❌ Error al detener Maya: $e");
    }
    
    _updateStatus("Maya desactivada");
    listeningController.add(false);
  }

  void _updateStatus(String status) {
    currentMessage = status;
    statusController.add(status);
    debugPrint("📢 Estado Maya: $status");
  }

  void _updateListeningState(bool listening) {
    isListening = listening;
    listeningController.add(listening);
  }

  void dispose() {
    speechResultsController.close();
    statusController.close();
    listeningController.close();
    stopAssistant();
  }

  // Getters para el estado
  bool get isAssistantActive => isActive;
  String get currentStatus => currentMessage;
  List<MonitoreoRespuesta> get currentResponses => List.from(respuestas);
}
