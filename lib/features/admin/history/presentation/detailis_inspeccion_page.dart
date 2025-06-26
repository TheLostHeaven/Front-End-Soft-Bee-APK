import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:provider/provider.dart';
import 'package:sotfbee/features/admin/history/models/monitoreo_models.dart';

class InspeccionDetalleScreenModified extends StatefulWidget {
  final MonitoreoModel monitoreo;

  const InspeccionDetalleScreenModified({
    Key? key,
    required this.monitoreo,
  }) : super(key: key);

  @override
  _InspeccionDetalleScreenModifiedState createState() =>
      _InspeccionDetalleScreenModifiedState();
}

class _InspeccionDetalleScreenModifiedState 
    extends State<InspeccionDetalleScreenModified>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showingBarChart = false;
  bool _showingLineChart = false;
  
  // Datos dinámicos generados desde las respuestas
  Map<String, dynamic> _chartData = {};
  Map<String, dynamic> _estadisticas = {};
  List<Map<String, dynamic>> _colmenasData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _processMonitoreoData();

    // Delayed animations for charts
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showingLineChart = true;
        });
      }
    });

    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showingBarChart = true;
        });
      }
    });
  }

  void _processMonitoreoData() {
    // Procesar respuestas para generar datos de gráficas
    _chartData = widget.monitoreo.generateChartData();
    _generateEstadisticas();
    _generateColmenasData();
  }

  void _generateEstadisticas() {
    // Generar estadísticas basadas en las respuestas
    double produccionTotal = 0;
    double saludPromedio = 0;
    int poblacionTotal = 0;
    int contadorSalud = 0;
    int contadorProduccion = 0;

    for (final respuesta in widget.monitoreo.respuestas) {
      switch (respuesta.preguntaId.toLowerCase()) {
        case 'produccion_miel':
        case 'miel_producida':
        case 'cosecha_miel':
          double? valor = double.tryParse(respuesta.respuesta);
          if (valor != null) {
            produccionTotal += valor;
            contadorProduccion++;
          }
          break;
        case 'estado_salud':
        case 'salud_colmena':
        case 'condicion_general':
          if (respuesta.tipoRespuesta == 'number') {
            double? valor = double.tryParse(respuesta.respuesta);
            if (valor != null) {
              saludPromedio += valor;
              contadorSalud++;
            }
          } else if (respuesta.tipoRespuesta == 'option') {
            // Convertir respuestas de opción a valores numéricos
            double valor = _convertOptionToNumber(respuesta.respuesta);
            saludPromedio += valor;
            contadorSalud++;
          }
          break;
        case 'poblacion_estimada':
        case 'numero_abejas':
        case 'poblacion_colmena':
          int? valor = int.tryParse(respuesta.respuesta);
          if (valor != null) {
            poblacionTotal += valor;
          }
          break;
      }
    }

    _estadisticas = {
      'produccion_total': produccionTotal,
      'produccion_promedio': contadorProduccion > 0 ? produccionTotal / contadorProduccion : 0,
      'salud_promedio': contadorSalud > 0 ? saludPromedio / contadorSalud : 75,
      'poblacion_total': poblacionTotal,
      'tendencia': _calculateTendencia(produccionTotal),
    };
  }

  double _convertOptionToNumber(String option) {
    switch (option.toLowerCase()) {
      case 'excelente':
      case 'muy bueno':
        return 90;
      case 'bueno':
      case 'normal':
        return 75;
      case 'regular':
      case 'aceptable':
        return 60;
      case 'malo':
      case 'deficiente':
        return 40;
      case 'muy malo':
      case 'crítico':
        return 20;
      default:
        return 75;
    }
  }

  String _calculateTendencia(double produccionActual) {
    // Lógica simple para calcular tendencia
    // En una implementación real, compararías con datos históricos
    if (produccionActual > 15) return '+15%';
    if (produccionActual > 10) return '+8%';
    if (produccionActual > 5) return '+3%';
    return '-2%';
  }

  void _generateColmenasData() {
    // Generar datos de colmenas basados en las respuestas
    Map<String, Map<String, dynamic>> colmenasMap = {};

    for (final respuesta in widget.monitoreo.respuestas) {
      String colmenaKey = 'Colmena ${widget.monitoreo.numeroColmena ?? 1}';
      
      if (!colmenasMap.containsKey(colmenaKey)) {
        colmenasMap[colmenaKey] = {
          'name': colmenaKey,
          'health': 75.0,
          'status': 'Saludable',
          'statusColor': Colors.green,
          'produccion': 0.0,
          'poblacion': 0,
          'reina_presente': true,
          'plagas_detectadas': false,
        };
      }

      // Actualizar datos según el tipo de respuesta
      switch (respuesta.preguntaId.toLowerCase()) {
        case 'estado_salud':
        case 'salud_colmena':
          if (respuesta.tipoRespuesta == 'number') {
            double? valor = double.tryParse(respuesta.respuesta);
            if (valor != null) {
              colmenasMap[colmenaKey]!['health'] = valor;
              _updateStatusFromHealth(colmenasMap[colmenaKey]!, valor);
            }
          } else {
            double valor = _convertOptionToNumber(respuesta.respuesta);
            colmenasMap[colmenaKey]!['health'] = valor;
            _updateStatusFromHealth(colmenasMap[colmenaKey]!, valor);
          }
          break;
        case 'produccion_miel':
          double? valor = double.tryParse(respuesta.respuesta);
          if (valor != null) {
            colmenasMap[colmenaKey]!['produccion'] = valor;
          }
          break;
        case 'poblacion_estimada':
          int? valor = int.tryParse(respuesta.respuesta);
          if (valor != null) {
            colmenasMap[colmenaKey]!['poblacion'] = valor;
          }
          break;
        case 'presencia_reina':
        case 'reina_presente':
          colmenasMap[colmenaKey]!['reina_presente'] = 
              respuesta.respuesta.toLowerCase().contains('sí') ||
              respuesta.respuesta.toLowerCase().contains('si') ||
              respuesta.respuesta.toLowerCase().contains('presente');
          break;
        case 'plagas_detectadas':
        case 'presencia_plagas':
          colmenasMap[colmenaKey]!['plagas_detectadas'] = 
              respuesta.respuesta.toLowerCase().contains('sí') ||
              respuesta.respuesta.toLowerCase().contains('si') ||
              respuesta.respuesta.toLowerCase().contains('detectadas');
          break;
      }
    }

    _colmenasData = colmenasMap.values.toList();
    
    // Si no hay datos específicos, crear datos por defecto
    if (_colmenasData.isEmpty) {
      _colmenasData = [
        {
          'name': 'Colmena ${widget.monitoreo.numeroColmena ?? 1}',
          'health': 80.0,
          'status': 'Saludable',
          'statusColor': Colors.green,
          'produccion': _estadisticas['produccion_total'] ?? 0.0,
          'poblacion': 15000,
          'reina_presente': true,
          'plagas_detectadas': false,
        }
      ];
    }
  }

  void _updateStatusFromHealth(Map<String, dynamic> colmena, double health) {
    if (health >= 80) {
      colmena['status'] = 'Excelente';
      colmena['statusColor'] = Colors.green;
    } else if (health >= 60) {
      colmena['status'] = 'Saludable';
      colmena['statusColor'] = Colors.green;
    } else if (health >= 40) {
      colmena['status'] = 'Requiere atención';
      colmena['statusColor'] = Colors.orange;
    } else {
      colmena['status'] = 'Crítico';
      colmena['statusColor'] = Colors.red;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1200;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        final isMobile = constraints.maxWidth <= 768;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else if (isTablet) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1600),
          child: Row(
            children: [
              Container(
                width: 400,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getStatusColor(_determineEstado()),
                      _getStatusColor(_determineEstado()).withOpacity(0.7),
                    ],
                  ),
                ),
                child: _buildSidebarContent(),
              ),
              Expanded(
                child: Container(
                  color: Colors.grey[50],
                  child: Column(
                    children: [
                      _buildDesktopTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildDesktopInfoTab(),
                            _buildDesktopProduccionTab(),
                            _buildDesktopColmenasTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: _getStatusColor(_determineEstado()),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Detalles de Inspección',
                  style: GoogleFonts.concertOne(
                    fontSize: 24,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                background: _buildTabletHeader(),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: _getStatusColor(_determineEstado()),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _getStatusColor(_determineEstado()),
                  labelStyle: GoogleFonts.poppins(fontSize: 16),
                  tabs: [
                    Tab(icon: Icon(Icons.info_outline, size: 28), text: "Información"),
                    Tab(icon: Icon(Icons.show_chart, size: 28), text: "Producción"),
                    Tab(icon: Icon(Icons.hive, size: 28), text: "Colmenas"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabletInfoTab(),
            _buildTabletProduccionTab(),
            _buildTabletColmenasTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        label: Text('Editar', style: GoogleFonts.poppins(fontSize: 16)),
        icon: Icon(Icons.edit, size: 24),
        backgroundColor: _getStatusColor(_determineEstado()),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: _getStatusColor(_determineEstado()),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Detalles de Inspección',
                  style: GoogleFonts.concertOne(
                    fontSize: 20,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                background: _buildMobileHeader(),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: _getStatusColor(_determineEstado()),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _getStatusColor(_determineEstado()),
                  tabs: [
                    Tab(icon: Icon(Icons.info_outline), text: "Información"),
                    Tab(icon: Icon(Icons.show_chart), text: "Producción"),
                    Tab(icon: Icon(Icons.hive), text: "Colmenas"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildProduccionTab(),
            _buildColmenasTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        label: Text('Editar', style: GoogleFonts.poppins()),
        icon: Icon(Icons.edit),
        backgroundColor: _getStatusColor(_determineEstado()),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildSidebarContent() {
    String estado = _determineEstado();
    String fechaFormateada = _formatFecha(widget.monitoreo.fecha);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(estado), size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        estado,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Text(
              'Inspección',
              style: GoogleFonts.concertOne(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Detalles Completos',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 40),
            _buildSidebarInfoCard('Fecha', fechaFormateada, Icons.calendar_today),
            SizedBox(height: 20),
            _buildSidebarInfoCard('Estado', estado, _getStatusIcon(estado)),
            SizedBox(height: 20),
            _buildSidebarInfoCard(
              'Apiario', 
              widget.monitoreo.apiarioNombre ?? 'Apiario ${widget.monitoreo.idApiario}', 
              Icons.location_on
            ),
            SizedBox(height: 20),
            _buildSidebarInfoCard(
              'Colmena', 
              'Colmena ${widget.monitoreo.numeroColmena ?? widget.monitoreo.idColmena}', 
              Icons.hive
            ),
            SizedBox(height: 40),
            Text(
              'Resumen de Respuestas',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: widget.monitoreo.respuestas.length,
                  itemBuilder: (context, index) {
                    final respuesta = widget.monitoreo.respuestas[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            respuesta.preguntaTexto,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            respuesta.respuesta,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          if (index < widget.monitoreo.respuestas.length - 1)
                            Divider(color: Colors.white.withOpacity(0.3), height: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  widget.monitoreo.sincronizado ? Icons.cloud_done : Icons.cloud_off,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  widget.monitoreo.sincronizado ? 'Sincronizado' : 'Pendiente de sincronización',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEditDialog(),
                icon: Icon(
                  Icons.edit,
                  color: _getStatusColor(estado),
                ),
                label: Text(
                  'Editar Inspección',
                  style: GoogleFonts.poppins(
                    color: _getStatusColor(estado),
                    fontWeight: FontWeight.w600, // ← Este iba fuera antes
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _getStatusColor(_determineEstado()),
        unselectedLabelColor: Colors.grey,
        indicatorColor: _getStatusColor(_determineEstado()),
        labelStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(icon: Icon(Icons.info_outline, size: 28), text: "Información"),
          Tab(icon: Icon(Icons.show_chart, size: 28), text: "Producción"),
          Tab(icon: Icon(Icons.hive, size: 28), text: "Colmenas"),
        ],
      ),
    );
  }

  Widget _buildDesktopInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información General',
              style: GoogleFonts.concertOne(
                fontSize: 28,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildClimateCard()),
                SizedBox(width: 24),
                Expanded(child: _buildAdditionalInfoCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopProduccionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análisis de Producción',
              style: GoogleFonts.concertOne(
                fontSize: 28,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AnimatedOpacity(
                    opacity: _showingLineChart ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 500),
                    child: _buildDesktopLineChart(),
                  ),
                ),
                SizedBox(width: 24),
                Expanded(child: _buildProduccionStats()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopColmenasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de las Colmenas',
              style: GoogleFonts.concertOne(
                fontSize: 28,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showingBarChart ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 500),
                    child: _buildDesktopBarChart(),
                  ),
                ),
                SizedBox(width: 24),
                Expanded(child: _buildColmenasList()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletHeader() {
    String estado = _determineEstado();
    String fechaFormateada = _formatFecha(widget.monitoreo.fecha);
    
    return Hero(
      tag: 'inspeccion_${widget.monitoreo.id}',
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getStatusColor(estado),
                  _getStatusColor(estado).withOpacity(0.7),
                ],
              ),
            ),
          ),
          Positioned(
            right: -80,
            bottom: -80,
            child: Opacity(
              opacity: 0.2,
              child: Icon(
                _getStatusIcon(estado),
                size: 300,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 80,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(estado), size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        estado,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        fechaFormateada,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    String estado = _determineEstado();
    
    return Hero(
      tag: 'inspeccion_${widget.monitoreo.id}',
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getStatusColor(estado),
                  _getStatusColor(estado).withOpacity(0.7),
                ],
              ),
            ),
          ),
          Positioned(
            right: -50,
            bottom: -50,
            child: Opacity(
              opacity: 0.2,
              child: Icon(
                _getStatusIcon(estado),
                size: 200,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 70,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(estado), size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    estado,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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

  Widget _buildTabletInfoTab() {
    String fechaFormateada = _formatFecha(widget.monitoreo.fecha);
    String estado = _determineEstado();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Fecha de Inspección',
                  fechaFormateada,
                  Icons.calendar_today,
                ).animate().fadeIn(duration: 300.ms).slideY(),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  'Estado General',
                  estado,
                  _getStatusIcon(estado),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildRespuestasCard()
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(),
          SizedBox(height: 20),
          _buildClimateCard()
              .animate()
              .fadeIn(duration: 600.ms, delay: 300.ms)
              .slideY(),
        ],
      ),
    );
  }

  Widget _buildTabletProduccionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Producción basada en respuestas del monitoreo'),
          SizedBox(height: 20),
          AnimatedOpacity(
            opacity: _showingLineChart ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: _buildTabletLineChart(),
          ),
          SizedBox(height: 24),
          _buildProduccionStats(),
        ],
      ),
    );
  }

  Widget _buildTabletColmenasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Estado de las colmenas evaluadas'),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  opacity: _showingBarChart ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: _buildTabletBarChart(),
                ),
              ),
              SizedBox(width: 24),
              Expanded(child: _buildColmenasList()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLineChart() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 800, maxHeight: 400),
      child: Container(
        height: 400,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: _buildLineChartContent(),
      ),
    );
  }

  Widget _buildTabletLineChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _buildLineChartContent(),
    );
  }

  Widget _buildDesktopBarChart() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 800, maxHeight: 400),
      child: Container(
        height: 400,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: _buildBarChartContent(),
      ),
    );
  }

  Widget _buildTabletBarChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _buildBarChartContent(),
    );
  }

  Widget _buildAdditionalInfoCard() {
    String fechaFormateada = _formatFecha(widget.monitoreo.fecha);
    
    return Card(
      elevation: 4,
      shadowColor: Colors.amber.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Monitoreo',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('ID Monitoreo', '${widget.monitoreo.id}'),
            _buildInfoRow('Apiario', widget.monitoreo.apiarioNombre ?? 'Apiario ${widget.monitoreo.idApiario}'),
            _buildInfoRow('Colmena', 'Colmena ${widget.monitoreo.numeroColmena ?? widget.monitoreo.idColmena}'),
            _buildInfoRow('Fecha', fechaFormateada),
            _buildInfoRow('Respuestas', '${widget.monitoreo.respuestas.length}'),
            _buildInfoRow('Estado Sync', widget.monitoreo.sincronizado ? 'Sincronizado' : 'Pendiente'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.brown[800],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    String fechaFormateada = _formatFecha(widget.monitoreo.fecha);
    String estado = _determineEstado();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Fecha de Inspección',
            fechaFormateada,
            Icons.calendar_today,
          ).animate().fadeIn(duration: 300.ms).slideY(),
          SizedBox(height: 16),
          _buildInfoCard(
            'Estado General',
            estado,
            _getStatusIcon(estado),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(),
          SizedBox(height: 16),
          _buildRespuestasCard()
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(),
          SizedBox(height: 16),
          _buildClimateCard()
              .animate()
              .fadeIn(duration: 600.ms, delay: 300.ms)
              .slideY(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shadowColor: Colors.amber.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(_determineEstado()).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: _getStatusColor(_determineEstado()),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
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

  Widget _buildRespuestasCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.amber.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_determineEstado()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.quiz,
                    color: _getStatusColor(_determineEstado()),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Respuestas del Monitoreo',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.monitoreo.respuestas.isEmpty
                  ? Text(
                      'No hay respuestas registradas para este monitoreo.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.brown[700],
                      ),
                    )
                  : Column(
                      children: widget.monitoreo.respuestas.map((respuesta) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                respuesta.preguntaTexto,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.brown[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                respuesta.respuesta,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.brown[700],
                                ),
                              ),
                              if (widget.monitoreo.respuestas.last != respuesta)
                                Divider(color: Colors.grey[300], height: 20),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClimateCard() {
    // Generar datos climáticos simulados o desde respuestas si están disponibles
    Map<String, String> climateData = _extractClimateData();
    
    return Card(
      elevation: 4,
      shadowColor: Colors.amber.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.cloud, color: Colors.blue, size: 24),
                ),
                SizedBox(width: 16),
                Text(
                  'Condiciones Ambientales',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildClimateItem('Temperatura', climateData['temperatura']!, Icons.thermostat),
                _buildClimateItem('Humedad', climateData['humedad']!, Icons.water_drop),
                _buildClimateItem('Viento', climateData['viento']!, Icons.air),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _extractClimateData() {
    // Buscar datos climáticos en las respuestas
    String temperatura = '24°C';
    String humedad = '65%';
    String viento = '5 km/h';
    
    for (final respuesta in widget.monitoreo.respuestas) {
      String pregunta = respuesta.preguntaId.toLowerCase();
      if (pregunta.contains('temperatura')) {
        temperatura = '${respuesta.respuesta}°C';
      } else if (pregunta.contains('humedad')) {
        humedad = '${respuesta.respuesta}%';
      } else if (pregunta.contains('viento')) {
        viento = '${respuesta.respuesta} km/h';
      }
    }
    
    return {
      'temperatura': temperatura,
      'humedad': humedad,
      'viento': viento,
    };
  }

  Widget _buildClimateItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProduccionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Producción basada en respuestas del monitoreo'),
          SizedBox(height: 16),
          AnimatedOpacity(
            opacity: _showingLineChart ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: _buildLineChart(),
          ),
          SizedBox(height: 24),
          _buildProduccionStats(),
        ],
      ),
    );
  }

  Widget _buildColmenasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Estado de las colmenas evaluadas'),
          SizedBox(height: 16),
          AnimatedOpacity(
            opacity: _showingBarChart ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: _buildBarChart(),
          ),
          SizedBox(height: 24),
          _buildColmenasList(),
        ],
      ),
    );
  }

  Widget _buildProduccionStats() {
    return Card(
      elevation: 4,
      shadowColor: Colors.amber.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Producción',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn(
                  'Total', 
                  '${_estadisticas['produccion_total']?.toStringAsFixed(1) ?? '0'} kg', 
                  Colors.amber
                ),
                _buildStatColumn(
                  'Promedio', 
                  '${_estadisticas['produccion_promedio']?.toStringAsFixed(1) ?? '0'} kg', 
                  Colors.orange
                ),
                _buildStatColumn(
                  'Tendencia', 
                  _estadisticas['tendencia'] ?? '+0%', 
                  Colors.green
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildColmenasList() {
    return Column(
      children: _colmenasData.map((colmena) {
        return _buildColmenaItem(
          colmena['name'],
          colmena['health'],
          colmena['status'],
          colmena['statusColor'],
          colmena,
        );
      }).toList(),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms);
  }

  Widget _buildColmenaItem(
    String name,
    double health,
    String status,
    Color statusColor,
    Map<String, dynamic> colmenaData,
  ) {
    return GestureDetector(
      onTap: () {
        _showColmenaDetailDialog(name, health, status, statusColor, colmenaData);
      },
      child: Card(
        elevation: 2,
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.hive, color: Colors.amber[800], size: 30),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '${health.toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Salud',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showColmenaDetailDialog(
    String name,
    double health,
    String status,
    Color statusColor,
    Map<String, dynamic> colmenaData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.hive, color: Colors.amber[800]),
                      ),
                      SizedBox(width: 12),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildHealthIndicator(health, status, statusColor),
              SizedBox(height: 24),
              _buildDetailSection(
                'Población',
                _buildPopulationDetails(colmenaData),
              ),
              SizedBox(height: 16),
              _buildDetailSection(
                'Producción',
                _buildProductionDetails(colmenaData),
              ),
              SizedBox(height: 16),
              _buildDetailSection(
                'Datos del Monitoreo',
                _buildMonitoreoDetails(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(double health, String status, Color statusColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Estado de Salud',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value: health / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${health.toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    status,
                    style: GoogleFonts.poppins(fontSize: 14, color: statusColor),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHealthMetric(
                'Reina',
                'Presente',
                Icons.check_circle,
                Colors.green,
              ),
              _buildHealthMetric(
                'Cría',
                'Normal',
                Icons.child_care,
                Colors.amber,
              ),
              _buildHealthMetric(
                'Plagas',
                'No',
                Icons.bug_report,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.brown[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
          ),
        ),
        SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildPopulationDetails(Map<String, dynamic> colmenaData) {
    int poblacion = colmenaData['poblacion'] ?? 15000;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPopulationItem('Obreras', '~${(poblacion * 0.9).toInt()}', Icons.group),
              _buildPopulationItem('Zánganos', '~${(poblacion * 0.1).toInt()}', Icons.person),
              _buildPopulationItem('Edad Reina', '1.5 años', Icons.cake),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: poblacion / 20000, // Capacidad máxima estimada
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 8),
          Text(
            'Capacidad de población: ${((poblacion / 20000) * 100).toInt()}%',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPopulationItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber[800], size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.brown[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProductionDetails(Map<String, dynamic> colmenaData) {
    double produccion = colmenaData['produccion'] ?? 0.0;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProductionItem('Miel', '${produccion.toStringAsFixed(1)} kg', Icons.local_drink),
              _buildProductionItem('Polen', '${(produccion * 0.15).toStringAsFixed(1)} kg', Icons.grain),
              _buildProductionItem('Cera', '${(produccion * 0.06).toStringAsFixed(1)} kg', Icons.hexagon),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Última cosecha:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Text(
                _formatFecha(widget.monitoreo.fecha),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Próxima cosecha estimada:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Text(
                _getNextHarvestDate(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductionItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber[800], size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.brown[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMonitoreoDetails() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: widget.monitoreo.respuestas.map((respuesta) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.quiz,
                      color: Colors.amber[800],
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          respuesta.preguntaTexto,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.brown[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          respuesta.respuesta,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.concertOne(fontSize: 20, color: Colors.brown[800]),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLineChart() {
    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _buildLineChartContent(),
    );
  }

  Widget _buildLineChartContent() {
    // Generar datos de línea basados en las respuestas del monitoreo
    List<FlSpot> spots = _generateLineChartSpots();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()} kg',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
                int index = value.toInt();
                if (index >= 0 && index < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      months[index],
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.amber[600],
            barWidth: 4,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.amber.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '${barSpot.y.toInt()} kg',
                  GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateLineChartSpots() {
    // Generar puntos basados en datos de producción del monitoreo
    List<FlSpot> spots = [];
    double baseProduction = _estadisticas['produccion_total'] ?? 12.0;
    
    // Simular datos históricos con variaciones
    for (int i = 0; i < 6; i++) {
      double variation = (i * 2) + (baseProduction * 0.1 * (i - 2));
      double value = (baseProduction + variation).clamp(0, 30);
      spots.add(FlSpot(i.toDouble(), value));
    }
    
    return spots;
  }

  Widget _buildBarChart() {
    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _buildBarChartContent(),
    );
  }

  Widget _buildBarChartContent() {
    List<BarChartGroupData> barGroups = _generateBarChartGroups();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()}%',
                GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < _colmenasData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _colmenasData[index]['name'],
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
          },
        ),
        barGroups: barGroups,
      ),
    );
  }

  List<BarChartGroupData> _generateBarChartGroups() {
    List<BarChartGroupData> groups = [];
    
    for (int i = 0; i < _colmenasData.length; i++) {
      double health = _colmenasData[i]['health'];
      Color color = _colmenasData[i]['statusColor'];
      
      groups.add(_buildBarData(i, health, color));
    }
    
    return groups;
  }

  BarChartGroupData _buildBarData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: Colors.grey[200],
          ),
        ),
      ],
    );
  }

  String _formatFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      final months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      return '${dateTime.day} de ${months[dateTime.month - 1]}';
    } catch (e) {
      return fecha;
    }
  }

  String _getNextHarvestDate() {
    try {
      final currentDate = DateTime.parse(widget.monitoreo.fecha);
      final nextHarvest = currentDate.add(Duration(days: 45)); // Estimación de 45 días
      final months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      return '${nextHarvest.day} de ${months[nextHarvest.month - 1]}';
    } catch (e) {
      return 'Por determinar';
    }
  }

  String _determineEstado() {
    // Determinar estado basado en las respuestas del monitoreo
    for (final respuesta in widget.monitoreo.respuestas) {
      if (respuesta.preguntaId.toLowerCase().contains('salud') ||
          respuesta.preguntaId.toLowerCase().contains('estado')) {
        if (respuesta.tipoRespuesta == 'option') {
          if (respuesta.respuesta.toLowerCase().contains('malo') ||
              respuesta.respuesta.toLowerCase().contains('alerta') ||
              respuesta.respuesta.toLowerCase().contains('problema')) {
            return 'Alerta';
          }
        } else if (respuesta.tipoRespuesta == 'number') {
          double? valor = double.tryParse(respuesta.respuesta);
          if (valor != null && valor < 50) {
            return 'Alerta';
          }
        }
      }
    }
    return 'Normal';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alerta':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'alerta':
        return Icons.warning_amber_rounded;
      case 'normal':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Editar Inspección',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '¿Deseas editar esta inspección? Los cambios se sincronizarán automáticamente.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Aquí implementarías la navegación a la pantalla de edición
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Funcionalidad de edición próximamente'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(_determineEstado()),
              ),
              child: Text('Editar'),
            ),
          ],
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}