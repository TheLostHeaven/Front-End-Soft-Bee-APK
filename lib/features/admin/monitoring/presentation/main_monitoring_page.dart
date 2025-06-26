import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/apiary_management_page.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/enhanced_monitoreo_page.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/queen_notification_page.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/question_management_page.dart';
import '../models/model.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';


class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({Key? key}) : super(key: key);

  @override
  _MainDashboardPageState createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage>
    with SingleTickerProviderStateMixin {
  // Servicios
  late LocalDBService dbService;

  // Controladores de animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Estado
  bool isLoading = true;
  bool isConnected = false;
  Map<String, dynamic> estadisticas = {};
  List<Apiario> apiarios = [];

  // Colores
  final Color colorAmarillo = const Color(0xFFFBC209);
  final Color colorNaranja = const Color(0xFFFF9800);
  final Color colorAmbarClaro = const Color(0xFFFFF8E1);
  final Color colorAmbarMedio = const Color(0xFFFFE082);
  final Color colorVerde = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
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

    _animationController.forward();
  }

  Future<void> _initializeServices() async {
    try {
      dbService = LocalDBService();
      await _loadData();
      await _checkConnection();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error al inicializar: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      // Cargar estadísticas
      estadisticas = await dbService.getEstadisticas();

      // Cargar apiarios
      apiarios = await dbService.getApiarios();

      setState(() {});
    } catch (e) {
      debugPrint("❌ Error al cargar datos: $e");
    }
  }

  Future<void> _checkConnection() async {
    try {
      final connected = await ApiService.verificarConexion();
      setState(() {
        isConnected = connected;
      });
    } catch (e) {
      setState(() {
        isConnected = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    if (isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: _buildAppBar(isDesktop, isTablet),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildBody(isDesktop, isTablet),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop, bool isTablet) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.hive, color: Colors.white, size: isDesktop ? 28 : 24),
          SizedBox(width: 12),
          Text(
            'Sistema de Monitoreo',
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
            color: isConnected ? colorVerde : Colors.red,
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

        IconButton(
          icon: Icon(Icons.sync, color: Colors.white),
          onPressed: _syncData,
          tooltip: "Sincronizar datos",
        ).animate().fadeIn(delay: 400.ms).scale(),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: colorAmbarClaro,
      body: Center(
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
              "Cargando sistema...",
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
      ),
    );
  }

  Widget _buildBody(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas principales
          _buildStatsGrid(isDesktop, isTablet),

          SizedBox(height: isDesktop ? 32 : 24),

          // Menú principal de opciones
          _buildMainMenu(isDesktop, isTablet),

          SizedBox(height: isDesktop ? 32 : 24),

          // Acciones rápidas
          _buildQuickActions(isDesktop, isTablet),
        ],
      ),
    );
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
            ? Colors.red
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

  Widget _buildMainMenu(bool isDesktop, bool isTablet) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, colorAmbarClaro.withOpacity(0.3)],
          ),
        ),
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu,
                  color: colorNaranja,
                  size: isDesktop ? 28 : 24,
                ),
                SizedBox(width: 12),
                Text(
                  "Menú Principal",
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: colorNaranja,
                  ),
                ),
              ],
            ),

            SizedBox(height: isDesktop ? 24 : 16),

            // Opciones del menú en grid responsivo
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop
                  ? 3
                  : isTablet
                  ? 2
                  : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop
                  ? 1.5
                  : isTablet
                  ? 1.3
                  : 3,
              children: [
                _buildMenuOption(
                  title: "Gestionar Apiarios",
                  subtitle: "CRUD completo de apiarios",
                  icon: Icons.location_city,
                  color: colorVerde,
                  onTap: () => _navigateToApiarios(),
                  isDesktop: isDesktop,
                ),
                _buildMenuOption(
                  title: "Preguntas de Monitoreo",
                  subtitle: "Gestionar y reordenar preguntas",
                  icon: Icons.quiz,
                  color: colorAmarillo,
                  onTap: () => _navigateToPreguntas(),
                  isDesktop: isDesktop,
                ),
                _buildMenuOption(
                  title: "Calendario de Reinas",
                  subtitle: "Programar cambios de reina",
                  icon: Icons.calendar_month,
                  color: Colors.purple,
                  onTap: () => _navigateToCalendar(),
                  isDesktop: isDesktop,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMenuOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDesktop,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), Colors.white],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isDesktop ? 40 : 32, color: color)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: Offset(1, 1),
                    end: Offset(1.1, 1.1),
                    duration: 2000.ms,
                  ),

              SizedBox(height: isDesktop ? 16 : 12),

              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 4),

              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 12 : 10,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
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
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: colorNaranja,
                  size: isDesktop ? 28 : 24,
                ),
                SizedBox(width: 12),
                Text(
                  "Acciones Rápidas",
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: colorNaranja,
                  ),
                ),
              ],
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
                  () => _navigateToMonitoring(),
                  isDesktop,
                ),
                _buildActionButton(
                  "Sincronizar Datos",
                  Icons.sync,
                  colorNaranja,
                  () => _syncData(),
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
                  "Configuración",
                  Icons.settings,
                  Colors.grey[600]!,
                  () => _showSettings(),
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

  // Métodos de navegación
  void _navigateToApiarios() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ApiariosManagementScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToPreguntas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PreguntasManagementScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QueenCalendarScreen()),
    );
  }

  void _navigateToMonitoring() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EnhancedMonitoreoScreen()),
    ).then((_) => _loadData());
  }

  // Métodos de acción
  Future<void> _syncData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sincronizando datos...", style: GoogleFonts.poppins()),
          backgroundColor: colorAmarillo,
        ),
      );

      await _checkConnection();

      if (isConnected) {
        // Sincronizar con el servidor
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Datos sincronizados correctamente",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: colorVerde,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sin conexión - Los datos se sincronizarán automáticamente",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error en sincronización: $e",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Función de historial en desarrollo",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showSettings() {
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
              leading: Icon(Icons.sync),
              title: Text("Configurar sincronización"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.storage),
              title: Text("Gestionar datos locales"),
              onTap: () {
                Navigator.pop(context);
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