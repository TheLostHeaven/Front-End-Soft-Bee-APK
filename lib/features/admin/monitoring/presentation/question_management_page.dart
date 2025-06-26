import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/model.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import 'package:intl/intl.dart';

class PreguntasManagementScreen extends StatefulWidget {
  const PreguntasManagementScreen({Key? key}) : super(key: key);

  @override
  _PreguntasManagementScreenState createState() =>
      _PreguntasManagementScreenState();
}

class _PreguntasManagementScreenState extends State<PreguntasManagementScreen>
    with SingleTickerProviderStateMixin {
  // Servicios
  late LocalDBService dbService;

  // Controladores
  final TextEditingController _preguntaController = TextEditingController();
  final TextEditingController _opcionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Estado
  List<Pregunta> preguntas = [];
  List<Pregunta> filteredPreguntas = [];
  List<Apiario> apiarios = [];
  bool isLoading = true;
  bool isConnected = false;

  // Estado del formulario
  String tipoRespuestaSeleccionado = "texto";
  List<Opcion> opcionesTemporales = [];
  Pregunta? editingPregunta;
  int? selectedApiarioId;

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

      // Cargar preguntas
      if (selectedApiarioId != null) {
        preguntas = await dbService.getPreguntasByApiario(selectedApiarioId!);
      } else {
        preguntas = [];
      }

      _filterPreguntas();
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

  void _filterPreguntas() {
    final query = _searchController.text.toLowerCase();
    filteredPreguntas = preguntas.where((pregunta) {
      return pregunta.texto.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _preguntaController.dispose();
    _opcionController.dispose();
    _searchController.dispose();
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
          'Gestión de Preguntas',
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
      floatingActionButton: selectedApiarioId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showPreguntaDialog(),
              backgroundColor: colorVerde,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                'Nueva Pregunta',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
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
            "Cargando preguntas...",
            style: GoogleFonts.poppins(fontSize: 16, color: colorNaranja),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        // Selector de apiario y estadísticas
        _buildHeader(isDesktop, isTablet),

        // Lista de preguntas
        Expanded(
          child: selectedApiarioId == null
              ? _buildSelectApiarioPrompt()
              : _buildPreguntasList(isDesktop, isTablet),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        children: [
          // Selector de apiario
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seleccionar Apiario',
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: colorNaranja,
                    ),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedApiarioId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorAmarillo, width: 2),
                      ),
                      hintText: 'Selecciona un apiario',
                      hintStyle: GoogleFonts.poppins(),
                    ),
                    items: apiarios.map((apiario) {
                      return DropdownMenuItem<int>(
                        value: apiario.id,
                        child: Text(
                          apiario.nombre,
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedApiarioId = value;
                      });
                      _loadData();
                    },
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),

          if (selectedApiarioId != null) ...[
            SizedBox(height: 16),

            // Estadísticas
            Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 20 : 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Total Preguntas',
                          preguntas.length.toString(),
                          Icons.quiz,
                          colorVerde,
                          isDesktop,
                        ),
                        _buildStatItem(
                          'Activas',
                          preguntas.where((p) => p.activa).length.toString(),
                          Icons.check_circle,
                          colorAmarillo,
                          isDesktop,
                        ),
                        _buildStatItem(
                          'Con Opciones',
                          preguntas
                              .where(
                                (p) =>
                                    p.opciones != null &&
                                    p.opciones!.isNotEmpty,
                              )
                              .length
                              .toString(),
                          Icons.list,
                          colorNaranja,
                          isDesktop,
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms)
                .slideY(begin: -0.2, end: 0),

            SizedBox(height: 16),

            // Barra de búsqueda
            Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar preguntas...',
                        hintStyle: GoogleFonts.poppins(),
                        prefixIcon: Icon(Icons.search, color: colorNaranja),
                        border: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterPreguntas();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        _filterPreguntas();
                        setState(() {});
                      },
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: -0.2, end: 0),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDesktop,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: isDesktop ? 28 : 24)
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
            fontSize: isDesktop ? 20 : 18,
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
    );
  }

  Widget _buildSelectApiarioPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Selecciona un Apiario',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Primero selecciona un apiario para gestionar\nsus preguntas de monitoreo',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreguntasList(bool isDesktop, bool isTablet) {
    if (filteredPreguntas.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
      child: ReorderableListView.builder(
        onReorder: _reorderPreguntas,
        itemCount: filteredPreguntas.length,
        itemBuilder: (context, index) {
          return _buildPreguntaCard(filteredPreguntas[index], index, isDesktop);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron preguntas'
                : 'No hay preguntas configuradas',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Agrega tu primera pregunta para comenzar',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreguntaCard(Pregunta pregunta, int index, bool isDesktop) {
    return Card(
          key: ValueKey(pregunta.id),
          elevation: 4,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  pregunta.activa ? Colors.white : Colors.grey[100]!,
                  pregunta.activa
                      ? colorAmbarClaro.withOpacity(0.3)
                      : Colors.grey[200]!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icono de arrastrar más prominente
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorNaranja.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.drag_handle,
                        color: colorNaranja,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),

                    // Número de orden más visible
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: pregunta.activa
                              ? [colorNaranja, colorAmarillo]
                              : [Colors.grey, Colors.grey[400]!],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (pregunta.activa ? colorNaranja : Colors.grey)
                                    .withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${pregunta.orden}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 16),

                    // Contenido de la pregunta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pregunta.texto,
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: pregunta.activa
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getTypeColor(pregunta.tipoRespuesta),
                                      _getTypeColor(
                                        pregunta.tipoRespuesta,
                                      ).withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getTypeColor(
                                        pregunta.tipoRespuesta,
                                      ).withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _getTypeLabel(pregunta.tipoRespuesta),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (pregunta.obligatoria) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.red, Colors.red[400]!],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Obligatoria',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Switch de activa/inactiva más visible
                    Column(
                      children: [
                        Switch(
                          value: pregunta.activa,
                          onChanged: (value) =>
                              _togglePreguntaActiva(pregunta, value),
                          activeColor: colorVerde,
                          activeTrackColor: colorVerde.withOpacity(0.3),
                        ),
                        Text(
                          pregunta.activa ? 'Activa' : 'Inactiva',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: pregunta.activa ? colorVerde : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(width: 8),

                    // Menú de opciones mejorado
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorNaranja.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.more_vert, color: colorNaranja),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showPreguntaDialog(pregunta: pregunta);
                            break;
                          case 'duplicate':
                            _duplicatePregunta(pregunta);
                            break;
                          case 'delete':
                            _confirmDeletePregunta(pregunta);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: colorNaranja),
                              SizedBox(width: 12),
                              Text('Editar', style: GoogleFonts.poppins()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, color: colorAmarillo),
                              SizedBox(width: 12),
                              Text('Duplicar', style: GoogleFonts.poppins()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Eliminar', style: GoogleFonts.poppins()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Mostrar opciones de manera más elegante
                if (pregunta.opciones != null &&
                    pregunta.opciones!.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list, color: colorNaranja, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Opciones disponibles:',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorNaranja,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: pregunta.opciones!.asMap().entries.map((
                            entry,
                          ) {
                            int index = entry.key;
                            Opcion opcion = entry.value;
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorVerde.withOpacity(0.8),
                                    colorVerde.withOpacity(0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorVerde.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${index + 1}.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    opcion.valor,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                // Información adicional
                if (isDesktop) ...[
                  SizedBox(height: 12),
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ID: ${pregunta.id}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      Spacer(),
                      if (pregunta.fechaCreacion != null) ...[
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Creada: ${DateFormat('dd/MM/yyyy').format(pregunta.fechaCreacion!)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 * index),
          duration: 600.ms,
        )
        .slideY(begin: 0.2, end: 0);
  }

  Color _getTypeColor(String? tipo) {
    switch (tipo) {
      case 'opciones':
        return colorVerde;
      case 'numero':
        return colorNaranja;
      case 'rango':
        return Colors.purple;
      default:
        return colorAmarillo;
    }
  }

  String _getTypeLabel(String? tipo) {
    switch (tipo) {
      case 'opciones':
        return 'Opciones';
      case 'numero':
        return 'Número';
      case 'rango':
        return 'Rango';
      default:
        return 'Texto';
    }
  }

  // Reordenar preguntas
  void _reorderPreguntas(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = filteredPreguntas.removeAt(oldIndex);
      filteredPreguntas.insert(newIndex, item);

      // Actualizar orden
      for (int i = 0; i < filteredPreguntas.length; i++) {
        filteredPreguntas[i] = filteredPreguntas[i].copyWith(orden: i + 1);
      }
    });

    _saveOrder();
  }

  // Guardar orden de preguntas
  Future<void> _saveOrder() async {
    try {
      for (final pregunta in filteredPreguntas) {
        await dbService.savePregunta(pregunta);
      }

      if (isConnected && selectedApiarioId != null) {
        try {
          final orden = filteredPreguntas.map((p) => p.id).toList();
          await ApiService.reordenarPreguntas(selectedApiarioId!, orden);
        } catch (e) {
          debugPrint("⚠️ Error al sincronizar orden: $e");
        }
      }
    } catch (e) {
      debugPrint("❌ Error al guardar orden: $e");
    }
  }

  // Toggle pregunta activa/inactiva
  Future<void> _togglePreguntaActiva(Pregunta pregunta, bool activa) async {
    try {
      final updatedPregunta = pregunta.copyWith(activa: activa);
      await dbService.savePregunta(updatedPregunta);

      if (isConnected) {
        try {
          await ApiService.actualizarPregunta(
            pregunta.id,
            updatedPregunta.toJson(),
          );
        } catch (e) {
          debugPrint("⚠️ Error al sincronizar estado: $e");
        }
      }

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al actualizar estado: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Diálogo para crear/editar pregunta
  void _showPreguntaDialog({Pregunta? pregunta}) {
    final isEditing = pregunta != null;

    if (isEditing) {
      _preguntaController.text = pregunta.texto;
      tipoRespuestaSeleccionado = pregunta.tipoRespuesta ?? "texto";
      opcionesTemporales =
          pregunta.opciones
              ?.map((o) => Opcion(valor: o.valor, descripcion: o.descripcion))
              .toList() ??
          [];
    } else {
      _preguntaController.clear();
      tipoRespuestaSeleccionado = "texto";
      opcionesTemporales.clear();
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
              gradient: LinearGradient(colors: [colorNaranja, colorAmarillo]),
              borderRadius: BorderRadius.only(
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
                SizedBox(width: 12),
                Text(
                  isEditing ? 'Editar Pregunta' : 'Nueva Pregunta',
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
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),

                  // Texto de la pregunta
                  Container(
                    decoration: BoxDecoration(
                      color: colorAmbarClaro.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorAmarillo.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _preguntaController,
                      decoration: InputDecoration(
                        labelText: 'Texto de la pregunta',
                        labelStyle: GoogleFonts.poppins(color: colorNaranja),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        prefixIcon: Icon(Icons.quiz, color: colorNaranja),
                      ),
                      maxLines: 3,
                      style: GoogleFonts.poppins(),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Tipo de respuesta
                  Text(
                    'Tipo de respuesta:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: colorNaranja,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorAmarillo.withOpacity(0.3)),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            {"texto": "Texto libre"},
                            {"opciones": "Opciones múltiples"},
                            {"numero": "Número"},
                            {"rango": "Rango de valores"},
                          ].map((Map<String, String> tipo) {
                            String key = tipo.keys.first;
                            String label = tipo.values.first;
                            bool isSelected = tipoRespuestaSeleccionado == key;

                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  tipoRespuestaSeleccionado = key;
                                  if (key == "texto") {
                                    opcionesTemporales.clear();
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [colorAmarillo, colorNaranja],
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorNaranja
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getTypeIcon(key),
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      label,
                                      style: GoogleFonts.poppins(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  // Sección de opciones mejorada
                  if (tipoRespuestaSeleccionado == "opciones" ||
                      tipoRespuestaSeleccionado == "rango") ...[
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorVerde.withOpacity(0.1),
                            colorVerde.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorVerde.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.list_alt, color: colorVerde, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Configurar opciones:',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: colorVerde,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          // Lista de opciones actuales
                          if (opcionesTemporales.isNotEmpty)
                            Container(
                              constraints: BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: opcionesTemporales.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      leading: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: colorVerde,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        opcionesTemporales[index].valor,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setDialogState(() {
                                            opcionesTemporales.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          SizedBox(height: 12),

                          // Agregar nueva opción
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorVerde.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _opcionController,
                                    decoration: InputDecoration(
                                      hintText: 'Escribir nueva opción...',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.add_circle_outline,
                                        color: colorVerde,
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(),
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        setDialogState(() {
                                          opcionesTemporales.add(
                                            Opcion(valor: value.trim()),
                                          );
                                          _opcionController.clear();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.all(4),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_opcionController.text
                                          .trim()
                                          .isNotEmpty) {
                                        setDialogState(() {
                                          opcionesTemporales.add(
                                            Opcion(
                                              valor: _opcionController.text
                                                  .trim(),
                                            ),
                                          );
                                          _opcionController.clear();
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorVerde,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Agregar',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
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
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _opcionController.clear();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
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
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _savePregunta(pregunta),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorVerde,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, size: 18),
                          SizedBox(width: 8),
                          Text(
                            isEditing ? 'Actualizar' : 'Crear Pregunta',
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
      ),
    );
  }

  IconData _getTypeIcon(String tipo) {
    switch (tipo) {
      case 'opciones':
        return Icons.radio_button_checked;
      case 'numero':
        return Icons.numbers;
      case 'rango':
        return Icons.tune;
      default:
        return Icons.text_fields;
    }
  }

  // Guardar pregunta
  Future<void> _savePregunta(Pregunta? existingPregunta) async {
    if (_preguntaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor ingresa el texto de la pregunta',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((tipoRespuestaSeleccionado == "opciones" ||
            tipoRespuestaSeleccionado == "rango") &&
        opcionesTemporales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor agrega al menos una opción',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      Navigator.pop(context);
      _opcionController.clear();

      final pregunta =
          existingPregunta?.copyWith(
            texto: _preguntaController.text.trim(),
            tipoRespuesta: tipoRespuestaSeleccionado,
            opciones: tipoRespuestaSeleccionado != "texto"
                ? List<Opcion>.from(opcionesTemporales)
                : null,
          ) ??
          Pregunta(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            texto: _preguntaController.text.trim(),
            seleccionada: false,
            tipoRespuesta: tipoRespuestaSeleccionado,
            opciones: tipoRespuestaSeleccionado != "texto"
                ? List<Opcion>.from(opcionesTemporales)
                : null,
            orden: preguntas.length + 1,
            activa: true,
            apiarioId: selectedApiarioId,
            fechaCreacion: DateTime.now(),
          );

      await dbService.savePregunta(pregunta);

      if (isConnected) {
        try {
          if (existingPregunta != null) {
            await ApiService.actualizarPregunta(pregunta.id, pregunta.toJson());
          } else {
            await ApiService.crearPregunta(pregunta);
          }
        } catch (e) {
          debugPrint("⚠️ Error al sincronizar pregunta: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingPregunta != null
                ? 'Pregunta actualizada correctamente'
                : 'Pregunta creada correctamente',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: colorVerde,
        ),
      );

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Duplicar pregunta
  Future<void> _duplicatePregunta(Pregunta pregunta) async {
    try {
      final duplicatedPregunta = Pregunta(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        texto: "${pregunta.texto} (Copia)",
        seleccionada: false,
        tipoRespuesta: pregunta.tipoRespuesta,
        opciones: pregunta.opciones
            ?.map((o) => Opcion(valor: o.valor, descripcion: o.descripcion))
            .toList(),
        orden: preguntas.length + 1,
        activa: true,
        apiarioId: selectedApiarioId,
        fechaCreacion: DateTime.now(),
      );

      await dbService.savePregunta(duplicatedPregunta);

      if (isConnected) {
        try {
          await ApiService.crearPregunta(duplicatedPregunta);
        } catch (e) {
          debugPrint("⚠️ Error al sincronizar duplicación: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pregunta duplicada correctamente',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: colorVerde,
        ),
      );

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al duplicar: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Confirmar eliminación de pregunta
  void _confirmDeletePregunta(Pregunta pregunta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar Eliminación',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar esta pregunta?\n\n"${pregunta.texto}"',
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
            onPressed: () => _deletePregunta(pregunta),
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

  // Eliminar pregunta
  Future<void> _deletePregunta(Pregunta pregunta) async {
    try {
      Navigator.pop(context);

      await dbService.deletePregunta(pregunta.id);

      if (isConnected) {
        try {
          await ApiService.eliminarPregunta(pregunta.id);
        } catch (e) {
          debugPrint("⚠️ Error al sincronizar eliminación: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pregunta eliminada correctamente',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: colorVerde,
        ),
      );

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Sincronizar datos
  Future<void> _syncData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Sincronizando preguntas...",
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
            "Preguntas sincronizadas correctamente",
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
