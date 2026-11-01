import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/core/rutas.dart';
import 'package:saman_deportivo/vistas/bienvenida/bienvenida_view.dart';

/// Monta la página de bienvenida con rutas de prueba para el inicio de
/// sesión y el registro.
Widget _app() => MaterialApp(
  initialRoute: Rutas.bienvenida,
  routes: {
    Rutas.bienvenida: (context) => const BienvenidaView(),
    Rutas.login: (context) => const Text('Pantalla de inicio de sesión'),
    Rutas.registro: (context) => const Text('Pantalla de registro'),
  },
);

Future<void> _conTamano(WidgetTester tester, Size tamano) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('muestra las secciones del prototipo en pantalla ancha', (
    tester,
  ) async {
    await _conTamano(tester, const Size(1440, 900));
    await tester.pumpWidget(_app());

    expect(find.text('Vive el deporte'), findsOneWidget);
    expect(find.text('en la UNIMET'), findsOneWidget);
    expect(find.text('Encuentra tu deporte'), findsOneWidget);
    expect(find.text('Cada quien ve lo que necesita'), findsOneWidget);
    expect(find.text('Inscríbete en tres pasos'), findsOneWidget);
    expect(find.text('¿Listo para entrenar?'), findsOneWidget);
  });

  testWidgets('se adapta a un teléfono sin desbordarse', (tester) async {
    await _conTamano(tester, const Size(390, 844));
    await tester.pumpWidget(_app());

    expect(find.text('Vive el deporte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('«Crear cuenta de estudiante» lleva al registro', (tester) async {
    await _conTamano(tester, const Size(1440, 900));
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Crear cuenta de estudiante'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de registro'), findsOneWidget);
  });

  testWidgets('«Iniciar sesión» lleva al inicio de sesión', (tester) async {
    await _conTamano(tester, const Size(1440, 900));
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Iniciar sesión').first);
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de inicio de sesión'), findsOneWidget);
  });
}
