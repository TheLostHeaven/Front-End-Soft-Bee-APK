import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sotfbee/features/admin/history/controllers/monitoreo_controllers.dart';
import 'package:sotfbee/features/admin/history/models/monitoreo_models.dart';
import 'package:sotfbee/features/admin/history/presentation/detailis_inspeccion_page.dart';

class HistorialInspeccionesScreenModified extends StatefulWidget {
  @override
  _HistorialInspeccionesScreenModifiedState createState() =>
      _HistorialInspeccionesScreenModifiedState();
}

class _HistorialInspeccionesScreenModifiedState
    extends State<HistorialInspeccionesScreenModified> {
  @override
  void initState() {
    super.initState();
    // Cargar datos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonitoreoController>().loadMonitoreos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historial de Inspecciones',
          style: GoogleFonts.concertOne(
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Color(0xFF8D6E63),
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          Consumer<MonitoreoController>(
            builder: (context, controller, child) {
              return IconButton(
                icon: Icon(
                  controller.isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: controller.isOnline ? Colors.green : Colors.red,
                ),
                onPressed: () {
                  controller.syncData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        controller.isOnline
                            ? 'Sincronizando datos...'
                            : 'Sin conexión - Datos locales',
                      ),
                      backgroundColor: controller.isOnline
                          ? Colors.green
                          : Colors.orange,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amber.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Consumer<MonitoreoController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFFB300)),
                    SizedBox(height: 16),
                    Text(
                      'Cargando inspecciones...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.brown[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (controller.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error al cargar datos',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      controller.error!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadMonitoreos(),
                      child: Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFB300),
                      ),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                bool isLargeScreen = constraints.maxWidth > 768;
                bool isExtraLargeScreen = constraints.maxWidth > 1200;

                return Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isExtraLargeScreen ? 1200 : double.infinity,
                    ),
                    child: isLargeScreen
                        ? _buildLargeScreenLayout(
                            context,
                            constraints,
                            controller,
                          )
                        : _buildMobileLayout(context, controller),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a pantalla de nueva inspección
          _showNewInspectionDialog(context);
        },
        backgroundColor: Color(0xFFFFB300),
        child: Icon(Icons.add, color: Colors.brown[800]),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    MonitoreoController controller,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.loadMonitoreos(),
      child: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildHeader(false, controller),
          SizedBox(height: 16),
          ..._buildInspeccionItems(context, false, controller.monitoreos),
        ],
      ),
    );
  }

  Widget _buildLargeScreenLayout(
    BuildContext context,
    BoxConstraints constraints,
    MonitoreoController controller,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.loadMonitoreos(),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildHeader(true, controller),
            SizedBox(height: 32),
            _buildInspeccionesGrid(context, constraints, controller.monitoreos),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLargeScreen, MonitoreoController controller) {
    final stats = controller.getResumenStats();

    return Container(
      padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Resumen de Actividad',
              style: GoogleFonts.concertOne(
                fontSize: isLargeScreen ? 28 : 20,
                color: Colors.brown[800],
              ),
            ),
          ),
          SizedBox(height: isLargeScreen ? 16 : 8),
          Container(
            padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: isLargeScreen
                ? _buildLargeScreenStats(stats)
                : _buildMobileStats(stats),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildMobileStats(Map<String, dynamic> stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          '${stats['total_inspecciones'] ?? 0}',
          'Inspecciones',
          Icons.assignment,
          false,
        ),
        _buildStatItem(
          '${stats['colmenas_saludables'] ?? 0}',
          'Colmenas\nSaludables',
          Icons.favorite,
          false,
        ),
        _buildStatItem(
          '${stats['alertas_pendientes'] ?? 0}',
          'Alertas\nPendientes',
          Icons.warning_amber_rounded,
          false,
        ),
      ],
    );
  }

  Widget _buildLargeScreenStats(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '${stats['total_inspecciones'] ?? 0}',
            'Inspecciones Realizadas',
            Icons.assignment,
            'Total de inspecciones completadas',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            '${stats['colmenas_saludables'] ?? 0}',
            'Colmenas Saludables',
            Icons.favorite,
            'Colmenas en condiciones óptimas',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            '${stats['alertas_pendientes'] ?? 0}',
            'Alertas Pendientes',
            Icons.warning_amber_rounded,
            'Requieren atención inmediata',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String value,
    String title,
    IconData icon,
    String description,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.brown[800], size: 36),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.brown[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.brown[600]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    bool isLarge,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.brown[800], size: isLarge ? 32 : 28),
        SizedBox(height: isLarge ? 12 : 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isLarge ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isLarge ? 14 : 12,
            color: Colors.brown[800],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInspeccionesGrid(
    BuildContext context,
    BoxConstraints constraints,
    List<MonitoreoModel> monitoreos,
  ) {
    int crossAxisCount = 1;
    if (constraints.maxWidth > 1200) {
      crossAxisCount = 3;
    } else if (constraints.maxWidth > 768) {
      crossAxisCount = 2;
    }

    List<Widget> items = _buildInspeccionItems(context, true, monitoreos);

    if (crossAxisCount == 1) {
      return Column(children: items);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  List<Widget> _buildInspeccionItems(
    BuildContext context,
    bool isLargeScreen,
    List<MonitoreoModel> monitoreos,
  ) {
    if (monitoreos.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay inspecciones registradas',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Agrega tu primera inspección',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return monitoreos.asMap().entries.map((entry) {
      int index = entry.key;
      MonitoreoModel monitoreo = entry.value;

      // Determinar estado basado en respuestas
      String estado = _determineEstado(monitoreo);
      Color statusColor = _getStatusColor(estado);
      IconData statusIcon = _getStatusIcon(estado);

      return _buildHistorialItem(
            context,
            _formatFecha(monitoreo.fecha),
            estado,
            _generateObservaciones(monitoreo),
            statusIcon,
            statusColor,
            'assets/images/honeycomb_pattern.png',
            isLargeScreen,
            monitoreo,
          )
          .animate()
          .fadeIn(duration: Duration(milliseconds: 300 + (index * 100)))
          .slideX(delay: Duration(milliseconds: index * 100));
    }).toList();
  }

  String _determineEstado(MonitoreoModel monitoreo) {
    // Lógica para determinar estado basado en respuestas
    for (final respuesta in monitoreo.respuestas) {
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

  String _generateObservaciones(MonitoreoModel monitoreo) {
    if (monitoreo.respuestas.isEmpty) {
      return 'Sin observaciones registradas';
    }

    // Generar observaciones basadas en las respuestas más relevantes
    List<String> observaciones = [];

    for (final respuesta in monitoreo.respuestas.take(2)) {
      observaciones.add('${respuesta.preguntaTexto}: ${respuesta.respuesta}');
    }

    return observaciones.join('. ');
  }

  String _formatFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      final months = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      return '${dateTime.day} de ${months[dateTime.month - 1]}';
    } catch (e) {
      return fecha;
    }
  }

  Widget _buildHistorialItem(
    BuildContext context,
    String fecha,
    String estado,
    String observaciones,
    IconData statusIcon,
    Color statusColor,
    String backgroundPattern,
    bool isLargeScreen,
    MonitoreoModel monitoreo,
  ) {
    return Hero(
      tag: 'inspeccion_${monitoreo.id}',
      child: Card(
        elevation: isLargeScreen ? 6 : 4,
        shadowColor: Colors.amber.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.amber.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: Provider.of<MonitoreoController>(
                      context,
                      listen: false,
                    ),
                    child: InspeccionDetalleScreenModified(
                      monitoreo: monitoreo,
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Inspección del $fecha',
                          style: GoogleFonts.poppins(
                            fontSize: isLargeScreen ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[800],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      _buildStatusBadge(
                        estado,
                        statusIcon,
                        statusColor,
                        isLargeScreen,
                      ),
                    ],
                  ),
                  SizedBox(height: isLargeScreen ? 16 : 12),
                  Text(
                    observaciones,
                    style: GoogleFonts.poppins(
                      fontSize: isLargeScreen ? 16 : 14,
                      color: Colors.brown[600],
                      height: 1.4,
                    ),
                    maxLines: isLargeScreen ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isLargeScreen ? 16 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            monitoreo.sincronizado
                                ? Icons.cloud_done
                                : Icons.cloud_off,
                            size: 16,
                            color: monitoreo.sincronizado
                                ? Colors.green
                                : Colors.orange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            monitoreo.sincronizado ? 'Sincronizado' : 'Local',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: monitoreo.sincronizado
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Ver detalles',
                            style: GoogleFonts.poppins(
                              fontSize: isLargeScreen ? 16 : 14,
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: isLargeScreen ? 16 : 14,
                            color: Colors.amber[800],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    String status,
    IconData icon,
    Color color,
    bool isLargeScreen,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 16 : 12,
        vertical: isLargeScreen ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isLargeScreen ? 18 : 16, color: color),
          SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: isLargeScreen ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
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

  void _showNewInspectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Nueva Inspección',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '¿Deseas crear una nueva inspección?',
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
                // Aquí navegarías a la pantalla de nueva inspección
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Funcionalidad de nueva inspección próximamente',
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFB300),
              ),
              child: Text('Crear'),
            ),
          ],
        );
      },
    );
  }
}
