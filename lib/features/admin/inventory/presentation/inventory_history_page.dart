import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:sotfbee/features/admin/inventory/models/inventory_exit.dart';
import 'package:sotfbee/features/admin/inventory/widgets/error_widget.dart';
import 'package:sotfbee/features/admin/inventory/widgets/loading_widget.dart';

// Enum para definir los tipos de pantalla
enum ScreenType { mobile, tablet, desktop }

// Clase para manejar breakpoints responsivos
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1200;

  static ScreenType getScreenType(double width) {
    if (width < mobile) return ScreenType.mobile;
    if (width < desktop) return ScreenType.tablet;
    return ScreenType.desktop;
  }
}

// Widget responsivo principal
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveBreakpoints.getScreenType(
          constraints.maxWidth,
        );

        switch (screenType) {
          case ScreenType.mobile:
            return mobile;
          case ScreenType.tablet:
            return tablet ?? desktop;
          case ScreenType.desktop:
            return desktop;
        }
      },
    );
  }
}

class HistorialSalidasUpdated extends StatefulWidget {
  @override
  _HistorialSalidasUpdatedState createState() =>
      _HistorialSalidasUpdatedState();
}

class _HistorialSalidasUpdatedState extends State<HistorialSalidasUpdated>
    with SingleTickerProviderStateMixin {
  // Lista de salidas (por ahora mock data, luego conectar con backend)
  List<InventoryExit> _salidas = [
    InventoryExit(
      id: 1,
      insumoId: 1,
      nombreInsumo: 'Traje de apicultor',
      cantidad: 1,
      persona: 'Juan Pérez',
      fecha: DateTime.now().subtract(Duration(hours: 2)),
    ),
    InventoryExit(
      id: 2,
      insumoId: 2,
      nombreInsumo: 'Guantes de protección',
      cantidad: 2,
      persona: 'María García',
      fecha: DateTime.now().subtract(Duration(hours: 5)),
    ),
    InventoryExit(
      id: 3,
      insumoId: 3,
      nombreInsumo: 'Ahumador',
      cantidad: 1,
      persona: 'Carlos López',
      fecha: DateTime.now().subtract(Duration(days: 1)),
    ),
  ];

  TextEditingController searchController = TextEditingController();
  late AnimationController _animationController;
  String filtroSeleccionado = 'todos'; // todos, hoy, semana, mes
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _animationController.forward();
    // TODO: Aquí cargarías las salidas desde el backend
    // _loadExitHistory();
  }

  @override
  void dispose() {
    searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // TODO: Implementar carga desde backend
  Future<void> _loadExitHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Aquí harías la llamada al backend para obtener el historial
      // final exits = await _exitService.getExitHistory();

      setState(() {
        // _salidas = exits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<InventoryExit> get salidasFiltradas {
    List<InventoryExit> salidas = _salidas;

    if (searchController.text.isNotEmpty) {
      salidas = salidas.where((salida) {
        return salida.nombreInsumo.toLowerCase().contains(
              searchController.text.toLowerCase(),
            ) ||
            salida.persona.toLowerCase().contains(
              searchController.text.toLowerCase(),
            );
      }).toList();
    }

    DateTime ahora = DateTime.now();
    switch (filtroSeleccionado) {
      case 'hoy':
        salidas = salidas.where((salida) {
          return salida.fecha.year == ahora.year &&
              salida.fecha.month == ahora.month &&
              salida.fecha.day == ahora.day;
        }).toList();
        break;
      case 'semana':
        DateTime inicioSemana = ahora.subtract(Duration(days: 7));
        salidas = salidas.where((salida) {
          return salida.fecha.isAfter(inicioSemana);
        }).toList();
        break;
      case 'mes':
        DateTime inicioMes = DateTime(ahora.year, ahora.month, 1);
        salidas = salidas.where((salida) {
          return salida.fecha.isAfter(inicioMes);
        }).toList();
        break;
    }

    return salidas;
  }

  Map<String, dynamic> get estadisticas {
    final salidas = salidasFiltradas;
    final totalSalidas = salidas.length;
    final insumosUnicos = salidas.map((s) => s.nombreInsumo).toSet().length;
    final personasUnicas = salidas.map((s) => s.persona).toSet().length;

    return {
      'totalSalidas': totalSalidas,
      'insumosUnicos': insumosUnicos,
      'personasUnicas': personasUnicas,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: LoadingWidget(message: 'Cargando historial...'));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: ErrorDisplayWidget(
          message: _errorMessage!,
          onRetry: _loadExitHistory,
        ),
      );
    }

    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  // Layout para móviles
  Widget _buildMobileLayout() {
    final stats = estadisticas;

    return Container(
      color: Color(0xFFFFF8E1),
      child: Column(
        children: [
          _buildHeader(ScreenType.mobile),
          _buildEstadisticas(stats, ScreenType.mobile),
          _buildFiltrosYBusqueda(ScreenType.mobile),
          SizedBox(height: 16),
          Expanded(child: _buildListaSalidas(ScreenType.mobile)),
        ],
      ),
    );
  }

  // Layout para tablets
  Widget _buildTabletLayout() {
    final stats = estadisticas;

    return Container(
      color: Color(0xFFFFF8E1),
      child: Column(
        children: [
          _buildHeader(ScreenType.tablet),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel lateral con estadísticas
                  Container(width: 280, child: _buildSidePanel(stats)),
                  SizedBox(width: 16),
                  // Contenido principal
                  Expanded(
                    child: Column(
                      children: [
                        _buildFiltrosYBusqueda(ScreenType.tablet),
                        SizedBox(height: 16),
                        Expanded(child: _buildListaSalidas(ScreenType.tablet)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Layout para desktop
  Widget _buildDesktopLayout() {
    final stats = estadisticas;

    return Container(
      color: Color(0xFFFFF8E1),
      child: Column(
        children: [
          _buildHeader(ScreenType.desktop),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel lateral con estadísticas
                  Container(width: 350, child: _buildSidePanel(stats)),
                  SizedBox(width: 24),
                  // Contenido principal
                  Expanded(
                    child: Column(
                      children: [
                        _buildFiltrosYBusqueda(ScreenType.desktop),
                        SizedBox(height: 24),
                        Expanded(child: _buildListaSalidas(ScreenType.desktop)),
                      ],
                    ),
                  ),
                  SizedBox(width: 24),
                  // Panel de análisis (solo desktop)
                  Container(width: 300, child: _buildAnalysisPanel()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header responsivo
  Widget _buildHeader(ScreenType screenType) {
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber, Colors.amber[600]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: isDesktop ? 28 : 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Salidas',
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop
                          ? 32
                          : isTablet
                          ? 28
                          : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Registro completo de movimientos',
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 16 : 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 12,
                vertical: isDesktop ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    color: Colors.amber[700],
                    size: isDesktop ? 20 : 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${_salidas.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Estadísticas responsivas
  Widget _buildEstadisticas(Map<String, dynamic> stats, ScreenType screenType) {
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;

    // En tablet y desktop, las estadísticas van en el panel lateral
    if (isTablet || isDesktop) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              '${stats['totalSalidas']}',
              Icons.exit_to_app,
              Colors.blue,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Insumos',
              '${stats['insumosUnicos']}',
              Icons.inventory_2,
              Colors.green,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Personas',
              '${stats['personasUnicas']}',
              Icons.people,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // Panel lateral para tablet y desktop
  Widget _buildSidePanel(Map<String, dynamic> stats) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas del Período',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            _buildSummaryCard(
              'Total de Salidas',
              '${stats['totalSalidas']}',
              Icons.exit_to_app,
              Colors.blue,
            ),
            SizedBox(height: 12),
            _buildSummaryCard(
              'Insumos Diferentes',
              '${stats['insumosUnicos']}',
              Icons.inventory_2,
              Colors.green,
            ),
            SizedBox(height: 12),
            _buildSummaryCard(
              'Personas Involucradas',
              '${stats['personasUnicas']}',
              Icons.people,
              Colors.orange,
            ),
            SizedBox(height: 20),
            Text(
              'Filtro Activo',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.amber[700], size: 16),
                  SizedBox(width: 8),
                  Text(
                    _getFiltroTexto(),
                    style: GoogleFonts.poppins(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Panel de análisis para desktop
  Widget _buildAnalysisPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análisis de Actividad',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            _buildAnalysisItem(
              'Insumo más solicitado',
              _getInsumoMasSolicitado(),
            ),
            SizedBox(height: 16),
            _buildAnalysisItem('Persona más activa', _getPersonaMasActiva()),
            SizedBox(height: 16),
            _buildAnalysisItem(
              'Promedio diario',
              '${_getPromedioDiario().toStringAsFixed(1)} salidas',
            ),
            SizedBox(height: 24),
            Text(
              'Tendencias',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            _buildTrendItem(
              'Actividad reciente',
              _getTendenciaActividad(),
              _getTendenciaColor(),
            ),
          ],
        ),
      ),
    );
  }

  // Filtros y búsqueda responsivos
  Widget _buildFiltrosYBusqueda(ScreenType screenType) {
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;
    final padding = (isDesktop || isTablet) ? 0.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        children: [
          // Barra de búsqueda
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por insumo o persona...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.amber),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 20 : 16,
                  horizontal: 16,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: isDesktop ? 16 : 14),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          SizedBox(height: 16),
          // Filtros de tiempo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFiltroChip('todos', 'Todos'),
                SizedBox(width: 8),
                _buildFiltroChip('hoy', 'Hoy'),
                SizedBox(width: 8),
                _buildFiltroChip('semana', 'Esta semana'),
                SizedBox(width: 8),
                _buildFiltroChip('mes', 'Este mes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Lista de salidas responsiva
  Widget _buildListaSalidas(ScreenType screenType) {
    final salidasFiltradas = this.salidasFiltradas;
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;

    if (salidasFiltradas.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: (isDesktop || isTablet) ? 0 : 16,
      ),
      itemCount: salidasFiltradas.length,
      itemBuilder: (context, index) {
        return _buildSalidaCard(salidasFiltradas[index], index, screenType);
      },
    );
  }

  // Card de salida responsivo
  Widget _buildSalidaCard(
    InventoryExit salida,
    int index,
    ScreenType screenType,
  ) {
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;
    final isMobile = screenType == ScreenType.mobile;

    final cardMargin = isMobile
        ? EdgeInsets.only(bottom: 12)
        : isTablet
        ? EdgeInsets.only(bottom: 10)
        : EdgeInsets.only(bottom: 16);

    final cardPadding = isDesktop
        ? EdgeInsets.all(24)
        : isTablet
        ? EdgeInsets.all(16)
        : EdgeInsets.all(16);

    return Card(
          margin: cardMargin,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.amber[100]!),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.amber[50]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 12 : 8),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.exit_to_app,
                          color: Colors.amber[700],
                          size: isDesktop ? 24 : 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              salida.nombreInsumo,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: isDesktop ? 18 : 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: isDesktop ? 16 : 14,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  salida.persona,
                                  style: GoogleFonts.poppins(
                                    fontSize: isDesktop ? 14 : 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'x${salida.cantidad}',
                              style: GoogleFonts.poppins(
                                fontSize: isDesktop ? 14 : 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatearFecha(salida.fecha),
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 12 : 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isDesktop) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Registrado el ${_formatearFechaCompleta(salida.fecha)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: 600.ms,
          delay: Duration(milliseconds: index * 100),
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        );
  }

  // Widgets auxiliares
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String texto) {
    final isSelected = filtroSeleccionado == valor;

    return FilterChip(
      label: Text(
        texto,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.amber[700],
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          filtroSeleccionado = valor;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.amber,
      checkmarkColor: Colors.white,
      side: BorderSide(color: isSelected ? Colors.amber : Colors.amber[300]!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchController.text.isNotEmpty || filtroSeleccionado != 'todos'
                ? Icons.search_off
                : Icons.history,
            size: 64,
            color: Colors.amber[300],
          ),
          SizedBox(height: 16),
          Text(
            searchController.text.isNotEmpty || filtroSeleccionado != 'todos'
                ? 'No se encontraron salidas'
                : 'No hay salidas registradas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            searchController.text.isNotEmpty || filtroSeleccionado != 'todos'
                ? 'Intenta con otros filtros o términos de búsqueda'
                : 'Las salidas aparecerán aquí cuando se registren',
            style: GoogleFonts.poppins(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                searchController.clear();
                filtroSeleccionado = 'todos';
              });
            },
            icon: Icon(Icons.refresh),
            label: Text('Mostrar todo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // Métodos auxiliares
  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      return DateFormat('HH:mm').format(fecha);
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return '${diferencia.inDays} días';
    } else {
      return DateFormat('dd/MM').format(fecha);
    }
  }

  String _formatearFechaCompleta(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  String _getFiltroTexto() {
    switch (filtroSeleccionado) {
      case 'hoy':
        return 'Hoy';
      case 'semana':
        return 'Esta semana';
      case 'mes':
        return 'Este mes';
      default:
        return 'Todos los registros';
    }
  }

  String _getInsumoMasSolicitado() {
    if (salidasFiltradas.isEmpty) return 'Sin datos';

    Map<String, int> conteo = {};
    for (var salida in salidasFiltradas) {
      conteo[salida.nombreInsumo] = (conteo[salida.nombreInsumo] ?? 0) + 1;
    }

    var entrada = conteo.entries.reduce((a, b) => a.value > b.value ? a : b);
    return entrada.key;
  }

  String _getPersonaMasActiva() {
    if (salidasFiltradas.isEmpty) return 'Sin datos';

    Map<String, int> conteo = {};
    for (var salida in salidasFiltradas) {
      conteo[salida.persona] = (conteo[salida.persona] ?? 0) + 1;
    }

    var entrada = conteo.entries.reduce((a, b) => a.value > b.value ? a : b);
    return entrada.key;
  }

  double _getPromedioDiario() {
    if (salidasFiltradas.isEmpty) return 0.0;

    final fechas = salidasFiltradas.map((s) => s.fecha).toList();
    final fechaMin = fechas.reduce((a, b) => a.isBefore(b) ? a : b);
    final fechaMax = fechas.reduce((a, b) => a.isAfter(b) ? a : b);

    final dias = fechaMax.difference(fechaMin).inDays + 1;
    return salidasFiltradas.length / dias;
  }

  String _getTendenciaActividad() {
    final promedio = _getPromedioDiario();
    if (promedio >= 2) return 'Alta actividad';
    if (promedio >= 1) return 'Actividad moderada';
    return 'Baja actividad';
  }

  Color _getTendenciaColor() {
    final promedio = _getPromedioDiario();
    if (promedio >= 2) return Colors.red;
    if (promedio >= 1) return Colors.orange;
    return Colors.green;
  }
}
