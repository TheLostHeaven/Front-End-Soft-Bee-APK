import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:sotfbee/features/admin/monitoring/service/enhaced_api_service.dart';
import '../models/enhanced_models.dart';

class ColmenasManagementScreen extends StatefulWidget {
  const ColmenasManagementScreen({Key? key}) : super(key: key);

  @override
  _ColmenasManagementScreenState createState() => _ColmenasManagementScreenState();
}

class _ColmenasManagementScreenState extends State<ColmenasManagementScreen>
    with SingleTickerProviderStateMixin {
  // Controladores
  final TextEditingController _numeroColmenaController = TextEditingController();
  final TextEditingController _cuadrosAlimentoController = TextEditingController();
  final TextEditingController _cuadrosCriaController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Estado
  List<Colmena> colmenas = [];
  List<Colmena> filteredColmenas = [];
  List<Apiario> apiarios = [];
  bool isLoading = true;
  bool isConnected = false;
  Colmena? editingColmena;

  // Valores del formulario
  int? selectedApiarioId;
  String? nivelActividad;
  String? poblacionAbejas;
  String? estadoColmena;
  String? estadoSalud;
  String? camaraProduccion;

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
      apiarios = await EnhancedApiService.obtenerApiarios();
      // Cargar colmenas de todos los apiarios
      List<Colmena> todasColmenas = [];
      for (var apiario in apiarios) {
        final colmenasApiario = await EnhancedApiService.obtenerColmenas(apiario.id);
        todasColmenas.addAll(colmenasApiario);
      }
      colmenas = todasColmenas;
      _filterColmenas();
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error al cargar datos: $e");
      // Datos de ejemplo para desarrollo
      apiarios = [
        Apiario(id: 1, nombre: "Apiario Norte", ubicacion: "Sector La Montaña"),
        Apiario(id: 2, nombre: "Apiario Sur", ubicacion: "Valle del Río"),
      ];
      colmenas = [
        Colmena(
          id: 1,
          numeroColmena: 1,
          idApiario: 1,
          metadatos: {
            'nivel_actividad': 'Alta',
            'poblacion_abejas': 'Alta',
            'cuadros_alimento': 8,
            'cuadros_cria': 6,
            'estado_colmena': 'Cámara de cría y producción',
            'estado_salud': 'Ninguno',
            'camara_produccion': 'Si',
            'observaciones': 'Colmena en excelente estado',
          },
        ),
        Colmena(
          id: 2,
          numeroColmena: 2,
          idApiario: 1,
          metadatos: {
            'nivel_actividad': 'Media',
            'poblacion_abejas': 'Media',
            'cuadros_alimento': 6,
            'cuadros_cria': 4,
            'estado_colmena': 'Cámara de cría',
            'estado_salud': 'Presencia barroa',
            'camara_produccion': 'No',
            'observaciones': 'Requiere tratamiento para varroa',
          },
        ),
      ];
      _filterColmenas();
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

  void _filterColmenas() {
    final query = _searchController.text.toLowerCase();
    filteredColmenas = colmenas.where((colmena) {
      final apiarioNombre = apiarios
          .firstWhere(
            (a) => a.id == colmena.idApiario,
            orElse: () => Apiario(id: 0, nombre: '', ubicacion: ''),
          )
          .nombre
          .toLowerCase();

      return colmena.numeroColmena.toString().contains(query) ||
          apiarioNombre.contains(query) ||
          (colmena.metadatos?['observaciones']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  void dispose() {
    _numeroColmenaController.dispose();
    _cuadrosAlimentoController.dispose();
    _cuadrosCriaController.dispose();
    _observacionesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Colmenas',
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
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showColmenaDialog(),
          )
          .animate()
          .fadeIn(delay: 400.ms, duration: 400.ms)
          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
        ],
      ),
      backgroundColor: const Color(0xFFF9F8F6),
      body: isLoading
          ? _buildLoadingWidget()
          : SafeArea(
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

                        _buildSearchSection(isDesktop, isTablet)
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),

                        SizedBox(height: isDesktop ? 32 : 20),

                        _buildColmenasSection(isDesktop, isTablet)
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            "Cargando colmenas...",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.amber[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
                child: Icon(
                  Icons.hive,
                  size: isDesktop ? 40 : 32,
                  color: Colors.amber[700],
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .rotate(begin: -0.05, end: 0.05, duration: 2000.ms),
              ),
              SizedBox(width: isDesktop ? 24 : 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Gestión de Colmenas',
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 28 : (isTablet ? 26 : 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Administra todas tus colmenas',
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
                  icon: Icons.hive_outlined,
                  label: 'Total Colmenas',
                  value: colmenas.length.toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.trending_up_outlined,
                  label: 'Alta Actividad',
                  value: colmenas
                      .where((c) => c.metadatos?['nivel_actividad'] == 'Alta')
                      .length
                      .toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.home_work_outlined,
                  label: 'Con Producción',
                  value: colmenas
                      .where((c) => c.metadatos?['camara_produccion'] == 'Si')
                      .length
                      .toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.favorite_outline,
                  label: 'Saludables',
                  value: colmenas
                      .where((c) => c.metadatos?['estado_salud'] == 'Ninguno')
                      .length
                      .toString(),
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
                  icon: Icons.hive_outlined,
                  label: 'Total Colmenas',
                  value: colmenas.length.toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.trending_up_outlined,
                  label: 'Alta Actividad',
                  value: colmenas
                      .where((c) => c.metadatos?['nivel_actividad'] == 'Alta')
                      .length
                      .toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.home_work_outlined,
                  label: 'Con Producción',
                  value: colmenas
                      .where((c) => c.metadatos?['camara_produccion'] == 'Si')
                      .length
                      .toString(),
                  isDesktop: isDesktop,
                ),
                _buildHeaderStat(
                  icon: Icons.favorite_outline,
                  label: 'Saludables',
                  value: colmenas
                      .where((c) => c.metadatos?['estado_salud'] == 'Ninguno')
                      .length
                      .toString(),
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

  Widget _buildSearchSection(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        _buildSectionTitle('Buscar Colmenas', Icons.search_outlined, isDesktop),
        SizedBox(height: isDesktop ? 16 : 12),
        _buildSearchCard(isDesktop, isTablet),
      ],
    );
  }

  Widget _buildSearchCard(bool isDesktop, bool isTablet) {
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 12 : 8),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
            ),
            child: Icon(
              Icons.search,
              color: Colors.amber[700],
              size: isDesktop ? 24 : 20,
            ),
          ),
          SizedBox(width: isDesktop ? 20 : 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por número, apiario u observaciones...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: isDesktop ? 16 : 14,
                  color: Colors.black54,
                ),
                border: InputBorder.none,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterColmenas();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 16 : 14,
                color: Colors.black87,
              ),
              onChanged: (value) {
                _filterColmenas();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColmenasSection(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Colmenas', Icons.hive_outlined, isDesktop),
            ElevatedButton.icon(
              onPressed: () => _showColmenaDialog(),
              icon: const Icon(Icons.add),
              label: Text(
                'Nueva Colmena',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        _buildColmenasList(isDesktop, isTablet),
      ],
    );
  }

  Widget _buildColmenasList(bool isDesktop, bool isTablet) {
    if (filteredColmenas.isEmpty) {
      return _buildEmptyState(isDesktop);
    }

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: filteredColmenas.length,
        itemBuilder: (context, index) {
          return _buildColmenaCard(
            filteredColmenas[index],
            index,
            isDesktop,
            isTablet,
          );
        },
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredColmenas.length,
        separatorBuilder: (context, index) => SizedBox(height: isTablet ? 12 : 8),
        itemBuilder: (context, index) {
          return _buildColmenaCard(
            filteredColmenas[index],
            index,
            isDesktop,
            isTablet,
          );
        },
      );
    }
  }

  Widget _buildEmptyState(bool isDesktop) {
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
          Icon(Icons.hive, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron colmenas'
                : 'No hay colmenas configuradas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Agrega tu primera colmena para comenzar',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showColmenaDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Crear Colmena'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColmenaCard(
    Colmena colmena,
    int index,
    bool isDesktop,
    bool isTablet,
  ) {
    final apiario = apiarios.firstWhere(
      (a) => a.id == colmena.idApiario,
      orElse: () => Apiario(id: 0, nombre: 'Desconocido', ubicacion: ''),
    );

    final nivelActividad = colmena.metadatos?['nivel_actividad'] ?? 'Media';
    final estadoSalud = colmena.metadatos?['estado_salud'] ?? 'Ninguno';
    final camaraProduccion = colmena.metadatos?['camara_produccion'] ?? 'No';
    final cuadrosAlimento = colmena.metadatos?['cuadros_alimento'] ?? 0;
    final cuadrosCria = colmena.metadatos?['cuadros_cria'] ?? 0;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la colmena
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 12 : 8),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
                ),
                child: Icon(
                  Icons.hive,
                  color: Colors.amber[700],
                  size: isDesktop ? 24 : 20,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Colmena #${colmena.numeroColmena}',
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      apiario.nombre,
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 14 : 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showColmenaDialog(colmena: colmena);
                      break;
                    case 'delete':
                      _confirmDelete(colmena);
                      break;
                    case 'details':
                      _showColmenaDetails(colmena);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: Colors.amber[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text('Editar', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          color: Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text('Ver Detalles', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text('Eliminar', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          Divider(height: isDesktop ? 32 : 24),

          // Información de la colmena
          _buildInfoRow(
            Icons.trending_up_outlined,
            'Nivel de Actividad:',
            nivelActividad,
            iconColor: _getActivityColor(nivelActividad),
            isDesktop: isDesktop,
          ),

          Divider(height: isDesktop ? 24 : 16),

          _buildInfoRow(
            Icons.favorite_outline,
            'Estado de Salud:',
            estadoSalud,
            iconColor: _getHealthColor(estadoSalud),
            isHighlight: estadoSalud != 'Ninguno',
            isDesktop: isDesktop,
          ),

          Divider(height: isDesktop ? 24 : 16),

          _buildInfoRow(
            Icons.home_work_outlined,
            'Cámara de Producción:',
            camaraProduccion,
            iconColor: camaraProduccion == 'Si'
                ? Colors.green[700]!
                : Colors.grey[600]!,
            isDesktop: isDesktop,
          ),

          if (isDesktop) ...[
            Divider(height: 24),

            // Indicadores de cuadros
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Cuadros de Alimento',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      CircularPercentIndicator(
                        radius: 30,
                        lineWidth: 6,
                        percent: (cuadrosAlimento / 10).clamp(0.0, 1.0),
                        center: Text(
                          cuadrosAlimento.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        progressColor: Colors.blue[600],
                        backgroundColor: Colors.grey[200]!,
                        animation: true,
                        animationDuration: 1000,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Cuadros de Cría',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      CircularPercentIndicator(
                        radius: 30,
                        lineWidth: 6,
                        percent: (cuadrosCria / 10).clamp(0.0, 1.0),
                        center: Text(
                          cuadrosCria.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                        progressColor: Colors.orange[600],
                        backgroundColor: Colors.grey[200]!,
                        animation: true,
                        animationDuration: 1000,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: isDesktop ? 24 : 16),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showColmenaDetails(colmena),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: Text(
                    'Ver Detalles',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: isDesktop ? 14 : 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[100],
                    foregroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 12 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showColmenaDialog(colmena: colmena),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(
                    'Editar',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: isDesktop ? 14 : 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[100],
                    foregroundColor: Colors.amber[700],
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 12 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(
      delay: Duration(milliseconds: 100 * index),
      duration: 600.ms,
    )
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    required Color iconColor,
    bool isHighlight = false,
    required bool isDesktop,
  }) {
    return Row(
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
                label,
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 16 : 14,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? Colors.red[700] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(String nivel) {
    switch (nivel) {
      case 'Alta':
        return Colors.green[700]!;
      case 'Media':
        return Colors.amber[700]!;
      case 'Baja':
        return Colors.red[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Color _getHealthColor(String estado) {
    return estado == 'Ninguno' ? Colors.green[700]! : Colors.red[700]!;
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

  // Diálogo para crear/editar colmena
  void _showColmenaDialog({Colmena? colmena}) {
    final isEditing = colmena != null;

    if (isEditing) {
      _numeroColmenaController.text = colmena.numeroColmena.toString();
      selectedApiarioId = colmena.idApiario;
      nivelActividad = colmena.metadatos?['nivel_actividad'];
      poblacionAbejas = colmena.metadatos?['poblacion_abejas'];
      _cuadrosAlimentoController.text =
          colmena.metadatos?['cuadros_alimento']?.toString() ?? '';
      _cuadrosCriaController.text =
          colmena.metadatos?['cuadros_cria']?.toString() ?? '';
      estadoColmena = colmena.metadatos?['estado_colmena'];
      estadoSalud = colmena.metadatos?['estado_salud'];
      camaraProduccion = colmena.metadatos?['camara_produccion'];
      _observacionesController.text =
          colmena.metadatos?['observaciones']?.toString() ?? '';
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[600],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isEditing ? Icons.edit : Icons.add_circle,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Editar Colmena' : 'Nueva Colmena',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        titlePadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                // Número de colmena
                TextField(
                  controller: _numeroColmenaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Número de Colmena',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.amber[600]!,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(Icons.numbers, color: Colors.amber[600]),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 16),
                // Apiario
                DropdownButtonFormField<int>(
                  value: selectedApiarioId,
                  decoration: InputDecoration(
                    labelText: 'Apiario',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.amber[600]!,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: Colors.amber[600],
                    ),
                  ),
                  items: apiarios.map((apiario) {
                    return DropdownMenuItem<int>(
                      value: apiario.id,
                      child: Text(apiario.nombre, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedApiarioId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Nivel de actividad
                DropdownButtonFormField<String>(
                  value: nivelActividad,
                  decoration: InputDecoration(
                    labelText: 'Nivel de Actividad',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.amber[600]!,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.trending_up,
                      color: Colors.amber[600],
                    ),
                  ),
                  items: ['Baja', 'Media', 'Alta'].map((nivel) {
                    return DropdownMenuItem<String>(
                      value: nivel,
                      child: Text(nivel, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      nivelActividad = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Población de abejas
                DropdownButtonFormField<String>(
                  value: poblacionAbejas,
                  decoration: InputDecoration(
                    labelText: 'Población de Abejas',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.amber[600]!,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(Icons.groups, color: Colors.amber[600]),
                  ),
                  items: ['Baja', 'Media', 'Alta'].map((poblacion) {
                    return DropdownMenuItem<String>(
                      value: poblacion,
                      child: Text(poblacion, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      poblacionAbejas = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Cuadros de alimento y cría
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cuadrosAlimentoController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cuadros Alimento',
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.amber[600]!,
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.restaurant,
                            color: Colors.amber[600],
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _cuadrosCriaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cuadros Cría',
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.amber[600]!,
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.child_care,
                            color: Colors.amber[600],
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Estado de la colmena
                DropdownButtonFormField<String>(
                  value: estadoColmena,
                  decoration: InputDecoration(
                    labelText: 'Estado de la Colmena',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.amber[600]!,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(Icons.home, color: Colors.amber[600]),
                  ),
                  items: [
                    'Cámara de cría',
                    'Cámara de cría y producción',
                    'Cámara de cría y doble alza de producción',
                  ].map((estado) {
                    return DropdownMenuItem<String>(
                      value: estado,
                      child: Text(
                        estado,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      estadoColmena = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Estado de salud
                DropdownButtonFormField<String>(
                  value: estadoSalud,
                  decoration: InputDecoration(
                    labelText: 'Estado de Salud',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.amber[600]!,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.health_and_safety,
                      color: Colors.amber[600],
                    ),
                  ),
                  items: [
                    'Ninguno',
                    'Presencia barroa',
                    'Presencia de polilla',
                    'Presencia de curruncho',
                    'Mortalidad- malformación en nodrizas',
                  ].map((estado) {
                    return DropdownMenuItem<String>(
                      value: estado,
                      child: Text(
                        estado,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      estadoSalud = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Cámara de producción
                DropdownButtonFormField<String>(
                  value: camaraProduccion,
                  decoration: InputDecoration(
                    labelText: 'Cámara de Producción',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.amber[600]!,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(Icons.factory, color: Colors.amber[600]),
                  ),
                  items: ['Si', 'No'].map((opcion) {
                    return DropdownMenuItem<String>(
                      value: opcion,
                      child: Text(opcion, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      camaraProduccion = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Observaciones
                TextField(
                  controller: _observacionesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Observaciones',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.amber[600]!,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(Icons.note, color: Colors.amber[600]),
                  ),
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _saveColmena(colmena),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Actualizar' : 'Crear',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        actionsPadding: EdgeInsets.zero,
      ),
    );
  }

  void _clearForm() {
    _numeroColmenaController.clear();
    _cuadrosAlimentoController.clear();
    _cuadrosCriaController.clear();
    _observacionesController.clear();
    selectedApiarioId = null;
    nivelActividad = null;
    poblacionAbejas = null;
    estadoColmena = null;
    estadoSalud = null;
    camaraProduccion = null;
  }

  // Guardar colmena
  Future<void> _saveColmena(Colmena? existingColmena) async {
    if (_numeroColmenaController.text.trim().isEmpty ||
        selectedApiarioId == null) {
      _showSnackBar('Por favor completa los campos obligatorios', Colors.red);
      return;
    }

    try {
      Navigator.pop(context);

      final colmenaData = {
        'hive_number': int.parse(_numeroColmenaController.text.trim()),
        'apiary_id': selectedApiarioId,
        'activity_level': nivelActividad,
        'bee_population': poblacionAbejas,
        'food_frames': _cuadrosAlimentoController.text.isNotEmpty
            ? int.parse(_cuadrosAlimentoController.text)
            : 0,
        'brood_frames': _cuadrosCriaController.text.isNotEmpty
            ? int.parse(_cuadrosCriaController.text)
            : 0,
        'hive_status': estadoColmena,
        'health_status': estadoSalud,
        'has_production_chamber': camaraProduccion,
        'observations': _observacionesController.text.trim(),
      };

      if (existingColmena != null) {
        // Actualizar colmena existente
        await EnhancedApiService.actualizarColmena(
          existingColmena.id,
          colmenaData,
        );
        _showSnackBar('Colmena actualizada correctamente', Colors.green);
      } else {
        // Crear nueva colmena
        await EnhancedApiService.crearColmena(colmenaData);
        _showSnackBar('Colmena creada correctamente', Colors.green);
      }

      await _loadData();
    } catch (e) {
      _showSnackBar('Error al guardar: $e', Colors.red);
      debugPrint('Error al guardar colmena: $e');
    }
  }

  // Confirmar eliminación
  void _confirmDelete(Colmena colmena) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirmar Eliminación',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la colmena #${colmena.numeroColmena}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteColmena(colmena),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Eliminar colmena
  Future<void> _deleteColmena(Colmena colmena) async {
    try {
      Navigator.pop(context);
      await EnhancedApiService.eliminarColmena(colmena.id);
      _showSnackBar('Colmena eliminada correctamente', Colors.green);
      await _loadData();
    } catch (e) {
      _showSnackBar('Error al eliminar: $e', Colors.red);
    }
  }

  // Mostrar detalles de la colmena
  void _showColmenaDetails(Colmena colmena) {
    final apiario = apiarios.firstWhere(
      (a) => a.id == colmena.idApiario,
      orElse: () => Apiario(id: 0, nombre: 'Desconocido', ubicacion: ''),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Colmena #${colmena.numeroColmena}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Apiario:', apiario.nombre),
              _buildDetailRow('ID:', colmena.id.toString()),
              _buildDetailRow(
                'Nivel de Actividad:',
                colmena.metadatos?['nivel_actividad'] ?? 'N/A',
              ),
              _buildDetailRow(
                'Población de Abejas:',
                colmena.metadatos?['poblacion_abejas'] ?? 'N/A',
              ),
              _buildDetailRow(
                'Cuadros de Alimento:',
                colmena.metadatos?['cuadros_alimento']?.toString() ?? '0',
              ),
              _buildDetailRow(
                'Cuadros de Cría:',
                colmena.metadatos?['cuadros_cria']?.toString() ?? '0',
              ),
              _buildDetailRow(
                'Estado de la Colmena:',
                colmena.metadatos?['estado_colmena'] ?? 'N/A',
              ),
              _buildDetailRow(
                'Estado de Salud:',
                colmena.metadatos?['estado_salud'] ?? 'N/A',
              ),
              _buildDetailRow(
                'Cámara de Producción:',
                colmena.metadatos?['camara_produccion'] ?? 'N/A',
              ),
              if (colmena.metadatos?['observaciones'] != null &&
                  colmena.metadatos!['observaciones'].toString().isNotEmpty)
                _buildDetailRow(
                  'Observaciones:',
                  colmena.metadatos!['observaciones'].toString(),
                ),
              _buildDetailRow(
                'Fecha de creación:',
                colmena.fechaCreacion?.toString().split(' ')[0] ?? 'N/A',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(color: Colors.amber[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showColmenaDialog(colmena: colmena);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Editar',
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
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  // Sincronizar datos
  Future<void> _syncData() async {
    try {
      _showSnackBar("Sincronizando colmenas...", Colors.amber[600]!);
      await _checkConnection();
      await _loadData();
      _showSnackBar("Colmenas sincronizadas correctamente", Colors.green);
    } catch (e) {
      _showSnackBar("Error en sincronización: $e", Colors.red);
    }
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