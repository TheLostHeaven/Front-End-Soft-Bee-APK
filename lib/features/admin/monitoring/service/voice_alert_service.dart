import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceAlertService {
  static void showVoiceFeatureAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFFFF8E1).withOpacity(0.5)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con gradiente
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFBC209)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.mic_off,
                          color: Colors.white,
                          size: 28,
                        ),
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asistente Maya',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Funcionalidad Exclusiva',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: -0.3, end: 0, duration: 500.ms),

                // Contenido
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Icono principal animado
                      Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF9800).withOpacity(0.2),
                                  Color(0xFFFBC209).withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.smartphone,
                              size: 40,
                              color: Color(0xFFFF9800),
                            ),
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: Offset(1, 1),
                            end: Offset(1.1, 1.1),
                            duration: 2000.ms,
                          ),

                      SizedBox(height: 20),

                      // Título principal
                      Text(
                        'Disponible Solo en APK',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms),

                      SizedBox(height: 12),

                      // Descripción
                      Text(
                        'El asistente de voz Maya con reconocimiento de comandos está disponible únicamente en la versión APK completa de la aplicación.',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 400.ms),

                      SizedBox(height: 20),

                      // Características de Maya
                      Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFFFBC209).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Color(0xFFFF9800),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Características de Maya:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFF9800),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                _buildFeatureItem(
                                  Icons.mic,
                                  'Reconocimiento de voz en español',
                                ),
                                _buildFeatureItem(
                                  Icons.chat,
                                  'Comandos de voz inteligentes',
                                ),
                                _buildFeatureItem(
                                  Icons.speed,
                                  'Monitoreo rápido y eficiente',
                                ),
                                _buildFeatureItem(
                                  Icons.offline_bolt,
                                  'Funciona sin conexión a internet',
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 600.ms)
                          .slideY(begin: 0.2, end: 0),

                      SizedBox(height: 20),

                      // Información adicional
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Descarga la APK desde nuestro sitio web oficial para acceder a todas las funcionalidades.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 800.ms),
                    ],
                  ),
                ),

                // Botones de acción
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      // Botón principal
                      Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Entendido',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1000.ms)
                          .slideY(begin: 0.3, end: 0),

                      SizedBox(height: 12),

                      // Botón secundario
                      Container(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showDownloadInfo(context);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download,
                                color: Color(0xFFFF9800),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Información de Descarga',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFFFF9800),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 1200.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFFFF9800)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showDownloadInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.download, color: Color(0xFFFF9800)),
              SizedBox(width: 12),
              Text(
                'Descargar APK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para obtener la versión completa con Maya:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '1. Visita nuestro sitio web oficial\n'
                '2. Ve a la sección de descargas\n'
                '3. Descarga la APK más reciente\n'
                '4. Instala y disfruta de Maya',
                style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.orange[600], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Solo descarga desde fuentes oficiales',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: GoogleFonts.poppins(
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
