import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EnhancedCardWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isCompact;
  final int animationDelay;
  final bool showBorder;

  const EnhancedCardWidget({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.trailing,
    this.isCompact = true,
    this.animationDelay = 0,
    this.showBorder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCompact ? 1 : 2,
      margin: EdgeInsets.symmetric(
        horizontal: 2,
        vertical: isCompact ? 3 : 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: showBorder 
          ? BorderSide(color: color.withOpacity(0.3), width: 1)
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.03),
              ],
            ),
          ),
          child: Row(
            children: [
              // Icono minimalista
              Container(
                width: isCompact ? 32 : 40,
                height: isCompact ? 32 : 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isCompact ? 16 : 20,
                ),
              ).animate().scale(
                delay: Duration(milliseconds: animationDelay),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),

              SizedBox(width: 12),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: isCompact ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(
                          fontSize: isCompact ? 10 : 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: animationDelay + 100),
                duration: 300.ms,
              ),

              // Trailing widget
              if (trailing != null) ...[
                SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    ).animate().slideX(
      begin: 0.3,
      end: 0,
      delay: Duration(milliseconds: animationDelay),
      duration: 400.ms,
      curve: Curves.easeOut,
    );
  }
}

class StatCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isCompact;
  final int animationDelay;
  final VoidCallback? onTap;

  const StatCardWidget({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isCompact = true,
    this.animationDelay = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isCompact ? 28 : 36,
              height: isCompact ? 28 : 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isCompact ? 14 : 18,
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            ).scale(
              begin: Offset(1, 1),
              end: Offset(1.1, 1.1),
              duration: 2000.ms,
            ),

            SizedBox(height: 8),

            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: isCompact ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isCompact ? 9 : 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ).animate().fadeIn(
        delay: Duration(milliseconds: animationDelay),
        duration: 600.ms,
      ).slideY(
        begin: 0.2,
        end: 0,
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String message;
  final Color color;

  const LoadingWidget({
    Key? key,
    this.message = "Cargando...",
    this.color = const Color(0xFFFBC209),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hive, size: 48, color: color),
          ).animate(onPlay: (controller) => controller.repeat()).rotate(duration: 2000.ms),

          SizedBox(height: 24),

          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),

          SizedBox(height: 12),

          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 2,
          ),
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Color color;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
    this.color = const Color(0xFFFF9800),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: color.withOpacity(0.7),
              ),
            ).animate().scale(
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),

            SizedBox(height: 24),

            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),

            SizedBox(height: 8),

            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),

            if (actionText != null && onAction != null) ...[
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.add, size: 18),
                label: Text(
                  actionText!,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).scale(),
            ],
          ],
        ),
      ),
    );
  }
}

class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onRetry;

  const ConnectionStatusWidget({
    Key? key,
    required this.isConnected,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected ? Color(0xFF4CAF50) : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GestureDetector(
        onTap: onRetry,
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
    ).animate().fadeIn(delay: 200.ms).scale();
  }
}

class ActionButtonWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isCompact;

  const ActionButtonWidget({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isCompact = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isCompact ? 16 : 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: isCompact ? 11 : 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
      ),
    );
  }
}

class CustomAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isConnected;
  final VoidCallback? onSync;
  final List<Widget>? additionalActions;

  const CustomAppBarWidget({
    Key? key,
    required this.title,
    required this.isConnected,
    this.onSync,
    this.additionalActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.hive, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
      backgroundColor: Color(0xFFFF9800),
      elevation: 0,
      actions: [
        ConnectionStatusWidget(
          isConnected: isConnected,
          onRetry: onSync,
        ),
        if (onSync != null)
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: onSync,
            tooltip: "Sincronizar",
          ).animate().fadeIn(delay: 400.ms).scale(),
        if (additionalActions != null) ...additionalActions!,
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}