import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/model.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

class ApiariosManagementScreen extends StatefulWidget {
  const ApiariosManagementScreen({Key? key}) : super(key: key);

  @override
  _ApiariosManagementScreenState createState() =>
      _ApiariosManagementScreenState();
}

class _ApiariosManagementScreenState extends State<ApiariosManagementScreen>
    with SingleTickerProviderStateMixin {
  // Servicios
  late LocalDBService dbService;

  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Estado
  List<Apiario> apiarios = [];
  List<Apiario> filteredApiarios = [];
  bool isLoading = true;
  bool isConnected = false;
  Apiario? editingApiario;

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
      await _loadApiarios();
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

  Future<void> _loadApiarios() async {
    try {
      // Cargar desde base de datos local
      apiarios = await dbService.getApiarios();

      // Intentar sincronizar con servidor si hay conexión
      if (await ApiService.hasInternetConnection()) {
        try {
          final serverApiarios = await ApiService.obtenerApiarios();
          // Actualizar base de datos local
          for (final apiario in serverApiarios) {
            await dbService.insertApiario(apiario);
          }
          apiarios = serverApiarios;
        } catch (e) {
          debugPrint("⚠️ No se pudo sincronizar con servidor");
        }
      }

      _filterApiarios();
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error al cargar apiarios: $e");
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

  void _filterApiarios() {
    final query = _searchController.text.toLowerCase();
    filteredApiarios = apiarios.where((apiario) {
      return apiario.nombre.toLowerCase().contains(query) ||
          apiario.ubicacion.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
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
          'Gestión de Apiarios',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApiarioDialog(),
        backgroundColor: colorVerde,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nuevo Apiario',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
            "Cargando apiarios...",
            style: GoogleFonts.poppins(fontSize: 16, color: colorNaranja),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        // Barra de búsqueda y estadísticas
        _buildHeader(isDesktop, isTablet),

        // Lista de apiarios
        Expanded(child: _buildApiariosList(isDesktop, isTablet)),
      ],
    );
  }

  Widget _buildHeader(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        children: [
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
                    'Total Apiarios',
                    apiarios.length.toString(),
                    Icons.location_on,
                    colorVerde,
                    isDesktop,
                  ),
                  _buildStatItem(
                    'Activos',
                    apiarios.length.toString(),
                    Icons.check_circle,
                    colorAmarillo,
                    isDesktop,
                  ),
                  _buildStatItem(
                    'Sincronizados',
                    isConnected ? apiarios.length.toString() : '0',
                    Icons.sync,
                    isConnected ? colorVerde : Colors.grey,
                    isDesktop,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),

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
                      hintText: 'Buscar apiarios...',
                      hintStyle: GoogleFonts.poppins(),
                      prefixIcon: Icon(Icons.search, color: colorNaranja),
                      border: InputBorder.none,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _filterApiarios();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      _filterApiarios();
                      setState(() {});
                    },
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: -0.2, end: 0),
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

  Widget _buildApiariosList(bool isDesktop, bool isTablet) {
    if (filteredApiarios.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
      child: isDesktop ? _buildDesktopGrid() : _buildMobileList(isTablet),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron apiarios'
                : 'No hay apiarios configurados',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Agrega tu primer apiario para comenzar',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: filteredApiarios.length,
      itemBuilder: (context, index) {
        return _buildApiarioCard(filteredApiarios[index], index, true);
      },
    );
  }

  Widget _buildMobileList(bool isTablet) {
    return ListView.builder(
      itemCount: filteredApiarios.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _buildApiarioCard(filteredApiarios[index], index, false),
        );
      },
    );
  }

  Widget _buildApiarioCard(Apiario apiario, int index, bool isDesktop) {
    return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showApiarioDetails(apiario),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, colorAmbarClaro.withOpacity(0.3)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorAmarillo.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: colorNaranja,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apiario.nombre,
                              style: GoogleFonts.poppins(
                                fontSize: isDesktop ? 18 : 16,
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showApiarioDialog(apiario: apiario);
                              break;
                            case 'delete':
                              _confirmDelete(apiario);
                              break;
                            case 'colmenas':
                              _showColmenas(apiario);
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
                            value: 'colmenas',
                            child: Row(
                              children: [
                                Icon(Icons.hive, color: colorAmarillo),
                                SizedBox(width: 8),
                                Text('Ver Colmenas'),
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
                    ],
                  ),

                  if (isDesktop) ...[
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Creado: ${apiario.fechaCreacion?.toString().split(' ')[0] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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

  // Diálogo para crear/editar apiario
  void _showApiarioDialog({Apiario? apiario}) {
    final isEditing = apiario != null;

    if (isEditing) {
      _nombreController.text = apiario.nombre;
      _ubicacionController.text = apiario.ubicacion;
    } else {
      _nombreController.clear();
      _ubicacionController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEditing ? 'Editar Apiario' : 'Nuevo Apiario',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del Apiario',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorAmarillo, width: 2),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _ubicacionController,
              decoration: InputDecoration(
                labelText: 'Ubicación',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorAmarillo, width: 2),
                ),
              ),
              maxLines: 2,
            ),
          ],
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
            onPressed: () => _saveApiario(apiario),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorVerde,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isEditing ? 'Actualizar' : 'Crear',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Guardar apiario
  Future<void> _saveApiario(Apiario? existingApiario) async {
    if (_nombreController.text.trim().isEmpty ||
        _ubicacionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor completa todos los campos',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      Navigator.pop(context);

      if (existingApiario != null) {
        // Actualizar apiario existente
        final updatedApiario = existingApiario.copyWith(
          nombre: _nombreController.text.trim(),
          ubicacion: _ubicacionController.text.trim(),
        );

        await dbService.updateApiario(updatedApiario);

        if (isConnected) {
          try {
            await ApiService.actualizarApiario(
              updatedApiario.id,
              updatedApiario.toJson(),
            );
          } catch (e) {
            debugPrint("⚠️ Error al sincronizar actualización: $e");
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Apiario actualizado correctamente',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: colorVerde,
          ),
        );
      } else {
        // Crear nuevo apiario
        final newApiario = Apiario(
          id: DateTime.now().millisecondsSinceEpoch,
          nombre: _nombreController.text.trim(),
          ubicacion: _ubicacionController.text.trim(),
          fechaCreacion: DateTime.now(),
        );

        await dbService.insertApiario(newApiario);

        if (isConnected) {
          try {
            await ApiService.crearApiario(newApiario.toJson());
          } catch (e) {
            debugPrint("⚠️ Error al sincronizar creación: $e");
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Apiario creado correctamente',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: colorVerde,
          ),
        );
      }

      await _loadApiarios();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Confirmar eliminación
  void _confirmDelete(Apiario apiario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar Eliminación',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el apiario "${apiario.nombre}"?',
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
            onPressed: () => _deleteApiario(apiario),
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

  // Eliminar apiario
  Future<void> _deleteApiario(Apiario apiario) async {
    try {
      Navigator.pop(context);

      await dbService.deleteApiario(apiario.id);

      if (isConnected) {
        try {
          await ApiService.eliminarApiario(apiario.id);
        } catch (e) {
          debugPrint("⚠️ Error al sincronizar eliminación: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Apiario eliminado correctamente',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: colorVerde,
        ),
      );

      await _loadApiarios();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mostrar detalles del apiario
  void _showApiarioDetails(Apiario apiario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            _buildDetailRow(
              'Fecha de creación:',
              apiario.fechaCreacion?.toString().split(' ')[0] ?? 'N/A',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
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
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  // Mostrar colmenas del apiario
  void _showColmenas(Apiario apiario) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Función de gestión de colmenas en desarrollo',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Sincronizar datos
  Future<void> _syncData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Sincronizando apiarios...",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: colorAmarillo,
        ),
      );

      await _checkConnection();
      await _loadApiarios();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Apiarios sincronizados correctamente",
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
