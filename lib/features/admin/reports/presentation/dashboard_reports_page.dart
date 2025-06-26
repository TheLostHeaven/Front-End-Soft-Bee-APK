import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart'; // Importación relativa corregida
import '../model/api_models.dart';
import '../widgets/responsive_widgets.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  List<Apiario> _apiarios = [];
  List<Monitoreo> _monitoreos = [];
  SystemStats? _stats;
  int _currentUserId = 1;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getUserApiarios(_currentUserId),
        ApiService.getAllMonitoreos(),
        ApiService.getSystemStats(),
      ]);

      setState(() {
        _apiarios = results[0] as List<Apiario>;
        _monitoreos = results[1] as List<Monitoreo>;
        _stats = results[2] as SystemStats;
        _isLoading = false;
      });

      await _loadMonitoreosPorApiario();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMonitoreosPorApiario() async {
    for (int i = 0; i < _apiarios.length; i++) {
      try {
        final monitoreos = await ApiService.getMonitoreosByApiario(
          _apiarios[i].id,
        );
        setState(() {
          _apiarios[i].monitoreos = monitoreos;
        });
      } catch (e) {
        print('Error cargando monitoreos para apiario ${_apiarios[i].id}: $e');
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ApiarioTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
      drawer: ResponsiveBreakpoints.isMobile(context)
          ? _buildDrawer(context)
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 4,
      title:
          Text(
                ResponsiveBreakpoints.isMobile(context)
                    ? 'Dashboard Apiario'
                    : 'Dashboard de Monitoreo de Apiarios',
                style: ApiarioTheme.titleStyle.copyWith(
                  color: Colors.white,
                  fontSize: ApiarioTheme.getTitleFontSize(context),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideX(begin: -0.2, end: 0, curve: Curves.easeOutQuad),
      backgroundColor: ApiarioTheme.primaryColor,
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'Actualizar datos',
        ),
        if (!ResponsiveBreakpoints.isMobile(context)) ...[
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => _showNotifications(context),
            tooltip: 'Notificaciones',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettings(context),
            tooltip: 'Configuración',
          ),
        ],
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ApiarioTheme.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando datos del apiario...',
              style: ApiarioTheme.bodyStyle.copyWith(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Error al cargar los datos',
              style: ApiarioTheme.titleStyle.copyWith(
                fontSize: 20,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: ApiarioTheme.bodyStyle.copyWith(color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ApiarioTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: ApiarioTheme.primaryColor,
      child: _buildResponsiveLayout(context),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context) {
    if (ResponsiveBreakpoints.isMobile(context)) {
      return _buildMobileLayout(context);
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      return _buildTabletLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ApiarioTheme.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_stats != null)
            DashboardSummaryCard(stats: _stats!, isMobile: true),
          SizedBox(height: 20),
          AlertsWidget(monitoreos: _monitoreos),
          SizedBox(height: 20),
          ApiariosSectionWidget(apiarios: _apiarios, crossAxisCount: 1),
          SizedBox(height: 20),
          RecentMonitoreosWidget(
            monitoreos: _monitoreos.take(5).toList(),
            isCompact: true,
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ApiarioTheme.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_stats != null) DashboardSummaryCard(stats: _stats!),
          SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    ApiariosSectionWidget(
                      apiarios: _apiarios,
                      crossAxisCount: 1,
                    ),
                    SizedBox(height: 20),
                    AlertsWidget(monitoreos: _monitoreos),
                  ],
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    RecentMonitoreosWidget(monitoreos: _monitoreos),
                    SizedBox(height: 20),
                    WeatherWidget(),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ApiarioTheme.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_stats != null) DashboardSummaryCard(stats: _stats!),
          SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    RecentMonitoreosWidget(monitoreos: _monitoreos),
                    SizedBox(height: 24),
                    WeatherWidget(),
                  ],
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: ApiariosSectionWidget(
                  apiarios: _apiarios,
                  crossAxisCount: ResponsiveBreakpoints.isLargeDesktop(context)
                      ? 2
                      : 1,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    AlertsWidget(monitoreos: _monitoreos),
                    SizedBox(height: 24),
                    ProductionChart(monitoreos: _monitoreos),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: ApiarioTheme.primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hive, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  'Apiario Manager',
                  style: ApiarioTheme.titleStyle.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Gestión Integral',
                  style: ApiarioTheme.bodyStyle.copyWith(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.home_work),
            title: Text('Apiarios'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.monitor_heart),
            title: Text('Monitoreos'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.analytics),
            title: Text('Reportes'),
            onTap: () => Navigator.pop(context),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Configuración'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    if (ResponsiveBreakpoints.isMobile(context)) {
      return FloatingActionButton(
        onPressed: () => _showNewMonitoreoDialog(context),
        backgroundColor: ApiarioTheme.secondaryColor,
        child: Icon(Icons.add),
        tooltip: 'Nuevo Monitoreo',
      );
    } else {
      return FloatingActionButton.extended(
        onPressed: () => _showNewMonitoreoDialog(context),
        backgroundColor: ApiarioTheme.secondaryColor,
        icon: Icon(Icons.add),
        label: Text('Nuevo Monitoreo'),
      );
    }
  }

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Funcionalidad de notificaciones próximamente')),
    );
  }

  void _showSettings(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Configuración próximamente')));
  }

  void _showNewMonitoreoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nuevo Monitoreo'),
        content: Text('Funcionalidad de nuevo monitoreo próximamente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
