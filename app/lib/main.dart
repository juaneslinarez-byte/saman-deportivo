import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/rutas.dart';
import 'core/tema.dart';
import 'firebase_options.dart';
import 'vistas/auth/login_view.dart';
import 'vistas/auth/recuperar_password_vista.dart';
import 'vistas/auth/registro_view.dart';
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
    return MaterialApp(
      title: 'Samán Deportivo',
      debugShowCheckedModeBanner: false,
      theme: TemaSaman.claro,
      initialRoute: Rutas.inicial,
      routes: {
        Rutas.login: (context) => const LoginView(),
        Rutas.registro: (context) => const RegistroView(),
        Rutas.recuperar: (context) => const RecuperarPasswordView(),
        Rutas.perfil: (context) => const PerfilView(),
      },
    );
  }
}
