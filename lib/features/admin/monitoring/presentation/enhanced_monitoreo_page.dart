import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/model.dart';
import '../services/enhanced_voice_assistant_service.dart';
import '../services/local_db_service.dart';
import '../services/api_service.dart';
// import 'dart:math' as math;

class EnhancedMonitoreoScreen extends StatefulWidget {
  const EnhancedMonitoreoScreen({Key? key}) : super(key: key);

  @override
  _EnhancedMonitoreoScreenState createState() =>
      _EnhancedMonitoreoScreenState();
}

class _EnhancedMonitoreoScreenState extends State<EnhancedMonitoreoScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Servicios
  late EnhancedVoiceAssistantService mayaAssistant;
  late LocalDBService dbService;

  // Controladores de animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  // Estado de la aplicación
  bool isInitialized = false;
  bool isConnected = false;
  String connectionStatus = "Verificando conexión...";

  // Estado de Maya
  bool isMayaActive = false;
  bool isMayaListening = false;
  String mayaStatus = "Maya desactivada";
  List<MonitoreoRespuesta> currentResponses = [];

  // Datos
  List<Apiario> apiarios = [];
  List<Colmena> colmenas = [];
  Map<String, dynamic> estadisticas = {};

  // Colores
  final Color colorAmarillo = const Color(0xFFFBC209);
  final Color colorNaranja = const Color(0xFFFF9800);
  final Color colorAmbarClaro = const Color(0xFFFFF8E1);
  final Color colorAmbarMedio = const Color(0xFFFFE082);
  final Color colorVerde = const Color(0xFF4CAF50);
  final Color colorRojo = const Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeServices();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _initializeServices() async {
    try {
      // Inicializar servicios
      mayaAssistant = EnhancedVoiceAssistantService();
      dbService = LocalDBService();

      // Configurar listeners de Maya
      _setupMayaListeners();

      // Inicializar Maya
      await mayaAssistant.initialize();

      // Cargar datos iniciales
      await _loadInitialData();

      // Verificar conexión
      await _checkConnection();

      setState(() {
        isInitialized = true;
      });

      _showSnackBar("Sistema inicializado correctamente", colorVerde);
    } catch (e) {
      debugPrint("❌ Error al inicializar servicios: $e");
      _showSnackBar("Error al inicializar: $e", colorRojo);
    }
  }

  void _setupMayaListeners() {
    // Listener para el estado de Maya
    mayaAssistant.statusController.stream.listen((status) {
      if (mounted) {
        setState(() {
          mayaStatus = status;
        });
      }
    });

    // Listener para el estado de escucha
    mayaAssistant.listeningController.stream.listen((listening) {
      if (mounted) {
        setState(() {
          isMayaListening = listening;
        });
      }
    });

    // Listener para cambios en el estado activo
    mayaAssistant.speechResultsController.stream.listen((result) {
      if (mounted) {
        setState(() {
          isMayaActive = mayaAssistant.isAssistantActive;
          currentResponses = mayaAssistant.currentResponses;
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      // Cargar apiarios
      apiarios = await dbService.getApiarios();

      // Cargar estadísticas
      estadisticas = await dbService.getEstadisticas();

      setState(() {});

      debugPrint("✅ Datos iniciales cargados");
    } catch (e) {
      debugPrint("❌ Error al cargar datos: $e");
    }
  }

  Future<void> _checkConnection() async {
    try {
      final connected = await ApiService.verificarConexion();
      setState(() {
        isConnected = connected;
        connectionStatus = connected ? "Conectado al servidor" : "Modo offline";
      });
    } catch (e) {
      setState(() {
        isConnected = false;
        connectionStatus = "Sin conexión";
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    mayaAssistant.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      mayaAssistant.stopAssistant();
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: _buildAppBar(isDesktop, isTablet),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildBody(isDesktop, isTablet),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildMayaFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop, bool isTablet) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.hive, color: Colors.white, size: isDesktop ? 28 : 24),
          SizedBox(width: 12),
          Text(
            'Monitoreo Inteligente',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : 20,
              color: Colors.white,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
      backgroundColor: colorNaranja,
      elevation: 0,
      actions: [
        // Indicador de conexión
        Container(
          margin: EdgeInsets.only(right: 8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected ? colorVerde : colorRojo,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                isConnected ? "Online" : "Offline",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).scale(),

        // Botón de sincronización
        IconButton(
          icon: Icon(Icons.sync, color: Colors.white),
          onPressed: _syncData,
          tooltip: "Sincronizar datos",
        ).animate().fadeIn(delay: 400.ms).scale(),

        // Botón de configuración
        IconButton(
          icon: Icon(Icons.settings, color: Colors.white),
          onPressed: () => _showSettingsDialog(),
          tooltip: "Configuración",
        ).animate().fadeIn(delay: 600.ms).scale(),
      ],
    );
  }

  Widget _buildBody(bool isDesktop, bool isTablet) {
    if (!isInitialized) {
      return _buildLoadingScreen();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado de Maya
          _buildMayaStatusCard(isDesktop, isTablet),

          SizedBox(height: isDesktop ? 24 : 16),

          // Estadísticas principales
          _buildStatsGrid(isDesktop, isTablet),

          SizedBox(height: isDesktop ? 24 : 16),

          // Acciones rápidas
          _buildQuickActions(isDesktop, isTablet),

          SizedBox(height: isDesktop ? 24 : 16),

          // Lista de apiarios
          _buildApiariosList(isDesktop, isTablet),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorAmarillo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hive, size: 64, color: colorNaranja),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 2000.ms),

          SizedBox(height: 24),

          Text(
            "Inicializando Maya...",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorNaranja,
            ),
          ),

          SizedBox(height: 12),

          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorAmarillo),
          ),
        ],
      ),
    );
  }

  Widget _buildMayaStatusCard(bool isDesktop, bool isTablet) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isMayaActive ? colorVerde : colorAmarillo,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isMayaActive ? colorVerde.withOpacity(0.1) : colorAmbarClaro,
              Colors.white,
            ],
          ),
        ),
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMayaActive ? colorVerde : colorAmarillo,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isMayaActive ? colorVerde : colorAmarillo)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isMayaListening ? Icons.mic : Icons.assistant,
                        color: Colors.white,
                        size: isDesktop ? 28 : 24,
                      ),
                    )
                    .animate(
                      onPlay: (controller) => isMayaListening
                          ? controller.repeat(reverse: true)
                          : null,
                    )
                    .scale(
                      begin: Offset(1, 1),
                      end: Offset(1.1, 1.1),
                      duration: 1000.ms,
                    ),

                SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Maya - Asistente de Voz",
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: isMayaActive ? colorVerde : colorNaranja,
                        ),
                      ),
                      Text(
                        mayaStatus,
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 14 : 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicador de estado
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMayaActive ? colorVerde : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isMayaActive ? "ACTIVA" : "INACTIVA",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (isMayaActive && currentResponses.isNotEmpty) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 12),
              Text(
                "Respuestas actuales:",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: colorNaranja,
                ),
              ),
              SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(maxHeight: 120),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: currentResponses.length,
                  itemBuilder: (context, index) {
                    final resp = currentResponses[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 4),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorAmbarClaro,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorAmbarMedio),
                      ),
                      child: Text(
                        "${resp.preguntaTexto}: ${resp.respuesta}",
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ],

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isMayaActive ? _stopMaya : _startMaya,
                    icon: Icon(
                      isMayaActive ? Icons.stop : Icons.play_arrow,
                      size: 20,
                    ),
                    label: Text(
                      isMayaActive ? "Detener Maya" : "Iniciar Maya",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMayaActive ? colorRojo : colorVerde,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                ElevatedButton.icon(
                  onPressed: _startPassiveListening,
                  icon: Icon(Icons.hearing, size: 20),
                  label: Text(
                    "Modo Pasivo",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorAmarillo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatsGrid(bool isDesktop, bool isTablet) {
    final stats = [
      {
        'title': 'Apiarios',
        'value': estadisticas['total_apiarios']?.toString() ?? '0',
        'icon': Icons.location_on,
        'color': colorVerde,
      },
      {
        'title': 'Colmenas',
        'value': estadisticas['total_colmenas']?.toString() ?? '0',
        'icon': Icons.hive,
        'color': colorAmarillo,
      },
      {
        'title': 'Monitoreos',
        'value': estadisticas['total_monitoreos']?.toString() ?? '0',
        'icon': Icons.analytics,
        'color': colorNaranja,
      },
      {
        'title': 'Pendientes',
        'value': estadisticas['monitoreos_pendientes']?.toString() ?? '0',
        'icon': Icons.sync_problem,
        'color':
            estadisticas['monitoreos_pendientes'] != null &&
                estadisticas['monitoreos_pendientes'] > 0
            ? colorRojo
            : Colors.grey,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop
            ? 4
            : isTablet
            ? 2
            : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.2 : 1.1,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          stat['title'] as String,
          stat['value'] as String,
          stat['icon'] as IconData,
          stat['color'] as Color,
          index,
          isDesktop,
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    int index,
    bool isDesktop,
  ) {
    return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.1), Colors.white],
              ),
            ),
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: isDesktop ? 32 : 28, color: color)
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: Offset(1, 1),
                      end: Offset(1.1, 1.1),
                      duration: 2000.ms,
                    ),

                SizedBox(height: 12),

                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),

                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 300 + (index * 100)))
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickActions(bool isDesktop, bool isTablet) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Acciones Rápidas",
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: colorNaranja,
              ),
            ),

            SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  "Nuevo Monitoreo",
                  Icons.add_circle,
                  colorVerde,
                  () => _startNewMonitoring(),
                  isDesktop,
                ),
                _buildActionButton(
                  "Ver Historial",
                  Icons.history,
                  colorAmarillo,
                  () => _showHistory(),
                  isDesktop,
                ),
                _buildActionButton(
                  "Sincronizar",
                  Icons.sync,
                  colorNaranja,
                  () => _syncData(),
                  isDesktop,
                ),
                _buildActionButton(
                  "Configurar",
                  Icons.settings,
                  Colors.grey[600]!,
                  () => _showSettingsDialog(),
                  isDesktop,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isDesktop,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isDesktop ? 20 : 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: isDesktop ? 14 : 12,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 20 : 16,
          vertical: isDesktop ? 12 : 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildApiariosList(bool isDesktop, bool isTablet) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Mis Apiarios",
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: colorNaranja,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: _loadInitialData,
                  icon: Icon(Icons.refresh, color: colorNaranja),
                  tooltip: "Actualizar",
                ),
              ],
            ),

            SizedBox(height: 16),

            if (apiarios.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.location_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "No hay apiarios configurados",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: apiarios.length,
                itemBuilder: (context, index) {
                  final apiario = apiarios[index];
                  return _buildApiarioCard(apiario, index, isDesktop);
                },
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildApiarioCard(Apiario apiario, int index, bool isDesktop) {
    return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(isDesktop ? 16 : 12),
            leading: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorAmarillo.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: colorNaranja),
            ),
            title: Text(
              apiario.nombre,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: isDesktop ? 16 : 14,
              ),
            ),
            subtitle: Text(
              apiario.ubicacion,
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontSize: isDesktop ? 14 : 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _monitorApiario(apiario),
                  icon: Icon(Icons.play_arrow, color: colorVerde),
                  tooltip: "Iniciar monitoreo",
                ),
                IconButton(
                  onPressed: () => _showApiarioDetails(apiario),
                  icon: Icon(Icons.info_outline, color: colorNaranja),
                  tooltip: "Ver detalles",
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 900 + (index * 100)))
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildMayaFAB() {
    return FloatingActionButton.extended(
          onPressed: isMayaActive ? _stopMaya : _startMaya,
          backgroundColor: isMayaActive ? colorRojo : colorVerde,
          icon: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: Icon(
              isMayaActive ? Icons.stop : Icons.mic,
              key: ValueKey(isMayaActive),
              color: Colors.white,
            ),
          ),
          label: Text(
            isMayaActive ? "Detener" : "Maya",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        )
        .animate(
          onPlay: (controller) =>
              isMayaListening ? controller.repeat(reverse: true) : null,
        )
        .scale(begin: Offset(1, 1), end: Offset(1.1, 1.1), duration: 1000.ms);
  }

  // ==================== MÉTODOS DE ACCIÓN ====================

  Future<void> _startMaya() async {
    try {
      await mayaAssistant.startMonitoringFlow();
      setState(() {
        isMayaActive = true;
      });
      _showSnackBar("Maya activada - Iniciando monitoreo", colorVerde);
    } catch (e) {
      _showSnackBar("Error al activar Maya: $e", colorRojo);
    }
  }

  Future<void> _stopMaya() async {
    try {
      await mayaAssistant.stopAssistant();
      setState(() {
        isMayaActive = false;
        isMayaListening = false;
      });
      _showSnackBar("Maya desactivada", Colors.grey);
    } catch (e) {
      _showSnackBar("Error al detener Maya: $e", colorRojo);
    }
  }

  Future<void> _startPassiveListening() async {
    try {
      _showSnackBar(
        "Maya en modo pasivo - Di 'Maya, inicia monitoreo'",
        colorAmarillo,
      );
      mayaAssistant.startPassiveListening();
    } catch (e) {
      _showSnackBar("Error al activar modo pasivo: $e", colorRojo);
    }
  }

  Future<void> _syncData() async {
    try {
      _showSnackBar("Sincronizando datos...", colorAmarillo);

      // Verificar conexión
      await _checkConnection();

      if (!isConnected) {
        _showSnackBar(
          "Sin conexión - Los datos se sincronizarán automáticamente",
          Colors.orange,
        );
        return;
      }

      // Aquí implementarías la lógica de sincronización
      await Future.delayed(Duration(seconds: 2)); // Simular sincronización

      _showSnackBar("Datos sincronizados correctamente", colorVerde);
      await _loadInitialData();
    } catch (e) {
      _showSnackBar("Error en sincronización: $e", colorRojo);
    }
  }

  void _startNewMonitoring() {
    if (apiarios.isEmpty) {
      _showSnackBar("Primero configura al menos un apiario", Colors.orange);
      return;
    }

    _startMaya();
  }

  void _showHistory() {
    // Implementar navegación al historial
    _showSnackBar("Función de historial en desarrollo", Colors.blue);
  }

  void _monitorApiario(Apiario apiario) {
    // Implementar monitoreo específico del apiario
    _showSnackBar("Iniciando monitoreo de ${apiario.nombre}", colorVerde);
    _startMaya();
  }

  void _showApiarioDetails(Apiario apiario) {
    // Implementar detalles del apiario
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          apiario.nombre,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ubicación: ${apiario.ubicacion}"),
            Text("ID: ${apiario.id}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Configuración",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.mic),
              title: Text("Configurar Maya"),
              onTap: () {
                Navigator.pop(context);
                // Implementar configuración de Maya
              },
            ),
            ListTile(
              leading: Icon(Icons.sync),
              title: Text("Configurar sincronización"),
              onTap: () {
                Navigator.pop(context);
                // Implementar configuración de sync
              },
            ),
            ListTile(
              leading: Icon(Icons.storage),
              title: Text("Gestionar datos locales"),
              onTap: () {
                Navigator.pop(context);
                // Implementar gestión de datos
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cerrar"),
          ),
        ],
      ),
    );
  }
}
