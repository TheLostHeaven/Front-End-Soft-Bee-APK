import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/beehive_management_page.dart';
import 'package:sotfbee/features/admin/monitoring/service/enhaced_api_service.dart';
import 'package:sotfbee/features/admin/monitoring/widgets/enhanced_card_widget.dart';
import '../models/enhanced_models.dart';

class ApiariosManagementScreen extends StatefulWidget {
  const ApiariosManagementScreen({Key? key}) : super(key: key);

  @override
  _ApiariosManagementScreenState createState() =>
      _ApiariosManagementScreenState();
}

class _ApiariosManagementScreenState extends State<ApiariosManagementScreen>
    with SingleTickerProviderStateMixin {
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
      apiarios = await EnhancedApiService.obtenerApiarios();
      _filterApiarios();
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error al cargar apiarios: $e");
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

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: CustomAppBarWidget(
        title: 'Gestión de Apiarios',
        isConnected: isConnected,
        onSync: _syncData,
      ),
      body: isLoading
          ? LoadingWidget(message: "Cargando apiarios...", color: colorNaranja)
          : _buildBody(isTablet),
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
      ).animate().scale(delay: 800.ms),
    );
  }

  Widget _buildBody(bool isTablet) {
    return Column(
      children: [
        // Header con estadísticas y búsqueda
        _buildHeader(isTablet),
        // Lista de apiarios
        Expanded(child: _buildApiariosList(isTablet)),
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
                  label: 'Total Apiarios',
                  value: apiarios.length.toString(),
                  icon: Icons.location_on,
                  color: colorVerde,
                  animationDelay: 0,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCardWidget(
                  label: 'Activos',
                  value: apiarios.length.toString(),
                  icon: Icons.check_circle,
                  color: colorAmarillo,
                  animationDelay: 100,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCardWidget(
                  label: 'Sincronizados',
                  value: isConnected ? apiarios.length.toString() : '0',
                  icon: Icons.sync,
                  color: isConnected ? colorVerde : Colors.grey,
                  animationDelay: 200,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

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
                hintText: 'Buscar apiarios...',
                hintStyle: GoogleFonts.poppins(fontSize: 14),
                prefixIcon: Icon(Icons.search, color: colorNaranja),
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
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildApiariosList(bool isTablet) {
    if (filteredApiarios.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.location_off,
        title: _searchController.text.isNotEmpty
            ? 'No se encontraron apiarios'
            : 'No hay apiarios configurados',
        subtitle: _searchController.text.isNotEmpty
            ? 'Intenta con otros términos de búsqueda'
            : 'Agrega tu primer apiario para comenzar',
        actionText: _searchController.text.isEmpty ? 'Crear Apiario' : null,
        onAction: _searchController.text.isEmpty
            ? () => _showApiarioDialog()
            : null,
        color: colorNaranja,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: isTablet ? _buildDesktopGrid() : _buildMobileList(),
    );
  }

  Widget _buildDesktopGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: filteredApiarios.length,
      itemBuilder: (context, index) {
        return _buildApiarioCard(filteredApiarios[index], index, true);
      },
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: filteredApiarios.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _buildApiarioCard(filteredApiarios[index], index, false),
        );
      },
    );
  }

  Widget _buildApiarioCard(Apiario apiario, int index, bool isDesktop) {
    return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showApiarioDetails(apiario),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 16 : 12),
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
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorAmarillo.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: colorNaranja,
                          size: isDesktop ? 20 : 18,
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
                                fontSize: isDesktop ? 16 : 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              apiario.ubicacion,
                              style: GoogleFonts.poppins(
                                fontSize: isDesktop ? 12 : 11,
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
                                Icon(Icons.edit, color: colorNaranja, size: 18),
                                SizedBox(width: 8),
                                Text('Editar', style: GoogleFonts.poppins()),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'colmenas',
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(
                                  context,
                                ); // Cierra el menú emergente
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ColmenasManagementScreen(),
                                  ), // Reemplaza con tu widget de destino
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.hive,
                                    color: colorAmarillo,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ver Colmenas',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Eliminar', style: GoogleFonts.poppins()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (isDesktop) ...[
                    SizedBox(height: 12),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Creado: ${apiario.fechaCreacion?.toString().split(' ')[0] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
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
                isEditing ? 'Editar Apiario' : 'Nuevo Apiario',
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
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
                prefixIcon: Icon(Icons.location_city, color: colorNaranja),
              ),
              style: GoogleFonts.poppins(),
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
                prefixIcon: Icon(Icons.place, color: colorNaranja),
              ),
              style: GoogleFonts.poppins(),
              maxLines: 2,
            ),
          ],
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
                    onPressed: () => _saveApiario(apiario),
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
    );
  }

  // Guardar apiario
  Future<void> _saveApiario(Apiario? existingApiario) async {
    if (_nombreController.text.trim().isEmpty ||
        _ubicacionController.text.trim().isEmpty) {
      _showSnackBar('Por favor completa todos los campos', Colors.red);
      return;
    }

    try {
      Navigator.pop(context);

      if (existingApiario != null) {
        // Actualizar apiario existente
        final updatedData = {
          'name': _nombreController.text.trim(),
          'location': _ubicacionController.text.trim(),
        };

        await EnhancedApiService.actualizarApiario(
          existingApiario.id,
          updatedData,
        );

        _showSnackBar('Apiario actualizado correctamente', colorVerde);
      } else {
        // Crear nuevo apiario
        final newData = {
          'name': _nombreController.text.trim(),
          'location': _ubicacionController.text.trim(),
        };

        await EnhancedApiService.crearApiario(newData);

        _showSnackBar('Apiario creado correctamente', colorVerde);
      }

      await _loadApiarios();
    } catch (e) {
      _showSnackBar('Error al guardar: $e', Colors.red);
    }
  }

  // Confirmar eliminación
  void _confirmDelete(Apiario apiario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

      await EnhancedApiService.eliminarApiario(apiario.id);

      _showSnackBar('Apiario eliminado correctamente', colorVerde);

      await _loadApiarios();
    } catch (e) {
      _showSnackBar('Error al eliminar: $e', Colors.red);
    }
  }

  // Mostrar detalles del apiario
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
            _buildDetailRow(
              'Fecha de creación:',
              apiario.fechaCreacion?.toString().split(' ')[0] ?? 'N/A',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(color: colorNaranja),
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
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  // Mostrar colmenas del apiario
  void _showColmenas(Apiario apiario) {
    _showSnackBar('Función de gestión de colmenas en desarrollo', Colors.blue);
  }

  // Sincronizar datos
  Future<void> _syncData() async {
    try {
      _showSnackBar("Sincronizando apiarios...", colorAmarillo);

      await _checkConnection();
      await _loadApiarios();

      _showSnackBar("Apiarios sincronizados correctamente", colorVerde);
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
