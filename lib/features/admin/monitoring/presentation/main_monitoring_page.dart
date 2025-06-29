// lib/features/admin/monitoring/presentation/main_monitoring_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/beehive_management_page.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/apiary_management_page.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/queen_calendar_page.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/question_management_page.dart';
import 'package:sotfbee/features/admin/monitoring/service/enhaced_api_service.dart';
import '../models/enhanced_models.dart';

class MainMonitoringScreen extends StatefulWidget {
  const MainMonitoringScreen({Key? key}) : super(key: key);

  @override
  _MainMonitoringScreenState createState() => _MainMonitoringScreenState();
}

class _MainMonitoringScreenState extends State<MainMonitoringScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isConnected = false;
  Map<String, dynamic> estadisticas = {};
  List<Apiario> apiarios = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
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
      estadisticas = await EnhancedApiService.obtenerEstadisticas();
      apiarios = await EnhancedApiService.obtenerApiarios();
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error al cargar datos: $e");
      // Datos de ejemplo para desarrollo
      estadisticas = {
        'total_apiarios': 5,
        'total_colmenas': 23,
        'total_monitoreos': 156,
        'monitoreos_pendientes': 3,
      };
      apiarios = [
        Apiario(id: 1, nombre: "Apiario Norte", ubicacion: "Sector La Montaña"),
        Apiario(id: 2, nombre: "Apiario Sur", ubicacion: "Valle del Río"),
        Apiario(id: 3, nombre: "Apiario Central", ubicacion: "Finca El Roble"),
      ];
      setState(() {});
    }
  }

  Future<void> _checkConnection() async {
    try {
      final connected = await EnhancedApiService.verificarConexion();
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F8F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                "Cargando sistema...",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.amber[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text(
                  'Sistema de Monitoreo',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideX(
                  begin: -0.2,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutQuad,
                ),
        backgroundColor: Colors.amber[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.red,
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
                const SizedBox(width: 4),
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
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          IconButton(icon: const Icon(Icons.sync), onPressed: _syncData)
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
        ],
      ),
      backgroundColor: const Color(0xFFF9F8F6),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1200 : (isTablet ? 900 : double.infinity),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(isDesktop, isTablet)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(
                        begin: -0.2,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutQuad,
                      ),
                  SizedBox(height: isDesktop ? 32 : 20),

                  // Layout responsive: en desktop, mostrar menú y apiarios lado a lado
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildMenuSection(isDesktop, isTablet)
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 600.ms)
                              .slideX(begin: -0.2, end: 0),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: _buildApiariosSection(isDesktop, isTablet)
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 600.ms)
                              .slideX(begin: 0.2, end: 0),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildMenuSection(isDesktop, isTablet)
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                        SizedBox(height: isDesktop ? 32 : 20),
                        _buildApiariosSection(isDesktop, isTablet)
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),

                  SizedBox(height: isDesktop ? 32 : 20),
                  _buildQuickActionsSection(context, isDesktop, isTablet)
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 24 : 20)),
      decoration: BoxDecoration(
        color: Colors.amber[600],
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header principal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                ),
                child:
                    Icon(
                          Icons.hive,
                          size: isDesktop ? 40 : 32,
                          color: Colors.amber[700],
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .rotate(begin: -0.05, end: 0.05, duration: 2000.ms),
              ),
              SizedBox(width: isDesktop ? 24 : 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'SoftBee',
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 28 : (isTablet ? 26 : 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Sistema de Gestión Apícola',
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 16 : 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 32 : 20),

          // Estadísticas en grid responsive
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHeaderStat(
                  icon: Icons.location_on_outlined,
                  label: 'Apiarios',
                  value: estadisticas['total_apiarios']?.toString() ?? '0',
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.hive_outlined,
                  label: 'Colmenas',
                  value: estadisticas['total_colmenas']?.toString() ?? '0',
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.analytics_outlined,
                  label: 'Monitoreos',
                  value: estadisticas['total_monitoreos']?.toString() ?? '0',
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.pending_actions_outlined,
                  label: 'Pendientes',
                  value:
                      estadisticas['monitoreos_pendientes']?.toString() ?? '0',
                  isDesktop: isDesktop,
                ),
              ],
            )
          else
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildHeaderStat(
                  icon: Icons.location_on_outlined,
                  label: 'Apiarios',
                  value: estadisticas['total_apiarios']?.toString() ?? '0',
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.hive_outlined,
                  label: 'Colmenas',
                  value: estadisticas['total_colmenas']?.toString() ?? '0',
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.analytics_outlined,
                  label: 'Monitoreos',
                  value: estadisticas['total_monitoreos']?.toString() ?? '0',
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.pending_actions_outlined,
                  label: 'Pendientes',
                  value:
                      estadisticas['monitoreos_pendientes']?.toString() ?? '0',
                  isDesktop: isDesktop,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String label,
    required String value,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDesktop ? 24 : 20, color: Colors.white),
          SizedBox(height: isDesktop ? 8 : 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 14 : 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        _buildSectionTitle(
          'Menú Principal',
          Icons.dashboard_outlined,
          isDesktop,
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        _buildMenuCard(isDesktop, isTablet),
      ],
    );
  }

  Widget _buildMenuCard(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.amber[200]!, width: 1),
      ),
      child: Column(
        children: [
          _buildMenuRow(
            Icons.location_city_outlined,
            'Gestionar Apiarios',
            'CRUD completo de apiarios',
            iconColor: Colors.green[700]!,
            onTap: () => _navigateToApiarios(),
            isDesktop: isDesktop,
          ),
          Divider(height: isDesktop ? 32 : 24),
          _buildMenuRow(
            Icons.hive_outlined,
            'Gestionar Colmenas',
            'CRUD completo de colmenas',
            iconColor: Colors.amber[700]!,
            onTap: () => _navigateToColmenas(),
            isDesktop: isDesktop,
          ),
          Divider(height: isDesktop ? 32 : 24),
          _buildMenuRow(
            Icons.quiz_outlined,
            'Preguntas de Monitoreo',
            'Gestionar y reordenar preguntas',
            iconColor: Colors.blue[700]!,
            onTap: () => _navigateToPreguntas(),
            isDesktop: isDesktop,
          ),
          Divider(height: isDesktop ? 32 : 24),
          _buildMenuRow(
            Icons.calendar_month_outlined,
            'Calendario de Reinas',
            'Programar cambios de reina',
            iconColor: Colors.purple[700]!,
            onTap: () => _navigateToCalendar(),
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(
    IconData icon,
    String title,
    String subtitle, {
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDesktop,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 12 : 8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
              ),
              child: Icon(icon, color: iconColor, size: isDesktop ? 24 : 20),
            ),
            SizedBox(width: isDesktop ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 14 : 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: isDesktop ? 18 : 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiariosSection(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        _buildSectionTitle(
          'Apiarios Recientes',
          Icons.location_on_outlined,
          isDesktop,
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        _buildApiariosCard(isDesktop, isTablet),
      ],
    );
  }

  Widget _buildApiariosCard(bool isDesktop, bool isTablet) {
    if (apiarios.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isDesktop ? 40 : 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.amber[200]!, width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay apiarios',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer apiario para comenzar',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _navigateToApiarios(),
              icon: const Icon(Icons.add),
              label: const Text('Crear Apiario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.amber[200]!, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimos Apiarios',
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToApiarios(),
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.poppins(
                    color: Colors.amber[800],
                    fontWeight: FontWeight.w600,
                    fontSize: isDesktop ? 14 : 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: apiarios.take(3).length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final apiario = apiarios[index];
              return _buildApiarioRow(
                apiario: apiario,
                isDesktop: isDesktop,
                onTap: () => _showApiarioDetails(apiario),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApiarioRow({
    required Apiario apiario,
    required bool isDesktop,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 12 : 8),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 12 : 8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.green[700],
                size: isDesktop ? 24 : 20,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apiario.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    apiario.ubicacion,
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 14 : 12,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: isDesktop ? 16 : 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    return Column(
      children: [
        _buildSectionTitle(
          'Acciones Rápidas',
          Icons.flash_on_outlined,
          isDesktop,
        ),
        SizedBox(height: isDesktop ? 16 : 12),

        // En desktop, mostrar acciones en grid; en tablet 2x2; en móvil, scroll horizontal
        if (isDesktop)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: _buildActionButtons(context, isDesktop),
          )
        else if (isTablet)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: _buildActionButtons(context, isDesktop),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _buildActionButtons(context, isDesktop)
                  .map(
                    (button) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: button,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, bool isDesktop) {
    final buttonWidth = isDesktop ? 140.0 : 120.0;

    return [
      _buildActionButton(
        icon: Icons.sync_outlined,
        label: 'Sincronizar',
        onPressed: _syncData,
        color: Colors.blue[700]!,
        width: buttonWidth,
        isDesktop: isDesktop,
      ),
      _buildActionButton(
        icon: Icons.mic_outlined,
        label: 'Maya',
        onPressed: () => _showMayaAlert(),
        color: Colors.amber[700]!,
        width: buttonWidth,
        isDesktop: isDesktop,
      ),
      _buildActionButton(
        icon: Icons.history_outlined,
        label: 'Historial',
        onPressed: () => _showHistory(),
        color: Colors.green[700]!,
        width: buttonWidth,
        isDesktop: isDesktop,
      ),
      _buildActionButton(
        icon: Icons.settings_outlined,
        label: 'Configuración',
        onPressed: () => _showSettings(),
        color: Colors.grey[700]!,
        width: buttonWidth,
        isDesktop: isDesktop,
      ),
    ];
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required double width,
    required bool isDesktop,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 20 : 16,
            horizontal: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isDesktop ? 28 : 24),
            SizedBox(height: isDesktop ? 12 : 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: isDesktop ? 13 : 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: isDesktop ? 24 : 20, color: Colors.amber[800]),
        SizedBox(width: isDesktop ? 12 : 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.amber[800],
          ),
        ),
      ],
    );
  }

  // Métodos de navegación
  void _navigateToApiarios() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ApiariosManagementScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToColmenas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ColmenasManagementScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToPreguntas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuestionsManagementScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QueenCalendarScreen()),
    );
  }

  // Métodos de acción
  Future<void> _syncData() async {
    try {
      _showSnackBar("Sincronizando datos...", Colors.amber[600]!);
      await _checkConnection();
      if (isConnected) {
        await _loadData();
        _showSnackBar("Datos sincronizados correctamente", Colors.green);
      } else {
        _showSnackBar("Sin conexión a internet", Colors.orange);
      }
    } catch (e) {
      _showSnackBar("Error en sincronización: $e", Colors.red);
    }
  }

  void _showHistory() {
    _showSnackBar("Función de historial en desarrollo", Colors.blue);
  }

  void _showMayaAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.mic, color: Colors.amber[600]),
            const SizedBox(width: 12),
            Text(
              "Maya",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "La función de asistente de voz Maya estará disponible próximamente.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Entendido",
              style: GoogleFonts.poppins(
                color: Colors.amber[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Configuración",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.sync, color: Colors.amber[600]),
              title: Text(
                "Configurar sincronización",
                style: GoogleFonts.poppins(),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.storage, color: Colors.green),
              title: Text("Gestionar datos", style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text("Acerca de", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: GoogleFonts.poppins(
                color: Colors.amber[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiarioDetails(Apiario apiario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          apiario.nombre,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Ubicación:', apiario.ubicacion),
            _buildDetailRow('ID:', apiario.id.toString()),
            if (apiario.fechaCreacion != null)
              _buildDetailRow(
                'Fecha de creación:',
                '${apiario.fechaCreacion!.day}/${apiario.fechaCreacion!.month}/${apiario.fechaCreacion!.year}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(
                color: Colors.amber[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToApiarios();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Gestionar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.hive, color: Colors.amber[600]),
            const SizedBox(width: 12),
            Text(
              "SoftBee",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sistema de Monitoreo de Colmenas",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text("Versión 2.0.0", style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 16),
            Text(
              "Aplicación desarrollada para facilitar el monitoreo y gestión de apiarios de manera eficiente y moderna.",
              style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: GoogleFonts.poppins(
                color: Colors.amber[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
