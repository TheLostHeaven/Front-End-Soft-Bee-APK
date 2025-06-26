import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/inventory/models/inventory_item.dart';
import 'package:sotfbee/features/admin/inventory/service/inventory_service.dart';
import 'package:sotfbee/features/admin/inventory/widgets/error_widget.dart';
import 'package:sotfbee/features/admin/inventory/widgets/loading_widget.dart';


// Enum para definir los tipos de pantalla
enum ScreenType { mobile, tablet, desktop }

// Clase para manejar breakpoints responsivos
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1250;
  static const double desktop = 1400;

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

class GestionInventarioUpdated extends StatefulWidget {
  @override
  _GestionInventarioUpdatedState createState() =>
      _GestionInventarioUpdatedState();
}

class _GestionInventarioUpdatedState extends State<GestionInventarioUpdated>
    with SingleTickerProviderStateMixin {
  // Servicios
  final InventoryService _inventoryService = InventoryService();

  // Lista de insumos desde el backend
  List<InventoryItem> _inventoryItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Controladores para los formularios
  TextEditingController nombreController = TextEditingController();
  TextEditingController cantidadController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  // Clave para validación del formulario
  final _formKeyAgregar = GlobalKey<FormState>();

  // Variables de estado
  bool isEditing = false;
  InventoryItem? editingItem;
  String unidadSeleccionada = 'unit';

  // Lista de unidades disponibles
  final List<String> unidades = [
    'unit',
    'pair',
    'kg',
    'liter',
    'meter',
    'box',
    'gram',
    'ml',
    'dozen',
  ];

  // Controlador de animación
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _animationController.forward();
    _loadInventoryItems();
  }

  @override
  void dispose() {
    nombreController.dispose();
    cantidadController.dispose();
    searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Cargar items del inventario desde el backend
  Future<void> _loadInventoryItems() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final items = await _inventoryService.getInventoryItems();

      setState(() {
        _inventoryItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Método para agregar o editar insumos
  Future<void> _guardarInsumo() async {
    if (!_formKeyAgregar.currentState!.validate()) {
      return;
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => LoadingWidget(
          message: isEditing ? 'Actualizando insumo...' : 'Agregando insumo...',
        ),
      );

      if (isEditing && editingItem != null) {
        // Editar insumo existente
        final updatedItem = editingItem!.copyWith(
          itemName: nombreController.text.trim(),
          quantity: int.parse(cantidadController.text),
          unit: unidadSeleccionada,
        );

        await _inventoryService.updateInventoryItem(updatedItem);
      } else {
        // Agregar nuevo insumo
        final newItem = InventoryItem(
          id: 0, // El backend asignará el ID
          itemName: nombreController.text.trim(),
          quantity: int.parse(cantidadController.text),
          unit: unidadSeleccionada,
          apiaryId: 1, // ID del apiario por defecto
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _inventoryService.createInventoryItem(newItem);
      }

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Cerrar diálogo de formulario
      Navigator.of(context).pop();

      // Recargar inventario
      await _loadInventoryItems();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                isEditing
                    ? 'Insumo actualizado correctamente'
                    : 'Insumo agregado correctamente',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Limpiar formulario
      _limpiarFormulario();
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      Navigator.of(context).pop();

      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error: ${e.toString()}',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // Método para limpiar el formulario
  void _limpiarFormulario() {
    nombreController.clear();
    cantidadController.clear();
    unidadSeleccionada = 'unit';
    isEditing = false;
    editingItem = null;
  }

  // Método para editar insumos
  void _editarInsumo(InventoryItem insumo) {
    nombreController.text = insumo.itemName;
    cantidadController.text = insumo.quantity.toString();
    unidadSeleccionada = insumo.unit;
    isEditing = true;
    editingItem = insumo;

    _mostrarDialogoAgregar();
  }

  // Método para eliminar insumos
  Future<void> _eliminarInsumo(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text(
                '¿Eliminar insumo?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Esta acción no se puede deshacer. El insumo será eliminado permanentemente del inventario.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Eliminar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Mostrar indicador de carga
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => LoadingWidget(message: 'Eliminando insumo...'),
        );

        await _inventoryService.deleteInventoryItem(id);

        // Cerrar diálogo de carga
        Navigator.of(context).pop();

        // Recargar inventario
        await _loadInventoryItems();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Insumo eliminado correctamente',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        // Cerrar diálogo de carga
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al eliminar: ${e.toString()}',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // Método para mostrar diálogo de agregar/editar
  void _mostrarDialogoAgregar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_circle,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 8),
                  Text(
                    isEditing ? 'Editar Insumo' : 'Agregar Insumo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Form(
                key: _formKeyAgregar,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completa los detalles del insumo para tu apiario.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del insumo',
                        labelStyle: GoogleFonts.poppins(),
                        hintText: 'Ej: Traje de apicultor',
                        prefixIcon: Icon(
                          Icons.inventory_2,
                          color: Colors.amber,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                        errorStyle: GoogleFonts.poppins(color: Colors.red),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa un nombre';
                        }
                        if (value.trim().length < 3) {
                          return 'El nombre debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: cantidadController,
                            decoration: InputDecoration(
                              labelText: 'Cantidad',
                              labelStyle: GoogleFonts.poppins(),
                              hintText: 'Ej: 5',
                              prefixIcon: Icon(
                                Icons.numbers,
                                color: Colors.amber,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.amber),
                              ),
                              errorStyle: GoogleFonts.poppins(
                                color: Colors.red,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa cantidad';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Número válido';
                              }
                              if (int.parse(value) < 0) {
                                return 'Mayor a 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: unidadSeleccionada,
                            decoration: InputDecoration(
                              labelText: 'Unidad',
                              labelStyle: GoogleFonts.poppins(),
                              prefixIcon: Icon(
                                Icons.straighten,
                                color: Colors.amber,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.amber),
                              ),
                            ),
                            items: unidades.map((String unidad) {
                              return DropdownMenuItem<String>(
                                value: unidad,
                                child: Text(
                                  unidad,
                                  style: GoogleFonts.poppins(),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                unidadSeleccionada = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _limpiarFormulario();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _guardarInsumo,
                  child: Text(
                    isEditing ? 'Actualizar' : 'Agregar',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Método para filtrar insumos
  List<InventoryItem> get filteredInsumos {
    if (searchController.text.isEmpty) {
      return _inventoryItems;
    }
    return _inventoryItems
        .where(
          (insumo) => insumo.itemName.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: LoadingWidget(message: 'Cargando inventario...'));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: ErrorDisplayWidget(
          message: _errorMessage!,
          onRetry: _loadInventoryItems,
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

  // Layout para móviles (diseño actual)
  Widget _buildMobileLayout() {
    return Container(
      color: Color(0xFFFFF8E1),
      child: Column(
        children: [
          _buildHeader(ScreenType.mobile),
          _buildSearchAndAddSection(ScreenType.mobile),
          Expanded(child: _buildListaInsumos(ScreenType.mobile)),
        ],
      ),
    );
  }

  // Layout para tablets
  Widget _buildTabletLayout() {
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
                  // Panel lateral con información
                  Container(width: 280, child: _buildSidePanel()),
                  SizedBox(width: 16),
                  // Contenido principal
                  Expanded(
                    child: Column(
                      children: [
                        _buildSearchAndAddSection(ScreenType.tablet),
                        SizedBox(height: 16),
                        Expanded(child: _buildListaInsumos(ScreenType.tablet)),
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
                  // Panel lateral expandido
                  Container(width: 350, child: _buildSidePanel()),
                  SizedBox(width: 24),
                  // Contenido principal
                  Expanded(
                    child: Column(
                      children: [
                        _buildSearchAndAddSection(ScreenType.desktop),
                        SizedBox(height: 24),
                        Expanded(child: _buildListaInsumos(ScreenType.desktop)),
                      ],
                    ),
                  ),
                  SizedBox(width: 24),
                  // Panel de estadísticas (solo desktop)
                  Container(width: 300, child: _buildStatsPanel()),
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
                    'Gestión de Inventario',
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
                    'Administra tus insumos de apiario',
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
                    Icons.inventory_2,
                    color: Colors.amber[700],
                    size: isDesktop ? 20 : 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${_inventoryItems.length}',
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

  // Sección de búsqueda y agregar
  Widget _buildSearchAndAddSection(ScreenType screenType) {
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;
    final padding = (isDesktop || isTablet) ? 0.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
      child: Column(
        children: [
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
                hintText: 'Buscar insumo...',
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.add, size: isDesktop ? 24 : 20),
              label: Text(
                'Agregar Nuevo Insumo',
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isDesktop ? 20 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () {
                _limpiarFormulario();
                _mostrarDialogoAgregar();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Panel lateral para tablet y desktop
  Widget _buildSidePanel() {
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
              'Resumen de Inventario',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            _buildSummaryCard(
              'Total de Insumos',
              '${_inventoryItems.length}',
              Icons.inventory_2,
              Colors.blue,
            ),
            SizedBox(height: 12),
            _buildSummaryCard(
              'Stock Bajo',
              '${_getStockBajo()}',
              Icons.warning,
              Colors.orange,
            ),
            SizedBox(height: 12),
            _buildSummaryCard(
              'Sin Stock',
              '${_getSinStock()}',
              Icons.error,
              Colors.red,
            ),
            SizedBox(height: 12),
            _buildSummaryCard(
              'Stock Total',
              '${_getStockTotal()}',
              Icons.assessment,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  // Panel de estadísticas para desktop
  Widget _buildStatsPanel() {
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
              'Análisis de Inventario',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            _buildStatItem('Insumo con mayor stock', _getInsumoMayorStock()),
            SizedBox(height: 16),
            _buildStatItem('Insumo con menor stock', _getInsumoMenorStock()),
            SizedBox(height: 16),
            _buildStatItem(
              'Promedio de stock',
              '${_getPromedioStock().toStringAsFixed(1)} unidades',
            ),
            SizedBox(height: 24),
            Text(
              'Alertas',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            ..._buildAlertas(),
          ],
        ),
      ),
    );
  }

  // Lista de insumos responsiva
  Widget _buildListaInsumos(ScreenType screenType) {
    final insumosFiltrados = filteredInsumos;
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;

    if (insumosFiltrados.isEmpty) {
      return _buildEmptyState();
    }

    // Para desktop, usar grid de 2 columnas
    if (isDesktop) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.0,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: insumosFiltrados.length,
        itemBuilder: (context, index) {
          return _buildInsumoCard(insumosFiltrados[index], index, screenType);
        },
      );
    }

    // Para tablet y móvil, usar lista
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: (isDesktop || isTablet) ? 0 : 16,
      ),
      itemCount: insumosFiltrados.length,
      itemBuilder: (context, index) {
        return _buildInsumoCard(insumosFiltrados[index], index, screenType);
      },
    );
  }

  // Card de insumo responsivo
  Widget _buildInsumoCard(
    InventoryItem insumo,
    int index,
    ScreenType screenType,
  ) {
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;
    final isMobile = screenType == ScreenType.mobile;

    final cantidad = insumo.quantity;
    final unidad = insumo.unit;
    final nombre = insumo.itemName;
    final id = insumo.id;

    final bool cantidadBaja = cantidad <= 1;

    // Ajustes específicos para cada tamaño de pantalla
    final cardMargin = isMobile
        ? EdgeInsets.only(bottom: 12)
        : isTablet
        ? EdgeInsets.only(bottom: 10)
        : EdgeInsets.zero;

    final cardPadding = isDesktop
        ? EdgeInsets.all(24)
        : isTablet
        ? EdgeInsets.all(12)
        : EdgeInsets.all(16);

    final iconSize = isDesktop
        ? 26
        : isTablet
        ? 18
        : 20;
    final titleFontSize = isDesktop
        ? 18
        : isTablet
        ? 14
        : 16;
    final subtitleFontSize = isDesktop
        ? 14
        : isTablet
        ? 11
        : 12;

    return Card(
          margin: cardMargin,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: cantidadBaja
                  ? Colors.red[100] ?? Colors.red.shade100
                  : Colors.amber[100] ?? Colors.amber.shade100,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: cantidadBaja
                    ? [
                        Colors.red[50] ?? Colors.red.shade50,
                        Colors.red[25] ?? Colors.red.shade100,
                      ]
                    : [Colors.amber[50] ?? Colors.amber.shade50, Colors.white],
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
                        padding: EdgeInsets.all(
                          isDesktop
                              ? 12
                              : isTablet
                              ? 6
                              : 8,
                        ),
                        decoration: BoxDecoration(
                          color: cantidadBaja
                              ? Colors.red[100] ?? Colors.red.shade100
                              : Colors.amber[100] ?? Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: cantidadBaja
                              ? Colors.red[700] ?? Colors.red
                              : Colors.amber[700] ?? Colors.amber,
                          size: iconSize.toDouble(),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: titleFontSize.toDouble(),
                                color: cantidadBaja
                                    ? Colors.red[800] ?? Colors.red
                                    : Colors.grey[800] ?? Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Stock: ',
                                  style: GoogleFonts.poppins(
                                    fontSize: subtitleFontSize.toDouble(),
                                    color: Colors.grey[600] ?? Colors.grey,
                                  ),
                                ),
                                Text(
                                  '$cantidad $unidad',
                                  style: GoogleFonts.poppins(
                                    fontSize: subtitleFontSize.toDouble(),
                                    fontWeight: FontWeight.w600,
                                    color: cantidadBaja
                                        ? Colors.red[700] ?? Colors.red
                                        : Colors.amber[700] ?? Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (cantidadBaja)
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
                            'STOCK BAJO',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: isDesktop
                        ? 16
                        : isTablet
                        ? 10
                        : 12,
                  ),
                  // Botones responsivos
                  isDesktop
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: Icon(Icons.edit, size: 16),
                              label: Text(
                                'Editar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Colors.amber[700] ?? Colors.amber,
                                side: BorderSide(
                                  color: Colors.amber[300] ?? Colors.amber,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => _editarInsumo(insumo),
                            ),
                            SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: Icon(Icons.delete, size: 16),
                              label: Text(
                                'Eliminar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[700] ?? Colors.red,
                                side: BorderSide(
                                  color: Colors.red[300] ?? Colors.red,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => _eliminarInsumo(id),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.edit,
                                  size: isTablet ? 14 : 16,
                                ),
                                label: Text(
                                  'Editar',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: isTablet ? 12 : 14,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Colors.amber[700] ?? Colors.amber,
                                  side: BorderSide(
                                    color: Colors.amber[300] ?? Colors.amber,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _editarInsumo(insumo),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.delete,
                                  size: isTablet ? 14 : 16,
                                ),
                                label: Text(
                                  'Eliminar',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: isTablet ? 12 : 14,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Colors.red[700] ?? Colors.red,
                                  side: BorderSide(
                                    color: Colors.red[300] ?? Colors.red,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _eliminarInsumo(id),
                              ),
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

  Widget _buildStatItem(String label, String value) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchController.text.isNotEmpty
                ? Icons.search_off
                : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.amber[300] ?? Colors.amber,
          ),
          SizedBox(height: 16),
          Text(
            searchController.text.isNotEmpty
                ? 'No se encontraron insumos'
                : 'No hay insumos registrados',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600] ?? Colors.grey,
            ),
          ),
          Text(
            searchController.text.isNotEmpty
                ? 'Intenta con otro término de búsqueda'
                : 'Agrega tu primer insumo al inventario',
            style: GoogleFonts.poppins(color: Colors.grey[500] ?? Colors.grey),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: searchController.text.isNotEmpty
                ? _loadInventoryItems
                : () {
                    _limpiarFormulario();
                    _mostrarDialogoAgregar();
                  },
            icon: Icon(
              searchController.text.isNotEmpty ? Icons.refresh : Icons.add,
            ),
            label: Text(
              searchController.text.isNotEmpty ? 'Recargar' : 'Agregar Insumo',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  List<Widget> _buildAlertas() {
    List<Widget> alertas = [];

    if (_getSinStock() > 0) {
      alertas.add(_buildAlerta('Productos sin stock', Icons.error, Colors.red));
    }

    if (_getStockBajo() > 0) {
      alertas.add(
        _buildAlerta('Stock bajo detectado', Icons.warning, Colors.orange),
      );
    }

    if (alertas.isEmpty) {
      alertas.add(
        _buildAlerta(
          'Inventario en buen estado',
          Icons.check_circle,
          Colors.green,
        ),
      );
    }

    return alertas;
  }

  Widget _buildAlerta(String mensaje, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares para estadísticas
  int _getStockBajo() {
    return _inventoryItems.where((insumo) {
      final cantidad = insumo.quantity;
      return cantidad > 0 && cantidad <= 1;
    }).length;
  }

  int _getSinStock() {
    return _inventoryItems.where((insumo) {
      final cantidad = insumo.quantity;
      return cantidad <= 0;
    }).length;
  }

  int _getStockTotal() {
    return _inventoryItems.fold(0, (total, insumo) {
      return total + insumo.quantity;
    });
  }

  String _getInsumoMayorStock() {
    if (_inventoryItems.isEmpty) return 'Sin datos';

    var insumoMayor = _inventoryItems.reduce((a, b) {
      return a.quantity > b.quantity ? a : b;
    });

    return insumoMayor.itemName;
  }

  String _getInsumoMenorStock() {
    if (_inventoryItems.isEmpty) return 'Sin datos';

    var insumoMenor = _inventoryItems.reduce((a, b) {
      return a.quantity < b.quantity ? a : b;
    });

    return insumoMenor.itemName;
  }

  double _getPromedioStock() {
    if (_inventoryItems.isEmpty) return 0.0;

    final total = _getStockTotal();
    return total / _inventoryItems.length;
  }
}
