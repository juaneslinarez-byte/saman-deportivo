import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/rutas.dart';
import 'core/tema.dart';
import 'firebase_options.dart';
import 'repositorios/asistencia_repository_firebase.dart';
import 'repositorios/auth_repository_firebase.dart';
import 'repositorios/repositorios.dart';
import 'repositorios/usuario_repository_firebase.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/perfil_viewmodel.dart';
import 'vistas/auth/login_view.dart';
import 'vistas/auth/recuperar_password_vista.dart';
import 'vistas/auth/registro_view.dart';
import 'vistas/bienvenida/bienvenida_view.dart';
import 'vistas/entrenador/disciplinas_entrenador_view.dart';
import 'vistas/entrenador/nomina_view.dart';
import 'vistas/entrenador/tomar_asistencia_view.dart';
import 'vistas/estudiante/catalogo_view.dart';
import 'vistas/estudiante/confirmar_inscripcion_view.dart';
import 'vistas/estudiante/detalle_disciplina_view.dart';
import 'vistas/estudiante/inscripcion_confirmada_view.dart';
import 'vistas/estudiante/mi_asistencia_view.dart';
import 'vistas/estudiante/mis_disciplinas_view.dart';
import 'vistas/inicio/en_construccion_view.dart';
import 'vistas/inicio/inicio_view.dart';
import 'vistas/perfil/editar_perfil_view.dart';
import 'vistas/perfil/perfil_view.dart';

Future<void> main() async {
  // Firebase debe estar listo antes de que la app use los repositorios.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Aquí se eligen las implementaciones reales (Firebase). Las vistas y los
    // ViewModels solo conocen las interfaces, así que en las pruebas se
    // reemplazan por los repositorios falsos sin tocar nada más.
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepositoryFirebase()),
        Provider<UsuarioRepository>(create: (_) => UsuarioRepositoryFirebase()),
        Provider<AsistenciaRepository>(
          create: (_) => AsistenciaRepositoryFirebase(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authRepository: context.read<AuthRepository>(),
            usuarioRepository: context.read<UsuarioRepository>(),
          ),
        ),
        // El perfil se vuelve a cargar cada vez que cambia la sesión.
        ChangeNotifierProxyProvider<AuthViewModel, PerfilViewModel>(
          create: (context) => PerfilViewModel(
            usuarioRepository: context.read<UsuarioRepository>(),
          ),
          update: (context, authViewModel, perfilViewModel) {
            final idUsuario = authViewModel.idUsuarioActual;
            // Se hace después de construir la pantalla, porque
            // actualizarSesion avisa a las vistas que el perfil cambió.
            Future.microtask(
              () => perfilViewModel!.actualizarSesion(idUsuario),
            );
            return perfilViewModel!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Samán Deportivo',
        debugShowCheckedModeBanner: false,
        theme: TemaSaman.claro,
        initialRoute: Rutas.inicial,
        routes: {
          Rutas.bienvenida: (context) => const BienvenidaView(),
          Rutas.login: (context) => const LoginView(),
          Rutas.registro: (context) => const RegistroView(),
          Rutas.recuperar: (context) => const RecuperarPasswordView(),
          Rutas.perfil: (context) => const PerfilView(),
          Rutas.editarPerfil: (context) => const EditarPerfilView(),
          Rutas.inicio: (context) => const InicioView(),
          Rutas.catalogo: (context) => const CatalogoView(),
          Rutas.detalleDisciplina: (context) => const DetalleDisciplinaView(),
          Rutas.confirmarInscripcion: (context) =>
              const ConfirmarInscripcionView(),
          Rutas.inscripcionConfirmada: (context) =>
              const InscripcionConfirmadaView(),
          Rutas.misDisciplinas: (context) => const MisDisciplinasView(),
          Rutas.miAsistencia: (context) => const MiAsistenciaView(),
          Rutas.disciplinasEntrenador: (context) =>
              const DisciplinasEntrenadorView(),
          Rutas.nominaEntrenador: (context) => const NominaView(),
          Rutas.asistenciaEntrenador: (context) => const TomarAsistenciaView(),
        },
        // Las secciones cuyo módulo todavía no registró su pantalla.
        onUnknownRoute: EnConstruccionView.ruta,
      ),
    );
  }
}
