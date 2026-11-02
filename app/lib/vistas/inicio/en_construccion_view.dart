import 'package:flutter/material.dart';

import '../../core/colores.dart';

/// Pantalla para las secciones del inicio cuyo módulo todavía no está listo.
///
/// main.dart la usa para cualquier ruta sin pantalla registrada, así cada
/// módulo se conecta al inicio con solo registrar su ruta.
class EnConstruccionView extends StatelessWidget {
  const EnConstruccionView({super.key});

  /// Ruta para los nombres que no tienen pantalla (`onUnknownRoute`).
  static Route<void> ruta(RouteSettings settings) => MaterialPageRoute<void>(
    settings: settings,
    builder: (context) => const EnConstruccionView(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresSaman.fondo,
      appBar: AppBar(
        backgroundColor: ColoresSaman.blanco,
        foregroundColor: ColoresSaman.azulOscuro,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: ColoresSaman.naranjaSuave,
                child: Icon(
                  Icons.construction_outlined,
                  size: 40,
                  color: ColoresSaman.naranja,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Esta sección está en construcción',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColoresSaman.azulOscuro,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estará disponible en una próxima versión.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ColoresSaman.textoSecundario),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColoresSaman.naranja,
                  side: const BorderSide(color: ColoresSaman.naranja),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => Navigator.maybePop(context),
                child: const Text(
                  'Volver',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
