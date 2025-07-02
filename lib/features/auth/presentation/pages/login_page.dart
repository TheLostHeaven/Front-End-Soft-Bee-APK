import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sotfbee/core/widgets/dashboard_menu.dart';
import 'package:sotfbee/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:sotfbee/features/auth/data/datasources/auth_remote_datasource.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  static const Color primaryYellow = Color(0xFFFFD100);
  static const Color accentYellow = Color(0xFFFFAB00);
  static const Color lightYellow = Color(0xFFFFF8E1);
  static const Color darkYellow = Color(0xFFF9A825);
  static const Color textDark = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    final token = await AuthStorage.getToken();
    if (token != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MenuScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.login(
        _identifierController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response['success'] == true) {
        final token = response['token'];
        await AuthStorage.saveToken(token);

        // Verificar token guardado
        final savedToken = await AuthStorage.getToken();
        debugPrint("Token guardado: $savedToken");

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MenuScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Error en el inicio de sesión';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final isSmallScreen = width < 600;
          final isLandscape = width > height;
          final isDesktop = width > 1024;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lightYellow, Colors.white],
              ),
            ),
            child: SafeArea(
              child: isDesktop
                  ? _buildDesktopLayout(context, width, height)
                  : (isLandscape && isSmallScreen
                        ? _buildLandscapeLayout(context, width, height)
                        : _buildPortraitLayout(
                            context,
                            width,
                            height,
                            isSmallScreen,
                          )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    double width,
    double height,
  ) {
    final logoSize = width * 0.12;
    final titleSize = width * 0.025;
    final subtitleSize = width * 0.015;
    final buttonHeight = height * 0.07;
    final verticalSpacing = height * 0.025;

    return Row(
      children: [
        Container(
          width: width * 0.4,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [lightYellow, Colors.white.withOpacity(0.9)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(5, 0),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: logoSize,
                  width: logoSize,
                  decoration: BoxDecoration(
                    color: primaryYellow,
                    borderRadius: BorderRadius.circular(logoSize * 0.3),
                    boxShadow: [
                      BoxShadow(
                        color: darkYellow.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/Logo.png',
                    width: logoSize * 0.6,
                    height: logoSize * 0.6,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: verticalSpacing),
                Text(
                  'SoftBee',
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: verticalSpacing * 0.5),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.02,
                    vertical: height * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: lightYellow,
                    borderRadius: BorderRadius.circular(height * 0.02),
                    border: Border.all(color: primaryYellow, width: 2),
                  ),
                  child: Text(
                    'Bienvenido a tu plataforma',
                    style: GoogleFonts.poppins(
                      fontSize: subtitleSize,
                      color: darkYellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: height * 0.05,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _buildLoginForm(
                    titleSize * 0.9,
                    subtitleSize,
                    buttonHeight,
                    verticalSpacing,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    double width,
    double height,
    bool isSmallScreen,
  ) {
    final logoSize = width * (isSmallScreen ? 0.25 : 0.1);
    final titleSize = width * (isSmallScreen ? 0.10 : 0.04);
    final subtitleSize = width * (isSmallScreen ? 0.04 : 0.02);
    final buttonHeight = height * 0.07;
    final verticalSpacing = height * 0.02;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height * 0.35,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: logoSize,
                      width: logoSize,
                      decoration: BoxDecoration(
                        color: primaryYellow,
                        borderRadius: BorderRadius.circular(logoSize * 0.3),
                        boxShadow: [
                          BoxShadow(
                            color: darkYellow.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: logoSize * 0.6,
                        height: logoSize * 0.6,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: verticalSpacing),
                    Text(
                      'SoftBee',
                      style: GoogleFonts.poppins(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildLoginForm(
              titleSize * 0.8,
              subtitleSize,
              buttonHeight,
              verticalSpacing,
            ),
            Padding(
              padding: EdgeInsets.only(top: verticalSpacing),
              child: _buildFooter(width, subtitleSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    double width,
    double height,
  ) {
    final logoSize = height * 0.25;
    final titleSize = height * 0.06;
    final subtitleSize = height * 0.035;
    final buttonHeight = height * 0.12;
    final horizontalPadding = width * 0.05;
    final verticalSpacing = height * 0.03;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width * 0.4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: logoSize,
                    width: logoSize,
                    decoration: BoxDecoration(
                      color: primaryYellow,
                      borderRadius: BorderRadius.circular(logoSize * 0.25),
                      boxShadow: [
                        BoxShadow(
                          color: darkYellow.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: logoSize * 0.6,
                      height: logoSize * 0.6,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: verticalSpacing * 0.5),
                  Text(
                    'SoftBee',
                    style: GoogleFonts.poppins(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: width * 0.05),
            Expanded(
              child: _buildLoginForm(
                titleSize * 0.8,
                subtitleSize,
                buttonHeight,
                verticalSpacing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(
    double titleSize,
    double subtitleSize,
    double buttonHeight,
    double verticalSpacing,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Iniciar Sesión',
            style: GoogleFonts.poppins(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: verticalSpacing),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: verticalSpacing),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          _buildTextField(
            controller: _identifierController,
            label: 'Usuario o Email',
            hint: 'ejemplo@correo.com o tu_usuario',
            icon: Icons.person_outline,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingrese su usuario o email';
              }
              return null;
            },
          ),
          SizedBox(height: verticalSpacing),

          _buildTextField(
            controller: _passwordController,
            label: 'Contraseña',
            hint: 'Ingresa tu contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingrese su contraseña';
              }
              if (value.length < 8) {
                return 'La contraseña debe tener al menos 8 caracteres';
              }
              return null;
            },
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ///resetPassword
                Navigator.pushNamed(context, '/forgot-password');
              },
              style: TextButton.styleFrom(foregroundColor: darkYellow),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w300,
                  fontSize: subtitleSize * 0.9,
                ),
              ),
            ),
          ),

          SizedBox(height: verticalSpacing),

          SizedBox(
            height: buttonHeight,
            child: _buildLoginButton(subtitleSize),
          ),

          SizedBox(height: verticalSpacing),

          _buildDivider(),

          SizedBox(height: verticalSpacing),

          SizedBox(
            height: buttonHeight,
            child: _buildRegisterButton(subtitleSize),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(color: textDark),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: darkYellow),
          prefixIcon: Icon(icon, color: primaryYellow),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: primaryYellow,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryYellow.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryYellow, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildLoginButton(double fontSize) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryYellow.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: const LinearGradient(
          colors: [primaryYellow, accentYellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Iniciar Sesión',
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: primaryYellow.withOpacity(0.5), thickness: 1.5),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightYellow,
              shape: BoxShape.circle,
              border: Border.all(color: primaryYellow, width: 1.5),
            ),
            child: Text(
              'O',
              style: GoogleFonts.poppins(
                color: darkYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Divider(color: primaryYellow.withOpacity(0.5), thickness: 1.5),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(double fontSize) {
    return OutlinedButton(
      onPressed: () {
        Navigator.pushNamed(context, '/register');
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: primaryYellow, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_add_outlined, color: darkYellow, size: 20),
          const SizedBox(width: 8),
          Text(
            'Crear una cuenta',
            style: GoogleFonts.poppins(
              color: darkYellow,
              fontWeight: FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(double width, double fontSize) {
    return Column(
      children: [
        Text(
          '© ${DateTime.now().year} SoftBee. Todos los derechos reservados.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: textDark.withOpacity(0.6),
            fontSize: fontSize * 0.7,
          ),
        ),
      ],
    );
  }
}
