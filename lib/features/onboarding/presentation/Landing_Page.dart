import 'package:flutter/material.dart';
import 'package:sotfbee/features/auth/presentation/pages/login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFBBF24), // Amber 400
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  '/images/Logo.png', // Ruta de tu imagen
                  width: 24, // Ajusta el tamaño según necesites
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'SoftBee',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('Iniciar Sesión'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B), // Amber 500
              foregroundColor: Colors.white,
            ),
            child: const Text('Descargar'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildFeaturesSection(context),
            _buildVoiceCommandsSection(context),
            _buildBenefitsSection(context),
            _buildCtaSection(context),
            _buildContactSection(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFEF3C7), Colors.white], // Amber 50 to white
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7), // Amber 100
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Innovación Apícola',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E), // Amber 800
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SoftBee: Control de Apiarios por Comandos de Voz',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'La solución definitiva para apicultores. Monitorea tus colmenas y gestiona toda la información de tu apiario utilizando solo tu voz.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download),
                          label: const Text('Descargar Ahora'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B), // Amber 500
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Ver Demostración'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (MediaQuery.of(context).size.width > 800)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 300,
                      height: 600,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 8),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Column(
                          children: [
                            Container(
                              height: 24,
                              color: Colors.black,
                            ),
                            Expanded(
                              child: Container(
                                color: Colors.grey[100],
                                child: const Center(
                                  child: Text(
                                    'SoftBee App Preview',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // Amber 100
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Características',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E), // Amber 800
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Todo lo que necesitas para gestionar tu apiario',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'SoftBee combina tecnología avanzada con una interfaz intuitiva para ofrecerte la mejor experiencia en el manejo de tus colmenas.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildFeatureCard(
                icon: Icons.mic,
                title: 'Control por Voz',
                description:
                    'Registra datos, consulta información y controla la aplicación utilizando solo comandos de voz.',
              ),
              _buildFeatureCard(
                icon: Icons.bar_chart,
                title: 'Estadísticas Detalladas',
                description:
                    'Visualiza la producción, salud y rendimiento de tus colmenas con gráficos intuitivos.',
              ),
              _buildFeatureCard(
                icon: Icons.storage,
                title: 'Almacenamiento Seguro',
                description:
                    'Toda la información de tu apiario almacenada de forma segura y accesible desde cualquier dispositivo.',
              ),
              _buildFeatureCard(
                icon: Icons.notifications,
                title: 'Alertas y Recordatorios',
                description:
                    'Recibe notificaciones sobre tareas pendientes, tratamientos y revisiones programadas.',
              ),
              _buildFeatureCard(
                icon: Icons.smartphone,
                title: 'Funciona Sin Internet',
                description:
                    'Trabaja en el campo sin preocuparte por la conexión. Sincroniza los datos cuando vuelvas a tener señal.',
              ),
              _buildFeatureCard(
                icon: Icons.volume_up,
                title: 'Respuesta Auditiva',
                description:
                    'La aplicación te responde verbalmente, permitiéndote trabajar sin necesidad de mirar la pantalla.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), // Amber 100
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFD97706), // Amber 600
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCommandsSection(BuildContext context) {
    return Container(
      color: const Color(0xFFFEF3C7), // Amber 50
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A), // Amber 200
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Comandos de Voz',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E), // Amber 800
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Controla todo con tu voz',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'SoftBee entiende tus comandos de voz para que puedas trabajar con las manos libres mientras inspeccionas tus colmenas.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildCommandCard(
                            title: 'Registro de Datos',
                            commands: [
                              '"Registrar producción colmena 5: 2 kilos"',
                              '"Anotar tratamiento varroa en apiario norte"',
                              '"Marcar reina nueva en colmena 12"',
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCommandCard(
                            title: 'Consultas',
                            commands: [
                              '"¿Cuál fue la producción total del mes pasado?"',
                              '"Mostrar historial de la colmena número 8"',
                              '"¿Cuándo fue la última revisión del apiario sur?"',
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildCommandCard(
                            title: 'Control de la Aplicación',
                            commands: [
                              '"Abrir sección de estadísticas"',
                              '"Crear nueva colmena en apiario este"',
                              '"Programar revisión para el próximo martes"',
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCommandCard(
                            title: 'Alertas y Recordatorios',
                            commands: [
                              '"Recordarme revisar las colmenas nuevas en 2 semanas"',
                              '"Programar alerta para cosecha en 30 días"',
                              '"Configurar recordatorio de tratamiento mensual"',
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildCommandCard(
                      title: 'Registro de Datos',
                      commands: [
                        '"Registrar producción colmena 5: 2 kilos"',
                        '"Anotar tratamiento varroa en apiario norte"',
                        '"Marcar reina nueva en colmena 12"',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCommandCard(
                      title: 'Consultas',
                      commands: [
                        '"¿Cuál fue la producción total del mes pasado?"',
                        '"Mostrar historial de la colmena número 8"',
                        '"¿Cuándo fue la última revisión del apiario sur?"',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCommandCard(
                      title: 'Control de la Aplicación',
                      commands: [
                        '"Abrir sección de estadísticas"',
                        '"Crear nueva colmena en apiario este"',
                        '"Programar revisión para el próximo martes"',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCommandCard(
                      title: 'Alertas y Recordatorios',
                      commands: [
                        '"Recordarme revisar las colmenas nuevas en 2 semanas"',
                        '"Programar alerta para cosecha en 30 días"',
                        '"Configurar recordatorio de tratamiento mensual"',
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommandCard({
    required String title,
    required List<String> commands,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...commands.map((command) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7), // Amber 100
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Comando',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E), // Amber 800
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          command,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // Amber 100
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Beneficios',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E), // Amber 800
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Por qué elegir SoftBee?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Descubre cómo SoftBee puede transformar la gestión de tu apiario y mejorar tu productividad.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildBenefitCard(
                title: 'Ahorra Tiempo',
                description:
                    'Reduce hasta un 40% el tiempo dedicado a la documentación y registro de datos.',
              ),
              _buildBenefitCard(
                title: 'Manos Libres',
                description:
                    'Trabaja con tus colmenas sin interrupciones mientras registras toda la información importante.',
              ),
              _buildBenefitCard(
                title: 'Decisiones Informadas',
                description:
                    'Analiza tendencias y patrones para optimizar la producción y salud de tus colmenas.',
              ),
              _buildBenefitCard(
                title: 'Fácil de Usar',
                description:
                    'Interfaz intuitiva diseñada para apicultores de todos los niveles de experiencia tecnológica.',
              ),
              _buildBenefitCard(
                title: 'Trabajo en Equipo',
                description:
                    'Comparte información con colaboradores y mantén a todo el equipo sincronizado.',
              ),
              _buildBenefitCard(
                title: 'Soporte Técnico',
                description:
                    'Asistencia personalizada y actualizaciones regulares para mejorar tu experiencia.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context) {
    return Container(
      color: const Color(0xFFF59E0B), // Amber 500
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const Text(
            'Únete a la revolución apícola',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Más de 500 apicultores ya están utilizando SoftBee para transformar la gestión de sus apiarios.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('Descargar Ahora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFF59E0B), // Amber 500
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Solicitar Demostración'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (MediaQuery.of(context).size.width > 800)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7), // Amber 100
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Contacto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E), // Amber 800
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '¿Tienes preguntas?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Estamos aquí para ayudarte. Contáctanos y te responderemos a la brevedad.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildContactInfo(
                        icon: Icons.phone,
                        text: '+123 456 7890',
                      ),
                      const SizedBox(height: 16),
                      _buildContactInfo(
                        icon: Icons.email,
                        text: 'info@softbee.com',
                      ),
                      const SizedBox(height: 16),
                      _buildContactInfo(
                        icon: Icons.location_on,
                        text: 'Calle Apicultura 123, Ciudad Miel',
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (MediaQuery.of(context).size.width <= 800) ...[
                          const Text(
                            'Contáctanos',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nombre',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Juan',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Apellido',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Pérez',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'juan@ejemplo.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Mensaje',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Escribe tu mensaje aquí...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B), // Amber 500
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Enviar Mensaje'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7), // Amber 100
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFD97706), // Amber 600
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '© 2025 SoftBee. Todos los derechos reservados.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Términos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Privacidad',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Soporte',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}