import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/reports/model/api_models.dart';
import 'package:sotfbee/features/admin/reports/widgets/responsive_widgets.dart';

class DashboardSummaryCard extends StatelessWidget {
  final SystemStats stats;
  final bool isMobile;

  const DashboardSummaryCard({required this.stats, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(ApiarioTheme.getPadding(context)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dashboard,
                  color: ApiarioTheme.secondaryColor,
                  size: isMobile ? 24 : 32,
                ),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Resumen del Sistema',
                    style: ApiarioTheme.titleStyle.copyWith(
                      fontSize: ApiarioTheme.getSubtitleFontSize(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildSummaryLayout(context),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildSummaryLayout(BuildContext context) {
    final items = _buildSummaryItems(context);

    if (ResponsiveBreakpoints.isMobile(context)) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: items,
      );
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) => Expanded(child: item)).toList(),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items,
      );
    }
  }

  List<Widget> _buildSummaryItems(BuildContext context) {
    return [
      _SummaryItem(
        title: 'Total Apiarios',
        value: '${stats.totalApiarios}',
        icon: Icons.home_work,
        color: ApiarioTheme.primaryColor,
      ),
      _SummaryItem(
        title: 'Total Colmenas',
        value: '${stats.totalColmenas}',
        icon: Icons.home,
        color: ApiarioTheme.successColor,
      ),
      _SummaryItem(
        title: 'Monitoreos',
        value: '${stats.totalMonitoreos}',
        icon: Icons.monitor_heart,
        color: ApiarioTheme.secondaryColor,
      ),
      _SummaryItem(
        title: 'Este Mes',
        value: '${stats.monitoreosUltimoMes}',
        icon: Icons.calendar_month,
        color: ApiarioTheme.warningColor,
      ),
    ];
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 28),
          SizedBox(height: 8),
          Text(
            value,
            style: ApiarioTheme.bodyStyle.copyWith(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: ApiarioTheme.bodyStyle.copyWith(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ApiariosSectionWidget extends StatelessWidget {
  final List<Apiario> apiarios;
  final int crossAxisCount;

  const ApiariosSectionWidget({
    required this.apiarios,
    this.crossAxisCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Apiarios y Monitoreos', icon: Icons.home_work),
        SizedBox(height: 16),

        if (apiarios.isEmpty)
          _buildEmptyState(context)
        else
          GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getEffectiveCrossAxisCount(context),
              childAspectRatio: _getChildAspectRatio(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: apiarios.length,
            itemBuilder: (context, index) {
              final apiario = apiarios[index];
              return _ApiarioCard(apiario: apiario);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.home_work_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No hay apiarios registrados',
              style: ApiarioTheme.titleStyle.copyWith(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega tu primer apiario para comenzar',
              style: ApiarioTheme.bodyStyle.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  int _getEffectiveCrossAxisCount(BuildContext context) {
    if (ResponsiveBreakpoints.isMobile(context)) return 1;
    return crossAxisCount;
  }

  double _getChildAspectRatio(BuildContext context) {
    if (ResponsiveBreakpoints.isMobile(context)) return 1.8;
    if (ResponsiveBreakpoints.isTablet(context)) return 1.6;
    return 1.4;
  }
}

class _ApiarioCard extends StatelessWidget {
  final Apiario apiario;

  const _ApiarioCard({required this.apiario});

  @override
  Widget build(BuildContext context) {
    final monitoreos = apiario.monitoreos ?? [];
    final ultimoMonitoreo = monitoreos.isNotEmpty ? monitoreos.first : null;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showApiarioDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    decoration: BoxDecoration(
                      color: ApiarioTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.home_work,
                      color: ApiarioTheme.primaryColor,
                      size: isMobile ? 20 : 28,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apiario.name,
                          style: ApiarioTheme.bodyStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: ApiarioTheme.getBodyFontSize(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (apiario.location != null)
                          Text(
                            apiario.location!,
                            style: ApiarioTheme.bodyStyle.copyWith(
                              fontSize:
                                  ApiarioTheme.getBodyFontSize(context) - 2,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    context,
                    'Monitoreos',
                    '${monitoreos.length}',
                    Icons.monitor_heart,
                    ApiarioTheme.secondaryColor,
                  ),
                  _buildStatItem(
                    context,
                    'Último',
                    ultimoMonitoreo != null
                        ? _formatDaysAgo(ultimoMonitoreo.fecha)
                        : 'N/A',
                    Icons.schedule,
                    Colors.grey[600]!,
                  ),
                ],
              ),

              if (ultimoMonitoreo != null) ...[
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ultimoMonitoreo).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Último monitoreo: ${_formatDate(ultimoMonitoreo.fecha)}',
                    style: ApiarioTheme.bodyStyle.copyWith(
                      fontSize: ApiarioTheme.getBodyFontSize(context) - 4,
                      color: _getStatusColor(ultimoMonitoreo),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(height: 4),
        Text(
          value,
          style: ApiarioTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(
          label,
          style: ApiarioTheme.bodyStyle.copyWith(
            fontSize: ApiarioTheme.getBodyFontSize(context) - 4,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(Monitoreo monitoreo) {
    final daysSince = DateTime.now().difference(monitoreo.fecha).inDays;
    if (daysSince <= 7) return ApiarioTheme.successColor;
    if (daysSince <= 30) return ApiarioTheme.warningColor;
    return ApiarioTheme.dangerColor;
  }

  String _formatDaysAgo(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Hoy';
    if (days == 1) return 'Ayer';
    return '${days}d';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showApiarioDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(apiario.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (apiario.location != null) ...[
                Text('Ubicación: ${apiario.location}'),
                SizedBox(height: 8),
              ],
              Text(
                'Monitoreos registrados: ${apiario.monitoreos?.length ?? 0}',
              ),
              SizedBox(height: 8),
              Text('Creado: ${_formatDate(apiario.createdAt)}'),
              if (apiario.monitoreos?.isNotEmpty == true) ...[
                SizedBox(height: 12),
                Text(
                  'Monitoreos recientes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...apiario.monitoreos!
                    .take(3)
                    .map(
                      (m) => Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('• ${_formatDate(m.fecha)}'),
                      ),
                    ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Ver Detalles'),
          ),
        ],
      ),
    );
  }
}

class RecentMonitoreosWidget extends StatelessWidget {
  final List<Monitoreo> monitoreos;
  final bool isCompact;

  const RecentMonitoreosWidget({
    required this.monitoreos,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxItems = isCompact ? 3 : 5;
    final recentMonitoreos = monitoreos.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Monitoreos Recientes', icon: Icons.monitor_heart),
        SizedBox(height: 16),

        if (recentMonitoreos.isEmpty)
          _buildEmptyState(context)
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: recentMonitoreos
                  .map((monitoreo) => _MonitoreoItem(monitoreo: monitoreo))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 12),
            Text(
              'No hay monitoreos registrados',
              style: ApiarioTheme.bodyStyle.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitoreoItem extends StatelessWidget {
  final Monitoreo monitoreo;

  const _MonitoreoItem({required this.monitoreo});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final statusColor = _getStatusColor();

    return InkWell(
      onTap: () => _showMonitoreoDetails(context),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${monitoreo.apiarioNombre ?? 'Apiario'} - Colmena ${monitoreo.numeroColmena ?? monitoreo.idColmena}',
                    style: ApiarioTheme.bodyStyle.copyWith(
                      fontSize: ApiarioTheme.getBodyFontSize(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Fecha: ${_formatDate(monitoreo.fecha)}',
                    style: ApiarioTheme.bodyStyle.copyWith(
                      fontSize: ApiarioTheme.getBodyFontSize(context) - 2,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (monitoreo.respuestas.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      '${monitoreo.respuestas.length} respuestas registradas',
                      style: ApiarioTheme.bodyStyle.copyWith(
                        fontSize: ApiarioTheme.getBodyFontSize(context) - 2,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isMobile)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    final daysSince = DateTime.now().difference(monitoreo.fecha).inDays;
    if (daysSince <= 1) return ApiarioTheme.successColor;
    if (daysSince <= 7) return ApiarioTheme.warningColor;
    return ApiarioTheme.dangerColor;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showMonitoreoDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Monitoreo del ${_formatDate(monitoreo.fecha)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apiario: ${monitoreo.apiarioNombre ?? 'N/A'}'),
              SizedBox(height: 8),
              Text(
                'Colmena: ${monitoreo.numeroColmena ?? monitoreo.idColmena}',
              ),
              SizedBox(height: 8),
              Text('Sincronizado: ${monitoreo.sincronizado ? 'Sí' : 'No'}'),
              if (monitoreo.respuestas.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  'Respuestas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...monitoreo.respuestas
                    .take(3)
                    .map(
                      (r) => Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${r.preguntaTexto}: ${r.respuesta ?? 'N/A'}',
                        ),
                      ),
                    ),
              ],
            ],
          ),
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
}

class AlertsWidget extends StatelessWidget {
  final List<Monitoreo> monitoreos;

  const AlertsWidget({required this.monitoreos});

  @override
  Widget build(BuildContext context) {
    final alertas = _generateAlertas();

    return Card(
      elevation: 3,
      color: ApiarioTheme.dangerColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(ApiarioTheme.getPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notification_important,
                  color: ApiarioTheme.dangerColor,
                  size: 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alertas del Sistema',
                    style: ApiarioTheme.titleStyle.copyWith(
                      fontSize: ApiarioTheme.getSubtitleFontSize(context) - 4,
                      color: ApiarioTheme.dangerColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            if (alertas.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ApiarioTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: ApiarioTheme.successColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'No hay alertas activas',
                      style: ApiarioTheme.bodyStyle.copyWith(
                        color: ApiarioTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: alertas
                    .take(ResponsiveBreakpoints.isMobile(context) ? 3 : 5)
                    .map((alerta) => _buildAlertItem(context, alerta))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _generateAlertas() {
    List<String> alertas = [];

    final now = DateTime.now();
    final monitoreosAntiguos = monitoreos
        .where((m) => now.difference(m.fecha).inDays > 30)
        .length;

    if (monitoreosAntiguos > 0) {
      alertas.add('$monitoreosAntiguos monitoreos tienen más de 30 días');
    }

    final noSincronizados = monitoreos.where((m) => !m.sincronizado).length;
    if (noSincronizados > 0) {
      alertas.add('$noSincronizados monitoreos pendientes de sincronización');
    }

    final monitoreosRecientes = monitoreos
        .where((m) => now.difference(m.fecha).inDays <= 7)
        .length;

    if (monitoreosRecientes == 0 && monitoreos.isNotEmpty) {
      alertas.add('No hay monitoreos en los últimos 7 días');
    }

    return alertas;
  }

  Widget _buildAlertItem(BuildContext context, String alerta) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: ApiarioTheme.dangerColor, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                alerta,
                style: ApiarioTheme.bodyStyle.copyWith(
                  fontSize: ApiarioTheme.getBodyFontSize(context) - 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherWidget extends StatelessWidget {
  final bool isCompact;

  const WeatherWidget({this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(ApiarioTheme.getPadding(context)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: ApiarioTheme.secondaryColor,
                  size: isCompact ? 20 : 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Condiciones Climáticas',
                  style: ApiarioTheme.titleStyle.copyWith(
                    fontSize: ApiarioTheme.getSubtitleFontSize(context) - 4,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            isCompact || ResponsiveBreakpoints.isMobile(context)
                ? Column(
                    children: [
                      _WeatherItem('Temperatura', '24°C', Icons.thermostat),
                      SizedBox(height: 8),
                      _WeatherItem('Humedad', '65%', Icons.water_drop),
                      SizedBox(height: 8),
                      _WeatherItem('Viento', '12 km/h', Icons.air),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _WeatherItem('Temperatura', '24°C', Icons.thermostat),
                      _WeatherItem('Humedad', '65%', Icons.water_drop),
                      _WeatherItem('Viento', '12 km/h', Icons.air),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _WeatherItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _WeatherItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: ApiarioTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: ApiarioTheme.primaryColor,
            size: isMobile ? 20 : 24,
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: ApiarioTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: ApiarioTheme.getBodyFontSize(context),
                ),
              ),
              Text(
                label,
                style: ApiarioTheme.bodyStyle.copyWith(
                  fontSize: ApiarioTheme.getBodyFontSize(context) - 4,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductionChart extends StatelessWidget {
  final List<Monitoreo> monitoreos;
  final bool isCompact;

  const ProductionChart({required this.monitoreos, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final height = isCompact
        ? 150.0
        : (ResponsiveBreakpoints.isMobile(context) ? 180.0 : 200.0);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(ApiarioTheme.getPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: ApiarioTheme.primaryColor,
                  size: 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Actividad de Monitoreo',
                    style: ApiarioTheme.titleStyle.copyWith(
                      fontSize: ApiarioTheme.getSubtitleFontSize(context) - 4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: isCompact ? 32 : 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gráfico de Actividad',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: ApiarioTheme.getBodyFontSize(context),
                      ),
                    ),
                    Text(
                      '${monitoreos.length} monitoreos registrados',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: ApiarioTheme.getBodyFontSize(context) - 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ApiarioTheme.primaryColor.withOpacity(0.3),
            width: 2.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: ApiarioTheme.primaryColor,
            size: ResponsiveBreakpoints.isMobile(context) ? 24 : 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: ApiarioTheme.titleStyle.copyWith(
                fontSize: ApiarioTheme.getSubtitleFontSize(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
