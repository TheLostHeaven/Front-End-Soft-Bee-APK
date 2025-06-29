import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:sotfbee/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sotfbee/features/auth/data/datasources/auth_local_datasource.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final nombreCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  int _currentStep = 0;

  String? _nombreError;
  String? _correoError;
  String? _telefonoError;
  String? _passError;
  String? _confirmPassError;
  bool _showValidation = false;

  List<ApiaryData> _apiaries = [ApiaryData()];

  static const Color primaryYellow = Color(0xFFFFD100);
  static const Color accentYellow = Color(0xFFFFAB00);
  static const Color lightYellow = Color(0xFFFFF8E1);
  static const Color darkYellow = Color(0xFFF9A825);
  static const Color textDark = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    nombreCtrl.addListener(() => _validateNombre(nombreCtrl.text));
    correoCtrl.addListener(() => _validateCorreo(correoCtrl.text));
    telefonoCtrl.addListener(() => _validateTelefono(telefonoCtrl.text));
    passCtrl.addListener(() => _validatePassword(passCtrl.text));
    confirmPassCtrl.addListener(
      () => _validateConfirmPassword(confirmPassCtrl.text),
    );
  }

  Future<void> registrarUsuario() async {
    final url = Uri.parse("https://softbee-back-end-1.onrender.com/api/register");

    try {
      setState(() => _isLoading = true);

      if (!_formKey.currentState!.validate()) {
        setState(() => _showValidation = true);
        return;
      }

      final apiariesData = _apiaries.map((apiary) {
        return {
          "apiary_name": apiary.nameController.text.trim(),
          "location": apiary.addressController.text.trim(),
          "beehives_count": int.tryParse(apiary.hiveCountController.text) ?? 0,
          "treatments": apiary.appliesTreatments ? "True" : "False",
        };
      }).toList();

      final requestBody = {
        "nombre": nombreCtrl.text.trim(),
        "username": AuthService.generateUsername(correoCtrl.text.trim()),
        "email": correoCtrl.text.trim().toLowerCase(),
        "phone": _limpiarTelefono(telefonoCtrl.text.trim()),
        "password": passCtrl.text,
        "apiarios": apiariesData,
      };

      debugPrint("Enviando registro: ${jsonEncode(requestBody)}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      debugPrint("Respuesta: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 201) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse['token'] != null) {
          await AuthStorage.saveToken(decodedResponse['token']);
          debugPrint("Token guardado: ${decodedResponse['token']}");
        }

        _showSuccessDialog(decodedResponse['message'] ?? 'Registro exitoso');
      } else {
        final error = jsonDecode(response.body);
        _showErrorDialog(
          error['error'] ?? error['detail'] ?? 'Error en el registro',
        );
      }
    } catch (e) {
      debugPrint("Error en registro: $e");
      _showErrorDialog('Error de conexión: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _limpiarTelefono(String telefono) {
    return telefono.replaceAll(RegExp(r'[^\d]'), '');
  }

  void _validateNombre(String value) {
    setState(() {
      if (value.isEmpty) {
        _nombreError = 'El nombre es requerido';
      } else if (value.length < 2) {
        _nombreError = 'El nombre debe tener al menos 2 caracteres';
      } else if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
        _nombreError = 'El nombre solo puede contener letras';
      } else {
        _nombreError = null;
      }
    });
  }

  void _validateCorreo(String value) {
    setState(() {
      if (value.isEmpty) {
        _correoError = 'El correo es requerido';
      } else if (!RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(value)) {
        _correoError = 'Ingresa un correo válido (ej: usuario@dominio.com)';
      } else {
        _correoError = null;
      }
    });
  }

  void _validateTelefono(String value) {
    setState(() {
      if (value.isEmpty) {
        _telefonoError = 'El teléfono es requerido';
      } else {
        String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
        if (cleanPhone.length < 7) {
          _telefonoError = 'Número demasiado corto';
        } else {
          _telefonoError = null;
        }
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passError = 'La contraseña es requerida';
      } else if (value.length < 8) {
        _passError = 'La contraseña debe tener al menos 8 caracteres';
      } else if (!RegExp(
        r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
      ).hasMatch(value)) {
        _passError = 'Debe contener al menos: 1 letra, 1 número y 1 símbolo';
      } else {
        _passError = null;
      }

      if (confirmPassCtrl.text.isNotEmpty) {
        _validateConfirmPassword(confirmPassCtrl.text);
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPassError = 'Confirma tu contraseña';
      } else if (value != passCtrl.text) {
        _confirmPassError = 'Las contraseñas no coinciden';
      } else {
        _confirmPassError = null;
      }
    });
  }

  TextInputFormatter get _phoneFormatter {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

      if (text.length <= 3) {
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      } else if (text.length <= 6) {
        text = '${text.substring(0, 3)} ${text.substring(3)}';
      } else if (text.length <= 10) {
        text =
            '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6)}';
      } else {
        text = text.substring(0, 10);
        text =
            '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6)}';
      }

      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¡Registro Exitoso!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textDark.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Colors.green, Color(0xFF4CAF50)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Continuar',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Error en el Registro',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textDark.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Colors.red, Color(0xFFE53935)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Intentar de nuevo',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    correoCtrl.dispose();
    telefonoCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    for (final apiary in _apiaries) {
      apiary.dispose();
    }
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
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
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
                    child: Icon(
                      Icons.hive,
                      size: logoSize * 0.4,
                      color: Colors.white,
                    ),
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
                    'Crea tu cuenta de apicultor',
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
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Registro',
                          style: GoogleFonts.poppins(
                            fontSize: titleSize * 0.9,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: verticalSpacing),
                        _buildRegistrationStepper(width, height, subtitleSize),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // CORRECCIÓN PRINCIPAL: Layout móvil mejorado con scroll
  Widget _buildPortraitLayout(
    BuildContext context,
    double width,
    double height,
    bool isSmallScreen,
  ) {
    final logoSize = width * (isSmallScreen ? 0.25 : 0.10);
    final titleSize = width * (isSmallScreen ? 0.05 : 0.02);
    final subtitleSize = width * (isSmallScreen ? 0.04 : 0.03);
    final verticalSpacing = height * 0.02;

    return Column(
      children: [
        // Header fijo
        Container(
          height: height * 0.2, // Reducido para dar más espacio al contenido
          padding: EdgeInsets.all(width * 0.05),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
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
                    child: Icon(
                      Icons.hive,
                      size: logoSize * 0.4,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: verticalSpacing * 0.5),
                Text(
                  'Registro SoftBee',
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
        // Contenido scrolleable
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildRegistrationStepper(width, height, subtitleSize),
                  SizedBox(height: verticalSpacing),
                  _buildFooter(width, subtitleSize),
                ],
              ),
            ),
          ),
        ),
      ],
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
    final horizontalPadding = width * 0.05;
    final verticalSpacing = height * 0.03;

    return Row(
      children: [
        // Logo lateral fijo
        Container(
          width: width * 0.3,
          padding: EdgeInsets.all(horizontalPadding),
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
                child: Icon(
                  Icons.hive,
                  size: logoSize * 0.4,
                  color: Colors.white,
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
        // Contenido scrolleable
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Form(
              key: _formKey,
              child: _buildRegistrationStepper(width, height, subtitleSize),
            ),
          ),
        ),
      ],
    );
  }

  // CORRECCIÓN PRINCIPAL: Stepper con scroll mejorado
  Widget _buildRegistrationStepper(
    double width,
    double height,
    double fontSize,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: primaryYellow, secondary: accentYellow),
      ),
      child: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        physics:
            const NeverScrollableScrollPhysics(), // Evita conflictos de scroll
        onStepContinue: () {
          final isLastStep = _currentStep == 1;

          if (isLastStep) {
            registrarUsuario();
          } else {
            setState(() {
              _showValidation = true;
            });

            _validateNombre(nombreCtrl.text);
            _validateCorreo(correoCtrl.text);
            _validateTelefono(telefonoCtrl.text);
            _validatePassword(passCtrl.text);
            _validateConfirmPassword(confirmPassCtrl.text);

            if (_nombreError == null &&
                _correoError == null &&
                _telefonoError == null &&
                _passError == null &&
                _confirmPassError == null &&
                nombreCtrl.text.isNotEmpty &&
                correoCtrl.text.isNotEmpty &&
                telefonoCtrl.text.isNotEmpty &&
                passCtrl.text.isNotEmpty &&
                confirmPassCtrl.text.isNotEmpty) {
              setState(() {
                _currentStep += 1;
              });
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          } else {
            Navigator.of(context).pop();
          }
        },
        onStepTapped: (step) {
          setState(() {
            _currentStep = step;
          });
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 1;

          return Container(
            margin: const EdgeInsets.only(
              top: 20,
              bottom: 20,
            ), // Más margen para mejor accesibilidad
            child: Row(
              children: [
                Expanded(
                  child: Container(
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
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ), // Más padding para mejor toque
                      ),
                      child: _isLoading && isLastStep
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
                                Icon(
                                  isLastStep
                                      ? Icons.check_circle
                                      : Icons.navigate_next,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isLastStep ? 'Registrarse' : 'Continuar',
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryYellow, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ), // Más padding para mejor toque
                    ),
                    child: Text(
                      _currentStep > 0 ? 'Atrás' : 'Cancelar',
                      style: GoogleFonts.poppins(
                        color: darkYellow,
                        fontWeight: FontWeight.normal,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text(
              'Información Personal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            content: Column(
              children: [
                _buildTextField(
                  controller: nombreCtrl,
                  label: 'Nombre completo',
                  hint: 'Ingresa tu nombre',
                  icon: Icons.person_outline,
                  errorText: _nombreError,
                  onChanged: _validateNombre,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: correoCtrl,
                  label: 'Correo electrónico',
                  hint: 'ejemplo@correo.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _correoError,
                  onChanged: _validateCorreo,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    if (!RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    ).hasMatch(value)) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: telefonoCtrl,
                  label: 'Teléfono',
                  hint: '3XX XXX XXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _phoneFormatter,
                  ],
                  errorText: _telefonoError,
                  onChanged: _validateTelefono,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: passCtrl,
                  label: 'Contraseña',
                  hint: 'Crea una contraseña segura',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  errorText: _passError,
                  onChanged: _validatePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una contraseña';
                    }
                    if (value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: confirmPassCtrl,
                  label: 'Confirmar contraseña',
                  hint: 'Repite tu contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  errorText: _confirmPassError,
                  onChanged: _validateConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    if (value != passCtrl.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text(
              'Información de Apiarios',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            content: Column(
              children: [
                Text(
                  'Agrega información sobre tus apiarios',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    color: textDark.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                ..._apiaries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final apiary = entry.value;

                  return _buildApiaryCard(
                    apiary: apiary,
                    index: index,
                    onRemove: () => _removeApiary(index),
                    showRemoveButton: _apiaries.length > 1,
                  );
                }).toList(),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    bottom: 20,
                  ), // Más espacio inferior
                  child: OutlinedButton.icon(
                    onPressed: _addApiary,
                    icon: const Icon(Icons.add, color: darkYellow),
                    label: Text(
                      'Agregar otro apiario',
                      style: GoogleFonts.poppins(
                        color: darkYellow,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryYellow, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
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
    String? errorText,
    Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
            inputFormatters: inputFormatters,
            onChanged: (value) {
              if (_showValidation && onChanged != null) {
                onChanged(value);
              }
            },
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: errorText != null ? Colors.red : darkYellow,
              ),
              prefixIcon: Icon(
                icon,
                color: errorText != null ? Colors.red : primaryYellow,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: errorText != null ? Colors.red : primaryYellow,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    )
                  : (errorText != null
                        ? const Icon(Icons.error_outline, color: Colors.red)
                        : (controller.text.isNotEmpty &&
                                  errorText == null &&
                                  _showValidation
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null
                      ? Colors.red.withOpacity(0.5)
                      : primaryYellow.withOpacity(0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.red : primaryYellow,
                  width: 2,
                ),
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
        ),
        if (errorText != null && _showValidation)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorText,
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (errorText == null && controller.text.isNotEmpty && _showValidation)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Campo válido',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTreatmentSwitch({
    required bool value,
    required Function(bool) onChanged,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryYellow.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: textDark,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: textDark.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: primaryYellow,
        activeTrackColor: primaryYellow.withOpacity(0.3),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildApiaryCard({
    required ApiaryData apiary,
    required int index,
    required VoidCallback onRemove,
    required bool showRemoveButton,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryYellow.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: lightYellow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Apiario ${index + 1}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: darkYellow,
                  ),
                ),
                if (showRemoveButton)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Eliminar apiario',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextField(
                  controller: apiary.nameController,
                  label: 'Nombre del apiario',
                  hint: 'Ej: Apiario Las Flores',
                  icon: Icons.label_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el nombre del apiario';
                    }
                    if (value.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: apiary.addressController,
                  label: 'Dirección exacta del apiario',
                  hint: 'Ej: Cota, Vereda El Rosal - Finca La Esperanza',
                  icon: Icons.location_on_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La dirección es requerida';
                    }
                    if (value.length < 10) {
                      return 'La dirección es muy corta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: apiary.hiveCountController,
                  label: 'Cantidad de colmenas',
                  hint: 'Ej: 25',
                  icon: Icons.grid_view_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la cantidad';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTreatmentSwitch(
                  value: apiary.appliesTreatments,
                  onChanged: (value) {
                    setState(() {
                      apiary.appliesTreatments = value;
                    });
                  },
                  title:
                      '¿Aplicas tratamientos cuando las abejas están enfermas?',
                  subtitle:
                      'Indica si utilizas medicamentos o tratamientos veterinarios',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(double width, double fontSize) {
    return Column(
      children: [
        const SizedBox(height: 20),
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

  void _addApiary() {
    setState(() {
      _apiaries.add(ApiaryData());
    });
  }

  void _removeApiary(int index) {
    if (_apiaries.length > 1) {
      setState(() {
        _apiaries.removeAt(index);
      });
    }
  }
}

class ApiaryData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController hiveCountController = TextEditingController();
  bool appliesTreatments = false;

  void dispose() {
    nameController.dispose();
    addressController.dispose();
    hiveCountController.dispose();
  }
}
