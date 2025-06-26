import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sotfbee/main.dart'; // Asegúrate de que esta ruta sea correcta

void main() {
  testWidgets('SoftBeeApp smoke test', (WidgetTester tester) async {
    // Construye el widget sin const (ya que SoftBeeApp no es const)
    await tester.pumpWidget(SoftBeeApp());

    // Verifica si se muestra el texto 'Bienvenido' en la pantalla de inicio
    expect(find.text('Bienvenido'), findsOneWidget);

    // Este test de contador es solo un ejemplo, puedes eliminarlo si no tienes un contador
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Simula un tap en el botón con el ícono de suma (Icons.add)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verifica si el contador cambió después del tap
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
