import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/model.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

class QueenCalendarScreen extends StatefulWidget {
  const QueenCalendarScreen({Key? key}) : super(key: key);

  @override
  _QueenCalendarScreenState createState() => _QueenCalendarScreenState();
}

class _QueenCalendarScreenState extends State<QueenCalendarScreen>
    with SingleTickerProviderStateMixin {
  // Servicios
  late LocalDBService dbService;

  // Controladores
  final TextEditingController _notesController = TextEditingController();

  // Estado del calendario
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Estado de la aplicación
  bool isLoading = true;
  bool isConnected = false;
  List<Apiario> apiarios = [];
  List<NotificacionReina> notificaciones = [];
  Map<DateTime, List<NotificacionReina>> eventsByDay = {};

  // Estado del formulario
  int? selectedApiarioId;
  int? selectedColmenaId;
  List<Colmena> colmenasDelApiario = [];
  String selectedQueenType = 'Italiana';
  bool enableNotifications = true;

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
      // Cargar apiarios
      apiarios = await dbService.getApiarios();

      // Cargar notificaciones
      notificaciones = await dbService.getNotificacionesReina();

      // Organizar eventos por día
      _organizeEventsByDay();

      setState(() {});
    } catch (e) {
      debugPrint("❌ Error al cargar datos: $e");
    }
  }

  void _organizeEventsByDay() {
    eventsByDay.clear();
    for (final notificacion in notificaciones) {
      final day = DateTime(
        notificacion.fechaCreacion.year,
        notificacion.fechaCreacion.month,
        notificacion.fechaCreacion.day,
      );

      if (eventsByDay[day] == null) {
        eventsByDay[day] = [];
      }
      eventsByDay[day]!.add(notificacion);
    }
  }

  Future<void> _loadColmenas() async {
    if (selectedApiarioId == null) return;

    try {
      colmenasDelApiario = await dbService.getColmenasByApiario(
        selectedApiarioId!,
      );
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error al cargar colmenas: $e");
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
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: AppBar(
        title: Text(
          'Calendario de Reinas',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
          ),
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: _syncData,
            tooltip: "Sincronizar",
          ),
        ],
      ),
      body: isLoading ? _buildLoadingScreen() : _buildBody(isDesktop, isTablet),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorAmarillo),
          ),
          SizedBox(height: 16),
          Text(
            "Cargando calendario...",
            style: GoogleFonts.poppins(fontSize: 16, color: colorNaranja),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendario
                Expanded(
                  flex: 2,
                  child: _buildCalendarSection(isDesktop, isTablet),
                ),
                SizedBox(width: 24),
                // Panel lateral
                Expanded(flex: 1, child: _buildSidePanel(isDesktop, isTablet)),
              ],
            )
          : Column(
              children: [
                _buildCalendarSection(isDesktop, isTablet),
                SizedBox(height: 16),
                _buildSidePanel(isDesktop, isTablet),
              ],
            ),
    );
  }

  Widget _buildCalendarSection(bool isDesktop, bool isTablet) {
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
                  Icons.calendar_month,
                  color: colorNaranja,
                  size: isDesktop ? 28 : 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Calendario de Reemplazo de Reinas',
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: colorNaranja,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Estadísticas rápidas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat(
                  'Total Eventos',
                  notificaciones.length.toString(),
                  Icons.event,
                  colorVerde,
                  isDesktop,
                ),
                _buildQuickStat(
                  'Este Mes',
                  _getEventsThisMonth().toString(),
                  Icons.calendar_today,
                  colorAmarillo,
                  isDesktop,
                ),
                _buildQuickStat(
                  'Pendientes',
                  _getPendingEvents().toString(),
                  Icons.schedule,
                  colorNaranja,
                  isDesktop,
                ),
              ],
            ),

            SizedBox(height: 24),

            // Calendario
            TableCalendar<NotificacionReina>(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => eventsByDay[day] ?? [],
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              rowHeight: isDesktop ? 64 : 48,
              calendarStyle: CalendarStyle(
                cellMargin: EdgeInsets.all(isDesktop ? 8 : 4),
                cellPadding: EdgeInsets.all(isDesktop ? 12 : 8),
                defaultTextStyle: GoogleFonts.poppins(
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
                weekendTextStyle: GoogleFonts.poppins(
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[600],
                ),
                selectedTextStyle: GoogleFonts.poppins(
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                todayTextStyle: GoogleFonts.poppins(
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                todayDecoration: BoxDecoration(
                  color: colorAmarillo.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorNaranja, width: 2),
                ),
                selectedDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorNaranja, colorAmarillo],
                  ),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: colorVerde,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  color: colorNaranja,
                ),
                formatButtonDecoration: BoxDecoration(
                  color: colorAmarillo,
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isDesktop ? 14 : 12,
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  size: isDesktop ? 28 : 24,
                  color: colorNaranja,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  size: isDesktop ? 28 : 24,
                  color: colorNaranja,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.poppins(
                  fontSize: isDesktop ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: colorNaranja,
                ),
                weekendStyle: GoogleFonts.poppins(
                  fontSize: isDesktop ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              calendarBuilders: CalendarBuilders(
                // Marcador personalizado con abeja
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child:
                          Container(
                                decoration: BoxDecoration(
                                  color: colorVerde,
                                  shape: BoxShape.circle,
                                ),
                                width: 16,
                                height: 16,
                                child: Center(
                                  child: Text(
                                    '🐝',
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ),
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .scale(
                                begin: Offset(0.8, 0.8),
                                end: Offset(1.2, 1.2),
                                duration: 1000.ms,
                              ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isDesktop ? 24 : 20)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: Offset(1, 1),
                end: Offset(1.1, 1.1),
                duration: 2000.ms,
              ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 12 : 10,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        // Eventos del día seleccionado
        if (_selectedDay != null) _buildSelectedDayEvents(isDesktop, isTablet),

        SizedBox(height: 16),

        // Formulario para nuevo evento
        _buildNewEventForm(isDesktop, isTablet),
      ],
    );
  }

  Widget _buildSelectedDayEvents(bool isDesktop, bool isTablet) {
    final events = eventsByDay[_selectedDay] ?? [];

    return Card(
      elevation: 4,
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
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: colorNaranja,
                  size: isDesktop ? 24 : 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Eventos del ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: colorNaranja,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            if (events.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No hay eventos programados',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(events[index], isDesktop);
                },
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildEventCard(NotificacionReina notificacion, bool isDesktop) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: !isDesktop,
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorAmarillo.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text('🐝', style: TextStyle(fontSize: isDesktop ? 16 : 14)),
        ),
        title: Text(
          notificacion.titulo,
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 14 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          notificacion.mensaje,
          style: GoogleFonts.poppins(fontSize: isDesktop ? 12 : 10),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editEvent(notificacion);
                break;
              case 'delete':
                _deleteEvent(notificacion);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: colorNaranja),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewEventForm(bool isDesktop, bool isTablet) {
    return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, colorAmbarClaro.withOpacity(0.3)],
              ),
            ),
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle,
                      color: colorVerde,
                      size: isDesktop ? 24 : 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Programar Reemplazo',
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: colorVerde,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Selector de apiario
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
                      borderSide: BorderSide(color: colorAmarillo, width: 2),
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
                      selectedColmenaId = null;
                    });
                    _loadColmenas();
                  },
                ),

                SizedBox(height: 12),

                // Selector de colmena
                DropdownButtonFormField<int>(
                  value: selectedColmenaId,
                  decoration: InputDecoration(
                    labelText: 'Colmena',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorAmarillo, width: 2),
                    ),
                  ),
                  items: colmenasDelApiario.map((colmena) {
                    return DropdownMenuItem<int>(
                      value: colmena.id,
                      child: Text(
                        'Colmena #${colmena.numeroColmena}',
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedColmenaId = value;
                    });
                  },
                ),

                SizedBox(height: 12),

                // Tipo de reina
                DropdownButtonFormField<String>(
                  value: selectedQueenType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Reina',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorAmarillo, width: 2),
                    ),
                  ),
                  items: ['Italiana', 'Carniola', 'Buckfast', 'Caucásica'].map((
                    tipo,
                  ) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedQueenType = value!;
                    });
                  },
                ),

                SizedBox(height: 12),

                // Notas
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notas',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorAmarillo, width: 2),
                    ),
                  ),
                  maxLines: 3,
                ),

                SizedBox(height: 16),

                // Switch de notificaciones
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Activar notificaciones',
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: enableNotifications,
                      onChanged: (value) {
                        setState(() {
                          enableNotifications = value;
                        });
                      },
                      activeColor: colorVerde,
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Botón para crear evento
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedDay != null ? _createEvent : null,
                    icon: Icon(Icons.save, color: Colors.white),
                    label: Text(
                      'Programar Reemplazo',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorVerde,
                      padding: EdgeInsets.symmetric(
                        vertical: isDesktop ? 16 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideX(begin: 0.2, end: 0);
  }

  // Métodos de utilidad
  int _getEventsThisMonth() {
    final now = DateTime.now();
    return notificaciones.where((n) {
      return n.fechaCreacion.year == now.year &&
          n.fechaCreacion.month == now.month;
    }).length;
  }

  int _getPendingEvents() {
    final now = DateTime.now();
    return notificaciones.where((n) {
      return n.fechaVencimiento != null &&
          n.fechaVencimiento!.isAfter(now) &&
          !n.leida;
    }).length;
  }

  // Crear nuevo evento
  Future<void> _createEvent() async {
    if (_selectedDay == null || selectedApiarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor selecciona una fecha y un apiario',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final apiario = apiarios.firstWhere((a) => a.id == selectedApiarioId);
      final colmenaText = selectedColmenaId != null
          ? ' - Colmena #${colmenasDelApiario.firstWhere((c) => c.id == selectedColmenaId).numeroColmena}'
          : '';

      final notificacion = NotificacionReina(
        id: DateTime.now().millisecondsSinceEpoch,
        apiarioId: selectedApiarioId!,
        colmenaId: selectedColmenaId,
        tipo: 'reemplazo_reina',
        titulo: 'Reemplazo de Reina - ${apiario.nombre}$colmenaText',
        mensaje:
            'Reemplazo programado para reina tipo $selectedQueenType. ${_notesController.text}',
        prioridad: 'alta',
        fechaCreacion: _selectedDay!,
        fechaVencimiento: _selectedDay,
        metadatos: {
          'tipo_reina': selectedQueenType,
          'notas': _notesController.text,
          'notificaciones_activas': enableNotifications,
        },
      );

      await dbService.saveNotificacionReina(notificacion);

      if (isConnected) {
        try {
          await ApiService.crearNotificacionReina(notificacion);
        } catch (e) {
          debugPrint("⚠️ Error al sincronizar notificación: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reemplazo programado para ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: colorVerde,
        ),
      );

      // Limpiar formulario
      setState(() {
        selectedApiarioId = null;
        selectedColmenaId = null;
        selectedQueenType = 'Italiana';
        enableNotifications = true;
      });
      _notesController.clear();
      colmenasDelApiario.clear();

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al crear evento: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Editar evento
  void _editEvent(NotificacionReina notificacion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Función de edición en desarrollo',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Eliminar evento
  Future<void> _deleteEvent(NotificacionReina notificacion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar Eliminación',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar este evento?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

    if (confirmed == true) {
      try {
        // Eliminar de base de datos local
        // await dbService.deleteNotificacionReina(notificacion.id);

        if (isConnected) {
          // Eliminar del servidor
          // await ApiService.eliminarNotificacionReina(notificacion.id);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Evento eliminado correctamente',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: colorVerde,
          ),
        );

        await _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al eliminar evento: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Sincronizar datos
  Future<void> _syncData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Sincronizando calendario...",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: colorAmarillo,
        ),
      );

      await _checkConnection();
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Calendario sincronizado correctamente",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: colorVerde,
        ),
      );
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
}
