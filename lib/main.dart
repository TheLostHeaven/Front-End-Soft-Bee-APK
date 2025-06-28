import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';
import 'package:sotfbee/core/widgets/dashboard_menu.dart';
import 'package:sotfbee/features/admin/history/controllers/monitoreo_controllers.dart';
import 'package:sotfbee/features/auth/presentation/pages/confirm_reset_page.dart';
import 'package:sotfbee/features/auth/presentation/pages/login_page.dart';
import 'package:sotfbee/features/auth/presentation/pages/register_page.dart';
import 'package:sotfbee/features/auth/presentation/pages/reset_password_page.dart';
import 'package:sotfbee/features/onboarding/presentation/landing_page.dart';

// Hive
import 'package:hive_flutter/hive_flutter.dart';

// Opcional: para otras plataformas
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sotfbee/core/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Hive para todas las plataformas
  await Hive.initFlutter();

  // FFI initialization is now handled in LocalDBService to avoid conflicts.

  // Configura la estrategia de URLs limpias en Web
  // setUrlStrategy(PathUrlStrategy());

  // Ejecuta la app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MonitoreoController()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: const SoftBeeApp(),
    ),
  );
}

class SoftBeeApp extends StatelessWidget {
  const SoftBeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoftBee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFFF8F5E4),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8D6E63),
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: const Color(0xFFFBC209),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/reset-password') ?? false) {
          final uri = Uri.parse(settings.name!);
          final token = uri.queryParameters['token'] ?? '';

          if (token.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => ResetPasswordPage(token: token),
              settings: settings,
            );
          }
        }

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const LandingPage());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (context) => RegisterPage());
          case '/dashboard':
            return MaterialPageRoute(builder: (context) => MenuScreen());
          case '/forgot-password':
            return MaterialPageRoute(
              builder: (context) => const ForgotPasswordPage(),
            );
          default:
            return MaterialPageRoute(builder: (context) => const LandingPage());
        }
      },
    );
  }
}
