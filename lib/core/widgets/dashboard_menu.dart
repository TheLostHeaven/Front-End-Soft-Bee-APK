import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sotfbee/features/admin/history/presentation/inspection_history_page.dart';
import 'package:sotfbee/features/admin/inventory/presentation/inventory_management_page.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/main_monitoring_page.dart';
import 'package:sotfbee/features/admin/reports/presentation/dashboard_reports_page.dart';
import 'package:sotfbee/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:sotfbee/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sotfbee/features/auth/data/models/user_model.dart';
import 'package:sotfbee/features/auth/presentation/pages/user_profile_page.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Importa la página corregida

class MenuScreen extends StatefulWidget {
  @override
  _EnhancedMenuScreenState createState() => _EnhancedMenuScreenState();
}

class _EnhancedMenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _backgroundController;
  int? _hoveredIndex;
  Offset _mousePosition = Offset.zero;
  UserProfile? _userProfile;

  final List<MenuItemData> _menuItems = [
    MenuItemData(
      title: 'Monitoreo',
      icon: Icons.monitor,
      color: Color(0xFFFBC209),
      description: 'Supervisa el estado de tus colmenas en tiempo real',
      route: MainMonitoringScreen(),
    ),
    MenuItemData(
      title: 'Inventario',
      icon: Icons.inventory,
      color: Color(0xFFFFA500),
      description: 'Gestiona el inventario de tu apiario',
      route: GestionInventarioUpdated(),
    ),
    MenuItemData(
      title: 'Informes',
      icon: Icons.insert_chart,
      color: Color(0xFFFFB700),
      description: 'Genera reportes detallados de producción',
      route: DashboardScreen(),
    ),
    MenuItemData(
      title: 'Historial',
      icon: Icons.history,
      color: Color(0xFFFF9800),
      description: 'Revisa el historial de inspecciones',
      route: HistorialInspeccionesScreenModified(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  Future<void> _loadUserProfile() async {
    final token = await AuthStorage.getToken();
    if (token != null) {
      try {
        final profile = await AuthService.getUserProfile(token);
        setState(() => _userProfile = profile);
      } catch (e) {
        print('Error cargando perfil: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: (event) {
          setState(() {
            _mousePosition = event.localPosition;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFFF8E1),
                Color(0xFFFFF3C4).withOpacity(0.3),
              ],
            ),
          ),
          child: Stack(
            children: [
              _buildAnimatedBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _buildEnhancedHeader(context),
                    Expanded(child: _buildInteractiveMenu()),
                    if (MediaQuery.of(context).size.width > 900)
                      _buildDesktopStats(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100 + (50 * _backgroundController.value),
              right: -100 + (30 * _backgroundController.value),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFFBC209).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150 + (40 * _backgroundController.value),
              left: -100 + (20 * _backgroundController.value),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFFFA500).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFFBC209).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Icon(
                            Icons.hexagon_outlined,
                            color: Color(0xFFFBC209),
                            size: 40,
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .rotate(duration: 8.seconds, curve: Curves.easeInOut),
                    ],
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                            'SoftBee',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .slideX(
                            begin: -0.2,
                            end: 0,
                            duration: 800.ms,
                            curve: Curves.easeOutQuad,
                          ),
                      Text(
                            'Sistema de Gestión Apícola',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 200.ms)
                          .slideX(begin: -0.1, end: 0, duration: 600.ms),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_userProfile != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserManagementPage(user: _userProfile),
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFBC209).withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                _userProfile != null &&
                                    _userProfile!.profilePicture !=
                                        'default_profile.jpg'
                                ? NetworkImage(
                                    'https://softbee-back-end.onrender.com/uploads/${_userProfile!.profilePicture}',
                                  )
                                : AssetImage('images/userSoftbee.png')
                                      as ImageProvider,
                          ),
                        ),
                        SizedBox(height: 6),
                        // Mostrar primer nombre en lugar del botón de cerrar sesión
                        if (_userProfile != null)
                          Text(
                            _getFirstName(_userProfile!.name),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Botón de cerrar sesión en una ubicación diferente
                  IconButton(
                    icon: Icon(Icons.logout, size: 20, color: Colors.red),
                    tooltip: 'Cerrar sesión',
                    onPressed: () async {
                      await AuthStorage.deleteToken();
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 60),
          Column(
            children: [
              Text(
                    'Menú Principal',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFBC209),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 800.ms, delay: 300.ms),
              SizedBox(height: 12),
              Container(
                    width: 80,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFBC209), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 500.ms)
                  .slideX(begin: 0.2, end: 0, duration: 800.ms, delay: 500.ms)
                  .then(delay: 200.ms)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scaleX(begin: 1, end: 1.3, duration: 2.seconds),
            ],
          ),
        ],
      ),
    );
  }

  // Función para obtener solo el primer nombre
  String _getFirstName(String fullName) {
    return fullName.split(' ')[0];
  }

  Widget _buildInteractiveMenu() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;
        bool isDesktop = constraints.maxWidth > 900;

        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.1;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
          childAspectRatio = 1.9;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 0.85;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              return EnhancedMenuButton(
                    title: item.title,
                    icon: item.icon,
                    color: item.color,
                    description: item.description,
                    index: index,
                    isHovered: _hoveredIndex == index,
                    isDesktop: isDesktop,
                    mousePosition: _mousePosition,
                    onHover: (hovered) {
                      setState(() {
                        _hoveredIndex = hovered ? index : null;
                      });
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => item.route,
                          transitionsBuilder: (_, animation, __, child) {
                            return SlideTransition(
                              position:
                                  Tween<Offset>(
                                        begin: Offset(1.0, 0.0),
                                        end: Offset.zero,
                                      )
                                      .chain(
                                        CurveTween(
                                          curve: Curves.easeInOutQuart,
                                        ),
                                      )
                                      .animate(animation),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: (200 * index).ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 600.ms,
                    delay: (200 * index).ms,
                    curve: Curves.easeOutQuint,
                  );
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopStats() {
    final stats = [
      {'label': 'Colmenas Activas', 'value': '24', 'color': Color(0xFFFBC209)},
      {
        'label': 'Producción Mensual',
        'value': '156kg',
        'color': Color(0xFFFFA500),
      },
      {
        'label': 'Inspecciones Pendientes',
        'value': '3',
        'color': Color(0xFFFFB700),
      },
      {'label': 'Alertas', 'value': '1', 'color': Colors.red},
    ];

    return Container(
      margin: EdgeInsets.all(9),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> stat = entry.value;

          return Expanded(
            child:
                Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (stat['color'] as Color).withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            stat['value'],
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: stat['color'],
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            stat['label'],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: (100 * index).ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 600.ms,
                      delay: (100 * index).ms,
                    ),
          );
        }).toList(),
      ),
    );
  }
}

