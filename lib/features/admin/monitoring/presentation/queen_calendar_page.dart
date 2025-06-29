import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/monitoring/service/enhaced_api_service.dart';
import 'package:sotfbee/features/admin/monitoring/widgets/enhanced_card_widget.dart';
import '../models/enhanced_models.dart';

class QueenCalendarScreen extends StatefulWidget {
  const QueenCalendarScreen({Key? key}) : super(key: key);

  @override
  _QueenCalendarScreenState createState() => _QueenCalendarScreenState();
}

class _QueenCalendarScreenState extends State<QueenCalendarScreen>
    with SingleTickerProviderStateMixin {
  // Estado
  List<NotificacionReina> notificaciones = [];
  List<NotificacionReina> filteredNotificaciones = [];
  List<Apiario> apiarios = [];
  bool isLoading = true;
  bool isConnected = false;
  int? selectedApiarioId;
  String selectedFilter = 'todas'; // todas, pendientes, vencidas

  // Controladores
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();

  // Colores
  final Color colorAmarillo = const Color(0xFFFBC209);
  final Color colorNaranja = const Color(0xFFFF9800);
  final Color colorAmbarClaro = const Color(0xFFFFF8E1);
  final Color colorVerde = const Color(0xFF4CAF50);

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
      notificaciones = await EnhancedApiService.obtenerNotificacionesReina(
        apiarioId: selectedApiarioId,
      );
      _filterNotificaciones();
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error al cargar datos: $e");
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

  void _filterNotificaciones() {
    final query = _searchController.text.toLowerCase();
    final now = DateTime.now();

    filteredNotificaciones = notificaciones.where((notif) {
      // Filtro por texto
      final matchesText =
          notif.titulo.toLowerCase().contains(query) ||
          notif.mensaje.toLowerCase().contains(query);

      // Filtro por estado
      bool matchesFilter = true;
      switch (selectedFilter) {
        case 'pendientes':
          matchesFilter = !notif.leida;
          break;
        case 'vencidas':
          matchesFilter =
              notif.fechaVencimiento != null &&
              notif.fechaVencimiento!.isBefore(now);
          break;
        case 'todas':
        default:
          matchesFilter = true;
      }

      return matchesText && matchesFilter;
    }).toList();

    // Ordenar por fecha de creación (más recientes primero)
    filteredNotificaciones.sort(
      (a, b) => b.fechaCreacion.compareTo(a.fechaCreacion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: CustomAppBarWidget(
        title: 'Calendario de Reinas',
        isConnected: isConnected,
        onSync: _syncData,
      ),
      body: isLoading
          ? LoadingWidget(
              message: "Cargando notificaciones...",
              color: colorNaranja,
            )
          : _buildBody(isTablet),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNotificacionDialog(),
        backgroundColor: Colors.purple,
        icon: Icon(Icons.add_alert, color: Colors.white),
        label: Text(
          'Nueva Notificación',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ).animate().scale(delay: 800.ms),
    );
  }

  Widget _buildBody(bool isTablet) {
    return Column(
      children: [
        _buildHeader(isTablet),
        Expanded(child: _buildNotificacionesList(isTablet)),
      ],
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Estadísticas
          Row(
            children: [
              Expanded(
                child: StatCardWidget(
                  label: 'Total',
                  value: notificaciones.length.toString(),
                  icon: Icons.notifications,
                  color: Colors.purple,
                  animationDelay: 0,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: StatCardWidget(
                  label: 'Pendientes',
                  value: notificaciones
                      .where((n) => !n.leida)
                      .length
                      .toString(),
                  icon: Icons.notification_important,
                  color: colorNaranja,
                  animationDelay: 100,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: StatCardWidget(
                  label: 'Vencidas',
                  value: notificaciones
                      .where(
                        (n) =>
                            n.fechaVencimiento != null &&
                            n.fechaVencimiento!.isBefore(DateTime.now()),
                      )
                      .length
                      .toString(),
                  icon: Icons.warning,
                  color: Colors.red,
                  animationDelay: 200,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Filtros
          Row(
            children: [
              // Selector de apiario
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int?>(
                  value: selectedApiarioId,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por apiario',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        'Todos los apiarios',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    ...apiarios.map((apiario) {
                      return DropdownMenuItem<int?>(
                        value: apiario.id,
                        child: Text(
                          apiario.nombre,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedApiarioId = value;
                    });
                    _loadData();
                  },
                ),
              ),

              SizedBox(width: 12),

              // Filtro por estado
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedFilter,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'todas',
                      child: Text(
                        'Todas',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'pendientes',
                      child: Text(
                        'Pendientes',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'vencidas',
                      child: Text(
                        'Vencidas',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                    _filterNotificaciones();
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Barra de búsqueda
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar notificaciones...',
                hintStyle: GoogleFonts.poppins(fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.purple),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterNotificaciones();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                _filterNotificaciones();
                setState(() {});
              },
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildNotificacionesList(bool isTablet) {
    if (filteredNotificaciones.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.notifications_none,
        title: _searchController.text.isNotEmpty
            ? 'No se encontraron notificaciones'
            : 'No hay notificaciones',
        subtitle: _searchController.text.isNotEmpty
            ? 'Intenta con otros términos de búsqueda'
            : 'Crea tu primera notificación de reina',
        actionText: _searchController.text.isEmpty
            ? 'Crear Notificación'
            : null,
        onAction: _searchController.text.isEmpty
            ? () => _showNotificacionDialog()
            : null,
        color: Colors.purple,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: filteredNotificaciones.length,
        itemBuilder: (context, index) {
          return _buildNotificacionCard(filteredNotificaciones[index], index);
        },
      ),
    );
  }

  Widget _buildNotificacionCard(NotificacionReina notificacion, int index) {
    final now = DateTime.now();
    final isVencida =
        notificacion.fechaVencimiento != null &&
        notificacion.fechaVencimiento!.isBefore(now);
    final diasRestantes = notificacion.fechaVencimiento != null
        ? notificacion.fechaVencimiento!.difference(now).inDays
        : null;

    return Card(
          elevation: notificacion.leida ? 1 : 3,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isVencida
                  ? Colors.red.withOpacity(0.3)
                  : notificacion.leida
                  ? Colors.transparent
                  : _getPriorityColor(notificacion.prioridad).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showNotificacionDetails(notificacion),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    notificacion.leida
                        ? Colors.grey[50]!
                        : _getPriorityColor(
                            notificacion.prioridad,
                          ).withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con título y estado
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(
                            notificacion.prioridad,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getNotificationIcon(notificacion.tipo),
                          color: _getPriorityColor(notificacion.prioridad),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notificacion.titulo,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: notificacion.leida
                                    ? Colors.grey[600]
                                    : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatDate(notificacion.fechaCreacion),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badges de estado
                      Column(
                        children: [
                          if (!notificacion.leida)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorNaranja,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Nuevo',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (isVencida) ...[
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Vencida',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ] else if (diasRestantes != null &&
                              diasRestantes <= 7) ...[
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorAmarillo,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$diasRestantes días',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Mensaje
                  Text(
                    notificacion.mensaje,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: notificacion.leida
                          ? Colors.grey[600]
                          : Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 12),

                  // Footer con información adicional
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(
                            notificacion.prioridad,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getPriorityLabel(notificacion.prioridad),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getPriorityColor(notificacion.prioridad),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTypeLabel(notificacion.tipo),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Spacer(),
                      if (notificacion.fechaVencimiento != null)
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 4),
                            Text(
                              _formatDate(notificacion.fechaVencimiento!),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
        )
        .slideX(begin: 0.2, end: 0);
  }

  Color _getPriorityColor(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return colorNaranja;
      case 'baja':
        return colorVerde;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return 'ALTA';
      case 'media':
        return 'MEDIA';
      case 'baja':
        return 'BAJA';
      default:
        return 'NORMAL';
    }
  }

  IconData _getNotificationIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'cambio_reina':
        return Icons.swap_horiz;
      case 'revision':
        return Icons.search;
      case 'tratamiento':
        return Icons.medical_services;
      case 'alimentacion':
        return Icons.restaurant;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabel(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'cambio_reina':
        return 'Cambio de Reina';
      case 'revision':
        return 'Revisión';
      case 'tratamiento':
        return 'Tratamiento';
      case 'alimentacion':
        return 'Alimentación';
      default:
        return 'General';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Mostrar detalles de notificación
  void _showNotificacionDetails(NotificacionReina notificacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(notificacion.tipo),
              color: _getPriorityColor(notificacion.prioridad),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                notificacion.titulo,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notificacion.mensaje,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 16),
            _buildDetailRow('Tipo:', _getTypeLabel(notificacion.tipo)),
            _buildDetailRow(
              'Prioridad:',
              _getPriorityLabel(notificacion.prioridad),
            ),
            _buildDetailRow('Creada:', _formatDate(notificacion.fechaCreacion)),
            if (notificacion.fechaVencimiento != null)
              _buildDetailRow(
                'Vence:',
                _formatDate(notificacion.fechaVencimiento!),
              ),
            _buildDetailRow(
              'Estado:',
              notificacion.leida ? 'Leída' : 'Pendiente',
            ),
          ],
        ),
        actions: [
          if (!notificacion.leida)
            TextButton(
              onPressed: () => _marcarComoLeida(notificacion),
              child: Text(
                'Marcar como leída',
                style: GoogleFonts.poppins(color: colorVerde),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
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
          SizedBox(width: 8),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // Marcar notificación como leída
  Future<void> _marcarComoLeida(NotificacionReina notificacion) async {
    try {
      Navigator.pop(context);
      await EnhancedApiService.marcarNotificacionComoLeida(notificacion.id);
      _showSnackBar('Notificación marcada como leída', colorVerde);
      await _loadData();
    } catch (e) {
      _showSnackBar('Error al marcar notificación: $e', Colors.red);
    }
  }

  // Diálogo para crear notificación
  void _showNotificacionDialog({NotificacionReina? notificacion}) {
    final isEditing = notificacion != null;
    String tipoSeleccionado = notificacion?.tipo ?? 'cambio_reina';
    String prioridadSeleccionada = notificacion?.prioridad ?? 'media';
    DateTime? fechaVencimiento = notificacion?.fechaVencimiento;

    if (isEditing) {
      _tituloController.text = notificacion.titulo;
      _mensajeController.text = notificacion.mensaje;
    } else {
      _tituloController.clear();
      _mensajeController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purple[300]!],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.add_alert,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  isEditing ? 'Editar Notificación' : 'Nueva Notificación',
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),

                // Título
                TextField(
                  controller: _tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.title, color: Colors.purple),
                  ),
                  style: GoogleFonts.poppins(),
                ),

                SizedBox(height: 16),

                // Mensaje
                TextField(
                  controller: _mensajeController,
                  decoration: InputDecoration(
                    labelText: 'Mensaje',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.message, color: Colors.purple),
                  ),
                  style: GoogleFonts.poppins(),
                  maxLines: 3,
                ),

                SizedBox(height: 16),

                // Tipo
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.category, color: Colors.purple),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'cambio_reina',
                      child: Text(
                        'Cambio de Reina',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'revision',
                      child: Text('Revisión', style: GoogleFonts.poppins()),
                    ),
                    DropdownMenuItem(
                      value: 'tratamiento',
                      child: Text('Tratamiento', style: GoogleFonts.poppins()),
                    ),
                    DropdownMenuItem(
                      value: 'alimentacion',
                      child: Text('Alimentación', style: GoogleFonts.poppins()),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tipoSeleccionado = value!;
                    });
                  },
                ),

                SizedBox(height: 16),

                // Prioridad
                DropdownButtonFormField<String>(
                  value: prioridadSeleccionada,
                  decoration: InputDecoration(
                    labelText: 'Prioridad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.priority_high, color: Colors.purple),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'baja',
                      child: Text('Baja', style: GoogleFonts.poppins()),
                    ),
                    DropdownMenuItem(
                      value: 'media',
                      child: Text('Media', style: GoogleFonts.poppins()),
                    ),
                    DropdownMenuItem(
                      value: 'alta',
                      child: Text('Alta', style: GoogleFonts.poppins()),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      prioridadSeleccionada = value!;
                    });
                  },
                ),

                SizedBox(height: 16),

                // Fecha de vencimiento
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          fechaVencimiento ??
                          DateTime.now().add(Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        fechaVencimiento = date;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.purple),
                        SizedBox(width: 12),
                        Text(
                          fechaVencimiento != null
                              ? 'Vence: ${_formatDate(fechaVencimiento!)}'
                              : 'Seleccionar fecha de vencimiento',
                          style: GoogleFonts.poppins(
                            color: fechaVencimiento != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _saveNotificacion(
                        notificacion,
                        tipoSeleccionado,
                        prioridadSeleccionada,
                        fechaVencimiento,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isEditing ? 'Actualizar' : 'Crear',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          actionsPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // Guardar notificación
  Future<void> _saveNotificacion(
    NotificacionReina? existingNotificacion,
    String tipo,
    String prioridad,
    DateTime? fechaVencimiento,
  ) async {
    if (_tituloController.text.trim().isEmpty ||
        _mensajeController.text.trim().isEmpty) {
      _showSnackBar('Por favor completa todos los campos', Colors.red);
      return;
    }

    try {
      Navigator.pop(context);

      final nuevaNotificacion = NotificacionReina(
        id: existingNotificacion?.id ?? DateTime.now().millisecondsSinceEpoch,
        apiarioId: selectedApiarioId ?? apiarios.first.id,
        tipo: tipo,
        titulo: _tituloController.text.trim(),
        mensaje: _mensajeController.text.trim(),
        prioridad: prioridad,
        fechaCreacion: existingNotificacion?.fechaCreacion ?? DateTime.now(),
        fechaVencimiento: fechaVencimiento,
      );

      await EnhancedApiService.crearNotificacionReina(nuevaNotificacion);

      _showSnackBar(
        existingNotificacion != null
            ? 'Notificación actualizada correctamente'
            : 'Notificación creada correctamente',
        colorVerde,
      );

      await _loadData();
    } catch (e) {
      _showSnackBar('Error al guardar: $e', Colors.red);
    }
  }

  // Sincronizar datos
  Future<void> _syncData() async {
    try {
      _showSnackBar("Sincronizando notificaciones...", colorAmarillo);

      await _checkConnection();
      await _loadData();

      _showSnackBar("Notificaciones sincronizadas correctamente", colorVerde);
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

  @override
  void dispose() {
    _searchController.dispose();
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }
}
