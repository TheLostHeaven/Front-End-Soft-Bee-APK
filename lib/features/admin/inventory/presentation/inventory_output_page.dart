import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/inventory/models/inventory_item.dart';
import 'package:sotfbee/features/admin/inventory/presentation/inventory_history_page.dart';
import 'package:sotfbee/features/admin/inventory/presentation/inventory_management_page.dart';
import 'package:sotfbee/features/admin/inventory/service/inventory_service.dart';
import 'package:sotfbee/features/admin/inventory/widgets/error_widget.dart';
import 'package:sotfbee/features/admin/inventory/widgets/loading_widget.dart';


// Enum para definir los tipos de pantalla
enum ScreenType { mobile, tablet, desktop }

// Clase para manejar breakpoints responsivos
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1250;
  static const double desktop = 1420;

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

class SalidaProductosUpdated extends StatefulWidget {
  @override
  _SalidaProductosUpdatedState createState() => _SalidaProductosUpdatedState();
}

class _SalidaProductosUpdatedState extends State<SalidaProductosUpdated>
    with SingleTickerProviderStateMixin {
  // Servicios
  final InventoryService _inventoryService = InventoryService();

  // Lista de insumos desde el backend
  List<InventoryItem> _inventoryItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Controladores
  TextEditingController searchController = TextEditingController();
  TextEditingController personaController = TextEditingController();
  TextEditingController cantidadController = TextEditingController();

  // Clave para validación del formulario
  final _formKeySalida = GlobalKey<FormState>();

  // Variables para el diálogo de salida
  InventoryItem? insumoSeleccionado;

  // Controlador para animaciones
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
    searchController.dispose();
    personaController.dispose();
    cantidadController.dispose();
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

  // Método para registrar salida de insumo con validación
  void _registrarSalida(InventoryItem insumo) {
    personaController.clear();
    cantidadController.clear();
    insumoSeleccionado = insumo;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Registrar Salida',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKeySalida,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.amber[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insumo.itemName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[800],
                              ),
                            ),
                            Text(
                              'Disponible: ${insumo.quantity} ${insumo.unit}',
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
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: personaController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la persona',
                    labelStyle: GoogleFonts.poppins(),
                    hintText: 'Ej: Juan Pérez',
                    prefixIcon: Icon(Icons.person, color: Colors.amber),
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
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el nombre de la persona';
                    }
                    if (value.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: cantidadController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad a retirar',
                    labelStyle: GoogleFonts.poppins(),
                    hintText: 'Ej: 1',
                    prefixIcon: Icon(
                      Icons.remove_circle_outline,
                      color: Colors.amber,
                    ),
                    suffixText: insumo.unit,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                    errorStyle: GoogleFonts.poppins(color: Colors.red),
                    helperText:
                        'Máximo disponible: ${insumo.quantity} ${insumo.unit}',
                    helperStyle: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una cantidad';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Ingresa un número válido';
                    }
                    if (int.parse(value) <= 0) {
                      return 'La cantidad debe ser mayor a 0';
                    }
                    if (int.parse(value) > insumo.quantity) {
                      return 'No hay suficiente inventario disponible';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
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
              onPressed: () => _procesarSalida(),
              child: Text('Procesar salida'),
            ),
          ],
        );
      },
    );
  }

  // Procesar la salida del inventario
  Future<void> _procesarSalida() async {
    if (!_formKeySalida.currentState!.validate()) {
      return;
    }

    try {
      final cantidadSalida = int.parse(cantidadController.text);

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => LoadingWidget (message: 'Registrando salida...'),
      );

      // Registrar la salida en el backend
      await _inventoryService.recordInventoryExit(
        itemId: insumoSeleccionado!.id,
        quantity: cantidadSalida,
        person: personaController.text.trim(),
      );

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Cerrar diálogo de salida
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
                'Salida registrada correctamente',
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
                  'Error al registrar salida: ${e.toString()}',
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

  // Método para navegar al historial de salidas
  void _navegarAHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistorialSalidasUpdated()),
    );
  }

  // Método para navegar a gestión de inventario
  void _navegarAGestion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GestionInventarioUpdated()),
    ).then((_) {
      // Refrescar la vista cuando regrese de gestión
      _loadInventoryItems();
    });
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

  // Layout para móviles (tu diseño actual)
  Widget _buildMobileLayout() {
    return Container(
      color: Color(0xFFFFF8E1),
      child: Column(
        children: [
          _buildHeader(ScreenType.mobile),
          _buildSearchBar(ScreenType.mobile),
          Expanded(child: _buildInsumosList(ScreenType.mobile)),
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
                        _buildSearchBar(ScreenType.tablet),
                        SizedBox(height: 16),
                        Expanded(child: _buildInsumosList(ScreenType.tablet)),
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
                        _buildSearchBar(ScreenType.desktop),
                        SizedBox(height: 24),
                        Expanded(child: _buildInsumosList(ScreenType.desktop)),
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salida de Productos',
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop
                              ? 32
                              : isTablet
                              ? 28
                              : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Registra las salidas de tu inventario',
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 16 : 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDesktop || isTablet) ...[
                  _buildHeaderActions(screenType),
                ] else ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_inventoryItems.length} insumos',
                      style: GoogleFonts.poppins(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!isDesktop && !isTablet) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.history, size: 18),
                      label: Text(
                        'Historial',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.amber[700],
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _navegarAHistorial,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.settings, size: 18),
                      label: Text(
                        'Gestión',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.amber[700],
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _navegarAGestion,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Acciones del header para tablet y desktop
  Widget _buildHeaderActions(ScreenType screenType) {
    final isDesktop = screenType == ScreenType.desktop;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.amber[700], size: 20),
              SizedBox(width: 8),
              Text(
                '${_inventoryItems.length} insumos',
                style: GoogleFonts.poppins(
                  color: Colors.amber[700],
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 14 : 12,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.history, size: isDesktop ? 20 : 18),
          label: Text(
            'Historial',
            style: GoogleFonts.poppins(fontSize: isDesktop ? 16 : 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.amber[700],
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 16,
              vertical: isDesktop ? 12 : 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _navegarAHistorial,
        ),
        SizedBox(width: 12),
        ElevatedButton.icon(
          icon: Icon(Icons.settings, size: isDesktop ? 20 : 18),
          label: Text(
            'Gestión',
            style: GoogleFonts.poppins(fontSize: isDesktop ? 16 : 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.amber[700],
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 16,
              vertical: isDesktop ? 12 : 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _navegarAGestion,
        ),
      ],
    );
  }

  // Barra de búsqueda responsiva
  Widget _buildSearchBar(ScreenType screenType) {
    final isDesktop = screenType == ScreenType.desktop;
    final isTablet = screenType == ScreenType.tablet;
    final padding = (isDesktop || isTablet) ? 0.0 : 16.0;

    return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: padding / 2,
          ),
          child: Container(
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
                hintText: 'Buscar insumo para registrar salida...',
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
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(
          begin: -0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuad,
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
              'Estadísticas',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            _buildStatItem(
              'Items disponibles',
              '${_inventoryItems.where((item) => item.quantity > 0).length}',
            ),
            SizedBox(height: 16),
            _buildStatItem(
              'Promedio de stock',
              '${_getPromedioStock().toStringAsFixed(1)} unidades',
            ),
            SizedBox(height: 16),
            _buildStatItem('Última actualización', 'Hace unos momentos'),
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
  Widget _buildInsumosList(ScreenType screenType) {
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
          childAspectRatio: 2.2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: insumosFiltrados.length,
        itemBuilder: (context, index) {
          return _buildInsumoCard(insumosFiltrados[index], index, screenType);
        },
      );
    }

    // Para tablet, usar lista con cards más pequeñas
    if (isTablet) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: insumosFiltrados.length,
        itemBuilder: (context, index) {
          return _buildInsumoCard(insumosFiltrados[index], index, screenType);
        },
      );
    }

    // Para móvil, usar lista
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
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

    final bool cantidadBaja = cantidad <= 1;
    final bool sinStock = cantidad <= 0;

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

    final buttonPadding = isDesktop
        ? EdgeInsets.symmetric(vertical: 10, horizontal: 16)
        : isTablet
        ? EdgeInsets.symmetric(vertical: 8)
        : EdgeInsets.symmetric(vertical: 12);

    return Card(
          margin: cardMargin,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: sinStock
                  ? Colors.red[300] ?? Colors.red
                  : cantidadBaja
                  ? Colors.orange[200] ?? Colors.orange
                  : Colors.amber[100] ?? Colors.amber,
              width: sinStock ? 2 : 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: sinStock
                    ? [
                        Colors.red[50] ?? Colors.red.shade50,
                        Colors.red[25] ?? Colors.red.shade100,
                      ]
                    : cantidadBaja
                    ? [
                        Colors.orange[50] ?? Colors.orange.shade50,
                        Colors.orange[25] ?? Colors.orange.shade100,
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
                          color: sinStock
                              ? Colors.red[100] ?? Colors.red.shade100
                              : cantidadBaja
                              ? Colors.orange[100] ?? Colors.orange.shade100
                              : Colors.amber[100] ?? Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: sinStock
                              ? Colors.red[700] ?? Colors.red
                              : cantidadBaja
                              ? Colors.orange[700] ?? Colors.orange
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
                                color: sinStock
                                    ? Colors.red[800] ?? Colors.red
                                    : cantidadBaja
                                    ? Colors.orange[800] ?? Colors.orange
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
                                    color: sinStock
                                        ? Colors.red[700] ?? Colors.red
                                        : cantidadBaja
                                        ? Colors.orange[700] ?? Colors.orange
                                        : Colors.amber[700] ?? Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (sinStock)
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
                            'SIN STOCK',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (cantidadBaja)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
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
                  // Botón más pequeño para desktop
                  isDesktop
                      ? Row(
                          children: [
                            Expanded(
                              child: SizedBox(), // Espacio flexible
                            ),
                            ElevatedButton.icon(
                              icon: Icon(
                                sinStock ? Icons.block : Icons.exit_to_app,
                                size: 18,
                              ),
                              label: Text(
                                sinStock ? 'Sin Stock' : 'Registrar Salida',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: sinStock
                                    ? Colors.grey[400] ?? Colors.grey
                                    : Colors.amber,
                                foregroundColor: sinStock
                                    ? Colors.grey[600] ?? Colors.grey
                                    : Colors.white,
                                padding: buttonPadding,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: sinStock
                                  ? null
                                  : () => _registrarSalida(insumo),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              sinStock ? Icons.block : Icons.exit_to_app,
                              size: isTablet ? 16 : 18,
                            ),
                            label: Text(
                              sinStock
                                  ? 'Sin Stock Disponible'
                                  : 'Registrar Salida',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 13 : 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sinStock
                                  ? Colors.grey[400] ?? Colors.grey
                                  : Colors.amber,
                              foregroundColor: sinStock
                                  ? Colors.grey[600] ?? Colors.grey
                                  : Colors.white,
                              padding: buttonPadding,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: sinStock
                                ? null
                                : () => _registrarSalida(insumo),
                          ),
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
            Icons.search_off,
            size: 64,
            color: Colors.amber[300] ?? Colors.amber,
          ),
          SizedBox(height: 16),
          Text(
            'No se encontraron insumos',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600] ?? Colors.grey,
            ),
          ),
          Text(
            searchController.text.isNotEmpty
                ? 'Intenta con otro término de búsqueda'
                : 'No hay insumos disponibles',
            style: GoogleFonts.poppins(color: Colors.grey[500] ?? Colors.grey),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInventoryItems,
            icon: Icon(Icons.refresh),
            label: Text('Recargar'),
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
        _buildAlerta('Todo en orden', Icons.check_circle, Colors.green),
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

  double _getPromedioStock() {
    if (_inventoryItems.isEmpty) return 0.0;
    final total = _getStockTotal();
    return total / _inventoryItems.length;
  }
}
