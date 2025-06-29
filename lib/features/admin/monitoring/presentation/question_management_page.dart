import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/monitoring/service/enhaced_api_service.dart';
import 'package:sotfbee/features/admin/monitoring/widgets/enhanced_card_widget.dart';
import '../models/enhanced_models.dart';

class QuestionsManagementScreen extends StatefulWidget {
  const QuestionsManagementScreen({Key? key}) : super(key: key);

  @override
  _QuestionsManagementScreenState createState() =>
      _QuestionsManagementScreenState();
}

class _QuestionsManagementScreenState extends State<QuestionsManagementScreen> {
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
  int? selectedApiarioId;
  bool obligatoriaSeleccionada = false;

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
      
      if (selectedApiarioId != null) {
        preguntas = await EnhancedApiService.obtenerPreguntasApiario(
          selectedApiarioId!,
          soloActivas: false,
        );
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

  void _filterPreguntas() {
    final query = _searchController.text.toLowerCase();
    filteredPreguntas = preguntas.where((pregunta) {
      return pregunta.texto.toLowerCase().contains(query);
    }).toList();
    
    // Ordenar por orden
    filteredPreguntas.sort((a, b) => a.orden.compareTo(b.orden));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: CustomAppBarWidget(
        title: 'Gestión de Preguntas',
        isConnected: isConnected,
        onSync: _syncData,
      ),
      body: isLoading 
        ? LoadingWidget(message: "Cargando preguntas...", color: colorNaranja)
        : _buildBody(isTablet),
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
            ).animate().scale(delay: 800.ms)
          : null,
    );
  }

  Widget _buildBody(bool isTablet) {
    return Column(
      children: [
        _buildHeader(isTablet),
        Expanded(
          child: selectedApiarioId == null
              ? _buildSelectApiarioPrompt()
              : _buildPreguntasList(isTablet),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Selector de apiario
          EnhancedCardWidget(
            title: 'Seleccionar Apiario',
            icon: Icons.location_on,
            color: colorNaranja,
            isCompact: true,
            animationDelay: 0,
            trailing: Container(
              width: 200,
              child: DropdownButtonFormField<int>(
                value: selectedApiarioId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Selecciona...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                ),
                items: apiarios.map((apiario) {
                  return DropdownMenuItem<int>(
                    value: apiario.id,
                    child: Text(
                      apiario.nombre,
                      style: GoogleFonts.poppins(fontSize: 12),
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
            ),
          ),

          if (selectedApiarioId != null) ...[
            SizedBox(height: 12),

            // Estadísticas
            Row(
              children: [
                Expanded(
                  child: StatCardWidget(
                    label: 'Total',
                    value: preguntas.length.toString(),
                    icon: Icons.quiz,
                    color: colorVerde,
                    isCompact: true,
                    animationDelay: 100,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatCardWidget(
                    label: 'Activas',
                    value: preguntas.where((p) => p.activa).length.toString(),
                    icon: Icons.check_circle,
                    color: colorAmarillo,
                    isCompact: true,
                    animationDelay: 200,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatCardWidget(
                    label: 'Con Opciones',
                    value: preguntas
                        .where((p) => p.opciones != null && p.opciones!.isNotEmpty)
                        .length
                        .toString(),
                    icon: Icons.list,
                    color: colorNaranja,
                    isCompact: true,
                    animationDelay: 300,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Barra de búsqueda
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  hintText: 'Buscar preguntas...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  prefixIcon: Icon(Icons.search, color: colorNaranja, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey, size: 18),
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
            ).animate().fadeIn(delay: 400.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectApiarioPrompt() {
    return EmptyStateWidget(
      icon: Icons.quiz,
      title: 'Selecciona un Apiario',
      subtitle: 'Primero selecciona un apiario para gestionar\nsus preguntas de monitoreo',
      color: colorNaranja,
    );
  }

  Widget _buildPreguntasList(bool isTablet) {
    if (filteredPreguntas.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.quiz_outlined,
        title: _searchController.text.isNotEmpty
            ? 'No se encontraron preguntas'
            : 'No hay preguntas configuradas',
        subtitle: _searchController.text.isNotEmpty
            ? 'Intenta con otros términos de búsqueda'
            : 'Agrega tu primera pregunta para comenzar',
        actionText: _searchController.text.isEmpty ? 'Crear Pregunta' : null,
        onAction: _searchController.text.isEmpty ? () => _showPreguntaDialog() : null,
        color: colorNaranja,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ReorderableListView.builder(
        onReorder: _reorderPreguntas,
        itemCount: filteredPreguntas.length,
        itemBuilder: (context, index) {
          return _buildPreguntaCard(filteredPreguntas[index], index);
        },
      ),
    );
  }

  Widget _buildPreguntaCard(Pregunta pregunta, int index) {
    return Card(
      key: ValueKey(pregunta.id),
      elevation: 1,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pregunta.activa ? Colors.white : Colors.grey[100]!,
              pregunta.activa
                  ? colorAmbarClaro.withOpacity(0.2)
                  : Colors.grey[200]!,
            ],
          ),
        ),
        child: Row(
          children: [
            // Handle de arrastre
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorNaranja.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.drag_handle,
                color: colorNaranja,
                size: 16,
              ),
            ),

            SizedBox(width: 8),

            // Número de orden
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: pregunta.activa
                      ? [colorNaranja, colorAmarillo]
                      : [Colors.grey, Colors.grey[400]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${pregunta.orden}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pregunta.texto,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: pregunta.activa ? Colors.black87 : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTypeColor(pregunta.tipoRespuesta),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getTypeLabel(pregunta.tipoRespuesta),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (pregunta.obligatoria) ...[
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Obligatoria',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (pregunta.opciones != null && pregunta.opciones!.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: pregunta.opciones!.take(3).map((opcion) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorVerde.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorVerde.withOpacity(0.3)),
                          ),
                          child: Text(
                            opcion.valor,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: colorVerde,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Switch y menú
            Column(
              children: [
                Switch(
                  value: pregunta.activa,
                  onChanged: (value) => _togglePreguntaActiva(pregunta, value),
                  activeColor: colorVerde,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: colorNaranja),
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
                          Icon(Icons.edit, color: colorNaranja, size: 16),
                          SizedBox(width: 8),
                          Text('Editar', style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, color: colorAmarillo, size: 16),
                          SizedBox(width: 8),
                          Text('Duplicar', style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Eliminar', style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 50 * index),
      duration: 400.ms,
    ).slideX(begin: 0.2, end: 0);
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
      if (selectedApiarioId != null) {
        final orden = filteredPreguntas.map((p) => p.id).toList();
        await EnhancedApiService.reordenarPreguntas(selectedApiarioId!, orden);
      }
    } catch (e) {
      debugPrint("❌ Error al guardar orden: $e");
    }
  }

  // Toggle pregunta activa/inactiva
  Future<void> _togglePreguntaActiva(Pregunta pregunta, bool activa) async {
    try {
      final updatedPregunta = pregunta.copyWith(activa: activa);
      await EnhancedApiService.actualizarPregunta(
        pregunta.id,
        updatedPregunta.toJson(),
      );
      await _loadData();
    } catch (e) {
      _showSnackBar('Error al actualizar estado: $e', Colors.red);
    }
  }

  // Diálogo para crear/editar pregunta
  void _showPreguntaDialog({Pregunta? pregunta}) {
    final isEditing = pregunta != null;

    if (isEditing) {
      _preguntaController.text = pregunta.texto;
      tipoRespuestaSeleccionado = pregunta.tipoRespuesta ?? "texto";
      obligatoriaSeleccionada = pregunta.obligatoria;
      opcionesTemporales = List.from(pregunta.opciones ?? []);
    } else {
      _preguntaController.clear();
      tipoRespuestaSeleccionado = "texto";
      obligatoriaSeleccionada = false;
      opcionesTemporales.clear();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),

                // Texto de la pregunta
                TextField(
                  controller: _preguntaController,
                  decoration: InputDecoration(
                    labelText: 'Texto de la pregunta',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorAmarillo, width: 2),
                    ),
                    prefixIcon: Icon(Icons.quiz, color: colorNaranja),
                  ),
                  style: GoogleFonts.poppins(),
                  maxLines: 2,
                ),

                SizedBox(height: 16),

                // Tipo de respuesta
                Text(
                  'Tipo de respuesta',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tipoRespuestaSeleccionado,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorAmarillo, width: 2),
                    ),
                    prefixIcon: Icon(Icons.category, color: colorNaranja),
                  ),
                  items: [
                    DropdownMenuItem(value: "texto", child: Text("Texto libre", style: GoogleFonts.poppins())),
                    DropdownMenuItem(value: "numero", child: Text("Número", style: GoogleFonts.poppins())),
                    DropdownMenuItem(value: "opciones", child: Text("Opciones múltiples", style: GoogleFonts.poppins())),
                    DropdownMenuItem(value: "rango", child: Text("Rango (1-10)", style: GoogleFonts.poppins())),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tipoRespuestaSeleccionado = value!;
                      if (value != "opciones") {
                        opcionesTemporales.clear();
                      }
                    });
                  },
                ),

                SizedBox(height: 16),

                // Checkbox obligatoria
                Row(
                  children: [
                    Checkbox(
                      value: obligatoriaSeleccionada,
                      onChanged: (value) {
                        setDialogState(() {
                          obligatoriaSeleccionada = value ?? false;
                        });
                      },
                      activeColor: colorVerde,
                    ),
                    Text(
                      'Pregunta obligatoria',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ],
                ),

                // Opciones (solo si el tipo es "opciones")
                if (tipoRespuestaSeleccionado == "opciones") ...[
                  SizedBox(height: 16),
                  Text(
                    'Opciones de respuesta',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Lista de opciones existentes
                  if (opcionesTemporales.isNotEmpty) ...[
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: opcionesTemporales.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(
                              opcionesTemporales[index].valor,
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red, size: 18),
                              onPressed: () {
                                setDialogState(() {
                                  opcionesTemporales.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                  ],

                  // Campo para agregar nueva opción
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _opcionController,
                          decoration: InputDecoration(
                            hintText: 'Nueva opción...',
                            hintStyle: GoogleFonts.poppins(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: GoogleFonts.poppins(fontSize: 13),
                          onSubmitted: (value) => _addOpcion(setDialogState),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _addOpcion(setDialogState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorVerde,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                ],
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
      ),
    );
  }

  void _addOpcion(StateSetter setDialogState) {
    if (_opcionController.text.trim().isNotEmpty) {
      setDialogState(() {
        opcionesTemporales.add(Opcion(
          valor: _opcionController.text.trim(),
          orden: opcionesTemporales.length + 1,
        ));
        _opcionController.clear();
      });
    }
  }

  // Guardar pregunta
  Future<void> _savePregunta(Pregunta? existingPregunta) async {
    if (_preguntaController.text.trim().isEmpty) {
      _showSnackBar('Por favor ingresa el texto de la pregunta', Colors.red);
      return;
    }

    if (tipoRespuestaSeleccionado == "opciones" && opcionesTemporales.isEmpty) {
      _showSnackBar('Agrega al menos una opción de respuesta', Colors.red);
      return;
    }

    try {
      Navigator.pop(context);

      final nuevaPregunta = Pregunta(
        id: existingPregunta?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        texto: _preguntaController.text.trim(),
        seleccionada: false,
        tipoRespuesta: tipoRespuestaSeleccionado,
        obligatoria: obligatoriaSeleccionada,
        opciones: tipoRespuestaSeleccionado == "opciones" ? opcionesTemporales : null,
        orden: existingPregunta?.orden ?? (preguntas.length + 1),
        activa: existingPregunta?.activa ?? true,
        apiarioId: selectedApiarioId,
      );

      if (existingPregunta != null) {
        // Actualizar pregunta existente
        await EnhancedApiService.actualizarPregunta(
          existingPregunta.id,
          nuevaPregunta.toJson(),
        );
        _showSnackBar('Pregunta actualizada correctamente', colorVerde);
      } else {
        // Crear nueva pregunta
        await EnhancedApiService.crearPregunta(nuevaPregunta);
        _showSnackBar('Pregunta creada correctamente', colorVerde);
      }

      await _loadData();
    } catch (e) {
      _showSnackBar('Error al guardar: $e', Colors.red);
    }
  }

  // Duplicar pregunta
  Future<void> _duplicatePregunta(Pregunta pregunta) async {
    try {
      final duplicada = Pregunta(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        texto: "${pregunta.texto} (Copia)",
        seleccionada: false,
        tipoRespuesta: pregunta.tipoRespuesta,
        obligatoria: pregunta.obligatoria,
        opciones: pregunta.opciones?.map((o) => Opcion(
          valor: o.valor,
          descripcion: o.descripcion,
          orden: o.orden,
        )).toList(),
        orden: preguntas.length + 1,
        activa: true,
        apiarioId: selectedApiarioId,
      );

      await EnhancedApiService.crearPregunta(duplicada);
      _showSnackBar('Pregunta duplicada correctamente', colorVerde);
      await _loadData();
    } catch (e) {
      _showSnackBar('Error al duplicar: $e', Colors.red);
    }
  }

  // Confirmar eliminación
  void _confirmDeletePregunta(Pregunta pregunta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirmar Eliminación',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la pregunta "${pregunta.texto}"?',
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

      await EnhancedApiService.eliminarPregunta(pregunta.id);
      _showSnackBar('Pregunta eliminada correctamente', colorVerde);
      await _loadData();
    } catch (e) {
      _showSnackBar('Error al eliminar: $e', Colors.red);
    }
  }

  // Sincronizar datos
  Future<void> _syncData() async {
    try {
      _showSnackBar("Sincronizando preguntas...", colorAmarillo);

      await _checkConnection();
      await _loadData();

      _showSnackBar("Preguntas sincronizadas correctamente", colorVerde);
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
    _preguntaController.dispose();
    _opcionController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