class MenuItemData {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final Widget route;

  MenuItemData({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.route,
  });
}

class EnhancedMenuButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final int index;
  final bool isHovered;
  final bool isDesktop;
  final Offset mousePosition;
  final Function(bool) onHover;
  final VoidCallback onTap;

  EnhancedMenuButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.index,
    required this.isHovered,
    required this.isDesktop,
    required this.mousePosition,
    required this.onHover,
    required this.onTap,
  });

  @override
  _EnhancedMenuButtonState createState() => _EnhancedMenuButtonState();
}

class _EnhancedMenuButtonState extends State<EnhancedMenuButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovered != oldWidget.isHovered) {
      if (widget.isHovered) {
        _glowController.forward();
        if (widget.isDesktop) {
          _shimmerController.forward();
        }
      } else {
        _glowController.reverse();
        _shimmerController.reset();
      }
    }
  }

  void _onTapDown(TapDownDetails details) => _scaleController.forward();
  void _onTapUp(TapUpDetails details) => _scaleController.reverse();
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleController,
            _glowController,
            _shimmerController,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                transform: Matrix4.identity()
                  ..translate(
                    0.0,
                    widget.isHovered && widget.isDesktop ? -8.0 : 0.0,
                  )
                  ..scale(widget.isHovered && widget.isDesktop ? 1.05 : 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withOpacity(0.8),
                        widget.color,
                        widget.color.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(
                          widget.isHovered ? 0.4 : 0.2,
                        ),
                        blurRadius: widget.isHovered ? 20 : 12,
                        offset: Offset(0, widget.isHovered ? 12 : 6),
                      ),
                      if (widget.isHovered && widget.isDesktop)
                        BoxShadow(
                          color: widget.color.withOpacity(0.2),
                          blurRadius: 40,
                          offset: Offset(0, 20),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned(
                          right: -30,
                          bottom: -30,
                          child: Opacity(
                            opacity: 0.15,
                            child: Icon(
                              widget.icon,
                              size: widget.isDesktop ? 140 : 120,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Animated circles
                        if (widget.isDesktop) ...[
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: 0.1 * _glowAnimation.value,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: 0.15 * _glowAnimation.value,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // Shimmer effect
                        if (widget.isDesktop)
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return Positioned(
                                left: -100 + (300 * _shimmerController.value),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        // Content
                        Padding(
                          padding: EdgeInsets.all(
                            widget.isDesktop ? 24.0 : 20.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    padding: EdgeInsets.all(
                                      widget.isHovered ? 14 : 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(
                                        widget.isHovered ? 0.3 : 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      widget.icon,
                                      color: Colors.white,
                                      size: widget.isDesktop ? 32 : 28,
                                    ),
                                  ),
                                  SizedBox(height: widget.isDesktop ? 20 : 16),
                                  AnimatedDefaultTextStyle(
                                    duration: Duration(milliseconds: 300),
                                    style: GoogleFonts.poppins(
                                      fontSize: widget.isDesktop ? 22 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    child: Text(widget.title),
                                  ),
                                  if (widget.isDesktop) ...[
                                    SizedBox(height: 8),
                                    AnimatedOpacity(
                                      duration: Duration(milliseconds: 300),
                                      opacity: widget.isHovered ? 1.0 : 0.8,
                                      child: Text(
                                        widget.description,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.9),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // Desktop interactive elements
                              if (widget.isDesktop)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: List.generate(3, (index) {
                                        return AnimatedContainer(
                                          duration: Duration(
                                            milliseconds: 300 + (index * 100),
                                          ),
                                          margin: EdgeInsets.only(right: 6),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(
                                              widget.isHovered ? 1.0 : 0.4,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    AnimatedOpacity(
                                      duration: Duration(milliseconds: 300),
                                      opacity: widget.isHovered ? 1.0 : 0.0,
                                      child: Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
