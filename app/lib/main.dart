import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'vistas/auth/login_view.dart';
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
      theme: AppTheme.tema,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginView(),
        '/registro': (context) => const RegistroView(),
        '/perfil': (context) => const PerfilView(),
      },
    );
  }
}

class AppTheme {
  static const Color colorPrimario = Color(0xFFF37021);

  static ThemeData get tema {
    return ThemeData(
      primaryColor: colorPrimario,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorPrimario,
        primary: colorPrimario,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimario,
          foregroundColor: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
    );
  }
}
