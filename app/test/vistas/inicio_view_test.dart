import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:saman_deportivo/core/rutas.dart';
import 'package:saman_deportivo/modelos/modelos.dart';
import 'package:saman_deportivo/viewmodels/auth_viewmodel.dart';
import 'package:saman_deportivo/viewmodels/perfil_viewmodel.dart';
import 'package:saman_deportivo/vistas/inicio/en_construccion_view.dart';
import 'package:saman_deportivo/vistas/inicio/inicio_view.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_usuario_repository.dart';

const _estudiante = Estudiante(
  id: 'e1',
  nombre: 'Ana',
  apellido: 'Pérez',
  cedula: 'V-1',
  correo: 'ana@correo.unimet.edu.ve',
  carnet: '20231110001',
  carrera: 'Ingeniería de Sistemas',
  solvente: true,
);

const _entrenadora = Entrenador(
  id: 't1',
  nombre: 'María',
  apellido: 'Gómez',
  cedula: 'V-2',
  correo: 'maria@correo.unimet.edu.ve',
  especialidad: 'Voleibol',
  aniosExperiencia: 4,
);

const _administrador = Administrador(
  id: 'a1',
  nombre: 'Pedro',
  apellido: 'Ruiz',
  cedula: 'V-3',
  correo: 'pedro@correo.unimet.edu.ve',
  cargo: 'Coordinador de deportes',
);

late FakeAuthRepository _auth;
late FakeUsuarioRepository _usuarios;
late AuthViewModel _authViewModel;
late PerfilViewModel _perfilViewModel;

/// Monta el inicio con el perfil de [persona] (o sin sesión si es null).
/// El perfil y el inicio de sesión son pantallas de prueba; cualquier otra
/// sección muestra «En construcción», igual que en main.dart.
Future<void> _abrirInicio(WidgetTester tester, Persona? persona) async {
  _auth = FakeAuthRepository();
  _usuarios = FakeUsuarioRepository();
  _authViewModel = AuthViewModel(
    authRepository: _auth,
    usuarioRepository: _usuarios,
  );
  _perfilViewModel = PerfilViewModel(usuarioRepository: _usuarios);
  if (persona != null) {
    _usuarios.agregar(persona);
    _perfilViewModel.actualizarSesion(persona.id);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: _authViewModel),
        ChangeNotifierProvider<PerfilViewModel>.value(value: _perfilViewModel),
      ],
      child: MaterialApp(
        initialRoute: Rutas.inicio,
        routes: {
          Rutas.inicio: (context) => const InicioView(),
          Rutas.perfil: (context) => const Text('Pantalla de perfil'),
          Rutas.login: (context) => const Text('Pantalla de inicio de sesión'),
        },
        onUnknownRoute: EnConstruccionView.ruta,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el estudiante ve el catálogo, sus disciplinas y su perfil', (
    tester,
  ) async {
    await _abrirInicio(tester, _estudiante);

    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Estudiante'), findsOneWidget);
    expect(find.text('Catálogo de disciplinas'), findsOneWidget);
    expect(find.text('Mis disciplinas'), findsOneWidget);
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Usuarios'), findsNothing);
  });

  testWidgets('avisa al estudiante que no está solvente', (tester) async {
    const sinSolvencia = Estudiante(
      id: 'e2',
      nombre: 'Luis',
      apellido: 'Mora',
      cedula: 'V-4',
      correo: 'luis@correo.unimet.edu.ve',
      carnet: '20231110002',
      carrera: 'Ingeniería Civil',
    );
    await _abrirInicio(tester, sinSolvencia);

    expect(find.textContaining('Aún no estás solvente'), findsOneWidget);
  });

  testWidgets('no muestra el aviso al estudiante solvente', (tester) async {
    await _abrirInicio(tester, _estudiante);

    expect(find.textContaining('Aún no estás solvente'), findsNothing);
  });

  testWidgets('el entrenador ve sus disciplinas y no el catálogo', (
    tester,
  ) async {
    await _abrirInicio(tester, _entrenadora);

    expect(find.text('Entrenador'), findsOneWidget);
    expect(find.text('Mis disciplinas'), findsOneWidget);
    expect(find.text('Catálogo de disciplinas'), findsNothing);
    expect(find.textContaining('solvente'), findsNothing);
  });

  testWidgets('el administrador ve deportes y usuarios', (tester) async {
    await _abrirInicio(tester, _administrador);

    expect(find.text('Administrador'), findsOneWidget);
    expect(find.text('Deportes'), findsOneWidget);
    expect(find.text('Usuarios'), findsOneWidget);
    expect(find.text('Mis disciplinas'), findsNothing);
  });

  testWidgets('cada actor recibe las rutas de su módulo', (tester) async {
    List<String> rutas(Persona persona) =>
        InicioView.seccionesPara(persona).map((s) => s.ruta).toList();

    expect(rutas(_estudiante), [
      Rutas.catalogo,
      Rutas.misDisciplinas,
      Rutas.solvencia,
      Rutas.perfil,
    ]);
    expect(rutas(_entrenadora), [Rutas.disciplinasEntrenador, Rutas.perfil]);
    expect(rutas(_administrador), [
      Rutas.adminDeportes,
      Rutas.adminUsuarios,
      Rutas.adminPagos,
      Rutas.perfil,
    ]);
  });

  testWidgets('una sección con pantalla abre esa pantalla', (tester) async {
    await _abrirInicio(tester, _estudiante);

    await tester.tap(find.text('Mi perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de perfil'), findsOneWidget);
  });

  testWidgets('una sección sin pantalla muestra «En construcción» y vuelve', (
    tester,
  ) async {
    await _abrirInicio(tester, _estudiante);

    await tester.tap(find.text('Catálogo de disciplinas'));
    await tester.pumpAndSettle();
    expect(find.text('Esta sección está en construcción'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsOneWidget);
  });

  testWidgets('cerrar sesión lleva al inicio de sesión', (tester) async {
    await _abrirInicio(tester, _administrador);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de inicio de sesión'), findsOneWidget);
  });

  testWidgets('sin sesión ofrece volver a iniciar sesión', (tester) async {
    await _abrirInicio(tester, null);

    expect(find.text('Volver a iniciar sesión'), findsOneWidget);
  });

  testWidgets('se adapta a un teléfono sin desbordarse', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _abrirInicio(tester, _administrador);

    expect(find.text('Usuarios'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
